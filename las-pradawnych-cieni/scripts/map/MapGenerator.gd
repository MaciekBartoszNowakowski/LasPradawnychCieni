class_name MapGenerator
extends RefCounted

const TYPE_AUTO: int = -1
const FINAL_OATH_CHECKPOINT_ID: String = "oath_stone"
const REGULAR_CHECKPOINT_ORDER: Array[String] = [
	"whispering_totem",
	"broken_bridge",
	"ancient_camp",
	"soltys_ledger",
]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var next_id: int = 0

const PRE_BOSS_SHOP_COUNT: int = 1
const PRE_BOSS_REST_COUNT: int = 1

var _pre_boss_zone_layer_set: Dictionary = {}
var _last_pre_boss_zone_layers: Array[int] = []


func generate_map(config: MapGenerationConfig, run_profile: RunProfile = null) -> Array[MapNode]:
	var retry_limit: int = 1

	if config.retry_generation_on_validation_fail:
		retry_limit = max(1, config.generation_retry_limit)

	var last_generated: Array[MapNode] = []

	for attempt in range(retry_limit):
		_setup_rng(run_profile, attempt)
		next_id = 0

		last_generated = _generate_map_once(config)

		if _validate_generated_map(last_generated, config):
			return last_generated

	push_warning("MapGenerator: nie udało się wygenerować mapy spełniającej walidację, zwracam ostatnią próbę.")
	return last_generated


func _setup_rng(run_profile: RunProfile, attempt: int = 0) -> void:
	if run_profile != null and run_profile.should_use_fixed_seed():
		rng.seed = run_profile.get_effective_seed() + attempt
	else:
		rng.randomize()
		
func _generate_map_once(config: MapGenerationConfig) -> Array[MapNode]:
	var act_decision_counts: PackedInt32Array = _build_act_decision_counts(config)
	var total_layers: int = max(2, config.get_safe_base_decision_length() + 1)
	var story_anchor_layers: PackedInt32Array = _pick_story_anchor_layers(total_layers, config)
	var layer_specs: Array = _build_layer_specs(
		config,
		act_decision_counts,
		story_anchor_layers,
		total_layers
	)
	var pre_boss_recovery_plan: Dictionary = _plan_pre_boss_recovery(
		total_layers,
		story_anchor_layers,
		layer_specs,
		config
	)

	_pre_boss_zone_layer_set.clear()
	_last_pre_boss_zone_layers = pre_boss_recovery_plan.get("zone_layers", []) as Array[int]
	for zone_layer_index in _last_pre_boss_zone_layers:
		_pre_boss_zone_layer_set[zone_layer_index] = true

	var layers: Array = _create_layers_from_specs(
		layer_specs,
		config,
		act_decision_counts,
		pre_boss_recovery_plan
	)

	_connect_layers(layers, config)
	_make_first_layer_available(layers)

	return _flatten_layers(layers)


func _validate_generated_map(map_nodes: Array[MapNode], config: MapGenerationConfig) -> bool:
	if map_nodes.is_empty():
		return false

	var node_by_id: Dictionary = _build_node_lookup(map_nodes)
	var reachable_ids: Dictionary = _get_reachable_node_ids(map_nodes, node_by_id)

	if config.require_boss_reachable and not _is_boss_reachable(map_nodes, reachable_ids):
		return false

	if config.require_all_main_story_events_reachable and not _are_all_story_anchors_reachable(map_nodes, reachable_ids):
		return false

	if config.require_no_dead_end_main_paths and _has_invalid_dead_ends(map_nodes, config):
		return false

	if _get_max_consecutive_battle_streak(map_nodes, reachable_ids) > config.max_consecutive_combats:
		return false

	if not _validate_pre_boss_recovery(map_nodes, config, reachable_ids):
		return false

	return true


func _validate_pre_boss_recovery(
	map_nodes: Array[MapNode],
	_config: MapGenerationConfig,
	reachable_ids: Dictionary
) -> bool:
	if _last_pre_boss_zone_layers.is_empty():
		return false

	var zone_layer_set: Dictionary = {}
	for layer_index in _last_pre_boss_zone_layers:
		zone_layer_set[layer_index] = true

	var zone_shop_count: int = 0
	var zone_rest_count: int = 0
	var reachable_shop_count: int = 0
	var reachable_rest_count: int = 0

	for node in map_nodes:
		if not zone_layer_set.has(node.layer_index):
			continue

		if node.type == MapEnums.NodeType.SHOP:
			zone_shop_count += 1
			if reachable_ids.has(node.id):
				reachable_shop_count += 1
		elif node.type == MapEnums.NodeType.REST:
			zone_rest_count += 1
			if reachable_ids.has(node.id):
				reachable_rest_count += 1

	if zone_shop_count != PRE_BOSS_SHOP_COUNT or zone_rest_count != PRE_BOSS_REST_COUNT:
		return false

	if reachable_shop_count < PRE_BOSS_SHOP_COUNT or reachable_rest_count < PRE_BOSS_REST_COUNT:
		return false

	return true


func _build_node_lookup(map_nodes: Array[MapNode]) -> Dictionary:
	var result: Dictionary = {}

	for node in map_nodes:
		result[node.id] = node

	return result


func _get_reachable_node_ids(map_nodes: Array[MapNode], node_by_id: Dictionary) -> Dictionary:
	var reachable: Dictionary = {}
	var stack: Array[int] = []

	for node in map_nodes:
		if node.layer_index == 0:
			stack.append(node.id)
			reachable[node.id] = true

	while not stack.is_empty():
		var current_id: int = stack.pop_back()

		if not node_by_id.has(current_id):
			continue

		var current_node: MapNode = node_by_id[current_id] as MapNode

		for connection_id in current_node.connections:
			if reachable.has(connection_id):
				continue

			reachable[connection_id] = true
			stack.append(connection_id)

	return reachable


func _is_boss_reachable(map_nodes: Array[MapNode], reachable_ids: Dictionary) -> bool:
	for node in map_nodes:
		if node.type == MapEnums.NodeType.BOSS:
			return reachable_ids.has(node.id)

	return false


func _are_all_story_anchors_reachable(map_nodes: Array[MapNode], reachable_ids: Dictionary) -> bool:
	for node in map_nodes:
		if node.type == MapEnums.NodeType.CHECKPOINT and not reachable_ids.has(node.id):
			return false

	return true
	
func _has_invalid_dead_ends(map_nodes: Array[MapNode], config: MapGenerationConfig) -> bool:
	var last_layer_index: int = _get_last_layer_index(map_nodes)

	for node in map_nodes:
		if node.layer_index >= last_layer_index:
			continue

		if not node.connections.is_empty():
			continue

		if config.allow_dead_end_side_branches:
			var remaining_layers: int = last_layer_index - node.layer_index
			if remaining_layers <= config.max_dead_end_branch_length:
				continue

		return true

	return false

func _get_max_consecutive_battle_streak(
	map_nodes: Array[MapNode],
	reachable_ids: Dictionary
) -> int:
	var incoming_lookup: Dictionary = _build_incoming_lookup(map_nodes)
	var sorted_nodes: Array[MapNode] = map_nodes.duplicate()
	sorted_nodes.sort_custom(func(a: MapNode, b: MapNode) -> bool: return a.layer_index < b.layer_index)

	var best_streak_by_id: Dictionary = {}
	var global_best: int = 0

	for node in sorted_nodes:
		if not reachable_ids.has(node.id):
			continue

		var best_before: int = 0
		var incoming_ids: Array = incoming_lookup.get(node.id, [])

		for incoming_id in incoming_ids:
			best_before = max(best_before, int(best_streak_by_id.get(incoming_id, 0)))

		var current_streak: int = 0
		if node.type == MapEnums.NodeType.BATTLE:
			current_streak = best_before + 1

		best_streak_by_id[node.id] = current_streak
		global_best = max(global_best, current_streak)

	return global_best


func _build_incoming_lookup(map_nodes: Array[MapNode]) -> Dictionary:
	var result: Dictionary = {}

	for node in map_nodes:
		if not result.has(node.id):
			result[node.id] = []

	for node in map_nodes:
		for target_id in node.connections:
			if not result.has(target_id):
				result[target_id] = []

			var incoming: Array = result[target_id]
			incoming.append(node.id)
			result[target_id] = incoming

	return result

func _get_last_layer_index(map_nodes: Array[MapNode]) -> int:
	var last_layer_index: int = 0

	for node in map_nodes:
		last_layer_index = max(last_layer_index, node.layer_index)

	return last_layer_index

func _build_act_decision_counts(config: MapGenerationConfig) -> PackedInt32Array:
	var act_count: int = config.get_safe_act_count()
	var total_decisions: int = config.get_safe_base_decision_length()

	if act_count <= 0:
		return PackedInt32Array([total_decisions])

	var result: PackedInt32Array = PackedInt32Array()
	for _i in range(act_count):
		result.append(0)

	if total_decisions <= 0:
		return result

	var weights: Array[float] = config.get_all_act_length_weights()
	var total_weight: float = config.get_total_act_length_weight()

	if total_decisions >= act_count:
		for i in range(act_count):
			result[i] = 1
		total_decisions -= act_count

	if total_decisions <= 0:
		return result

	var provisional: Array[float] = []
	var assigned: int = 0

	for i in range(act_count):
		var share: float = float(total_decisions) * float(weights[i]) / total_weight
		provisional.append(share)

		var whole: int = int(floor(share))
		result[i] += whole
		assigned += whole

	var remaining: int = total_decisions - assigned

	while remaining > 0:
		var best_index: int = 0
		var best_fraction: float = -1.0

		for i in range(act_count):
			var fraction: float = float(provisional[i]) - floor(float(provisional[i]))
			if fraction > best_fraction:
				best_fraction = fraction
				best_index = i

		result[best_index] += 1
		provisional[best_index] = floor(float(provisional[best_index]))
		remaining -= 1

	return result


func _build_layer_specs(
	config: MapGenerationConfig,
	act_decision_counts: PackedInt32Array,
	story_anchor_layers: PackedInt32Array,
	total_layers: int
) -> Array:
	var planned_node_counts: PackedInt32Array = _build_segmented_node_count_plan(
		total_layers,
		story_anchor_layers,
		config,
		act_decision_counts
	)

	var specs: Array = []

	for layer_index in range(total_layers):
		var spec: Dictionary = {
			"node_count": 1,
			"forced_type": TYPE_AUTO
		}

		if layer_index == 0:
			spec["node_count"] = 1
			spec["forced_type"] = config.start_node_type
		elif layer_index == total_layers - 1:
			spec["node_count"] = 1
			spec["forced_type"] = config.boss_node_type
		elif config.require_pre_boss_story_event and layer_index == total_layers - 2:
			spec["node_count"] = 1
			spec["forced_type"] = MapEnums.NodeType.CHECKPOINT
		elif story_anchor_layers.has(layer_index):
			spec["node_count"] = 1
			spec["forced_type"] = MapEnums.NodeType.CHECKPOINT
		else:
			spec["node_count"] = int(planned_node_counts[layer_index])

		specs.append(spec)

	return specs


func _build_segmented_node_count_plan(
	total_layers: int,
	story_anchor_layers: PackedInt32Array,
	config: MapGenerationConfig,
	act_decision_counts: PackedInt32Array
) -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()

	for _i in range(total_layers):
		result.append(1)

	var min_paths: int = config.get_preferred_active_paths_min()
	var max_paths: int = config.get_preferred_active_paths_max()

	var current_count: int = clamp(2, min_paths, max_paths)
	var layer_index: int = 1

	while layer_index < total_layers - 1:
		if _is_forced_single_layer(layer_index, total_layers, story_anchor_layers, config):
			result[layer_index] = 1
			layer_index += 1

			if layer_index < total_layers - 1:
				var act_index_after_anchor: int = _get_act_index_for_layer(layer_index, act_decision_counts)
				var act_rule_after_anchor: MapActRuleConfig = config.get_or_create_default_act_rule(act_index_after_anchor)
				current_count = clamp(act_rule_after_anchor.preferred_path_count, min_paths, max_paths)

			continue

		var next_forced_layer: int = _find_next_forced_single_layer(
			layer_index,
			total_layers,
			story_anchor_layers,
			config
		)

		var max_segment_end: int = next_forced_layer - 1
		var segment_length: int = rng.randi_range(
			config.get_path_commitment_length_min(),
			config.get_path_commitment_length_max()
		)

		var segment_end: int = min(max_segment_end, layer_index + segment_length - 1)
		var act_index: int = _get_act_index_for_layer(layer_index, act_decision_counts)
		var act_rule: MapActRuleConfig = config.get_or_create_default_act_rule(act_index)

		current_count = clamp(act_rule.preferred_path_count, min_paths, max_paths)

		for i in range(layer_index, segment_end + 1):
			result[i] = current_count

		_maybe_apply_short_branch(result, layer_index, segment_end, config)

		layer_index = segment_end + 1

	return result


func _maybe_apply_short_branch(
	result: PackedInt32Array,
	segment_start: int,
	segment_end: int,
	config: MapGenerationConfig
) -> void:
	if segment_end < segment_start:
		return

	if rng.randf() > config.branch_spawn_chance:
		return

	var max_extra_count: int = max(1, config.max_active_paths)
	var branch_length: int = rng.randi_range(
		config.get_short_branch_length_min(),
		config.get_short_branch_length_max()
	)

	if segment_end - segment_start + 1 < branch_length:
		return

	var max_start: int = segment_end - branch_length + 1
	var branch_start: int = rng.randi_range(segment_start, max_start)

	for i in range(branch_start, branch_start + branch_length):
		result[i] = min(max_extra_count, int(result[i]) + 1)


func _is_forced_single_layer(
	layer_index: int,
	total_layers: int,
	story_anchor_layers: PackedInt32Array,
	config: MapGenerationConfig
) -> bool:
	if layer_index == 0:
		return true

	if layer_index == total_layers - 1:
		return true

	if config.require_pre_boss_story_event and layer_index == total_layers - 2:
		return true

	return story_anchor_layers.has(layer_index)


func _find_next_forced_single_layer(
	from_layer: int,
	total_layers: int,
	story_anchor_layers: PackedInt32Array,
	config: MapGenerationConfig
) -> int:
	for layer_index in range(from_layer, total_layers):
		if _is_forced_single_layer(layer_index, total_layers, story_anchor_layers, config):
			return layer_index

	return total_layers - 1
	

func _pick_story_anchor_layers(total_layers: int, config: MapGenerationConfig) -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()
	var count: int = max(0, config.mandatory_story_event_count)

	if count <= 0:
		return result

	var last_usable_layer: int = total_layers - 2
	if config.require_pre_boss_story_event:
		last_usable_layer -= 1

	var first_usable_layer: int = 1

	if last_usable_layer < first_usable_layer:
		return result

	var spacing_min: int = config.get_story_spacing_min()
	var spacing_max: int = config.get_story_spacing_max()

	for i in range(count):
		var remaining_after: int = count - i - 1

		var raw_position: int
		if count == 1:
			raw_position = int(round((first_usable_layer + last_usable_layer) * 0.5))
		else:
			var t: float = float(i + 1) / float(count + 1)
			raw_position = int(round(lerp(float(first_usable_layer), float(last_usable_layer), t)))

		var min_allowed: int = first_usable_layer
		if not result.is_empty():
			min_allowed = int(result[result.size() - 1]) + spacing_min

		var max_allowed: int = last_usable_layer - remaining_after * spacing_min
		if max_allowed < min_allowed:
			max_allowed = min_allowed

		var candidate: int = clamp(raw_position, min_allowed, max_allowed)

		if not result.is_empty():
			var previous: int = int(result[result.size() - 1])
			var preferred_max: int = previous + spacing_max
			if preferred_max >= min_allowed:
				candidate = min(candidate, preferred_max)

		result.append(candidate)

	return result


func _get_pre_boss_zone_layer_indices(
	total_layers: int,
	story_anchor_layers: PackedInt32Array,
	config: MapGenerationConfig
) -> Array[int]:
	var result: Array[int] = []

	if total_layers <= 2:
		return result

	var start_layer: int = int(ceil((total_layers - 1) * config.get_pre_boss_zone_start_progress()))
	var end_exclusive: int = total_layers - 1

	if config.require_pre_boss_story_event:
		end_exclusive = min(end_exclusive, total_layers - 2)

	start_layer = clamp(start_layer, 1, max(1, end_exclusive - 1))

	for layer_index in range(start_layer, end_exclusive):
		if story_anchor_layers.has(layer_index):
			continue

		if config.require_pre_boss_story_event and layer_index == total_layers - 2:
			continue

		result.append(layer_index)

	return result


func _plan_pre_boss_recovery(
	total_layers: int,
	story_anchor_layers: PackedInt32Array,
	layer_specs: Array,
	config: MapGenerationConfig
) -> Dictionary:
	var zone_layers: Array[int] = _get_pre_boss_zone_layer_indices(
		total_layers,
		story_anchor_layers,
		config
	)
	var shop_layers: PackedInt32Array = PackedInt32Array()
	var rest_layers: PackedInt32Array = PackedInt32Array()
	var shop_node_index: int = 0
	var rest_node_index: int = 0

	if zone_layers.size() < 2:
		push_warning(
			"MapGenerator: za mało warstw w strefie pre-boss na sklep i odpoczynek."
		)
		return {
			"shop_layers": shop_layers,
			"rest_layers": rest_layers,
			"shop_node_index": shop_node_index,
			"rest_node_index": rest_node_index,
			"zone_layers": zone_layers,
		}

	var shuffled_layers: Array[int] = zone_layers.duplicate()
	_shuffle_int_array(shuffled_layers)

	var spacing: int = config.get_pre_boss_recovery_min_layer_spacing()
	var shop_layer: int = shuffled_layers[0]
	var rest_layer: int = -1

	for layer_index in shuffled_layers:
		if layer_index == shop_layer:
			continue
		if abs(layer_index - shop_layer) >= spacing:
			rest_layer = layer_index
			break

	if rest_layer == -1:
		for layer_index in shuffled_layers:
			if layer_index != shop_layer:
				rest_layer = layer_index
				break

	var layer_for_shop: int = shop_layer
	var layer_for_rest: int = rest_layer

	if rest_layer != -1 and rng.randi_range(0, 1) == 1:
		layer_for_shop = rest_layer
		layer_for_rest = shop_layer

	var shop_spec: Dictionary = (
		layer_specs[layer_for_shop] if layer_for_shop < layer_specs.size() else {}
	)
	var rest_spec: Dictionary = (
		layer_specs[layer_for_rest] if layer_for_rest >= 0 and layer_for_rest < layer_specs.size() else {}
	)
	var shop_node_count: int = max(1, int(shop_spec.get("node_count", 1)))
	var rest_node_count: int = max(1, int(rest_spec.get("node_count", 1)))

	shop_node_index = _pick_planned_recovery_node_index(shop_node_count)
	var shop_branch_lane: int = _branch_lane(shop_node_count, shop_node_index)
	rest_node_index = _pick_planned_recovery_node_index(rest_node_count, shop_branch_lane)

	if rest_layer == -1:
		shop_layers.append(shop_layer)
	else:
		shop_layers.append(layer_for_shop)
		rest_layers.append(layer_for_rest)

	return {
		"shop_layers": shop_layers,
		"rest_layers": rest_layers,
		"shop_node_index": shop_node_index,
		"rest_node_index": rest_node_index,
		"zone_layers": zone_layers,
	}


func _branch_lane(layer_size: int, node_index: int) -> int:
	if layer_size <= 1:
		return 0

	return int(round(float(node_index) / float(layer_size - 1) * 2.0))


func _pick_planned_recovery_node_index(node_count: int, avoid_branch_lane: int = -1) -> int:
	if node_count <= 1:
		return 0

	var candidates: Array[int] = []
	for index in range(node_count):
		candidates.append(index)

	_shuffle_int_array(candidates)

	if avoid_branch_lane < 0:
		return candidates[0]

	var alternate: Array[int] = []
	for index in candidates:
		if _branch_lane(node_count, index) != avoid_branch_lane:
			alternate.append(index)

	if alternate.is_empty():
		return candidates[rng.randi_range(0, candidates.size() - 1)]

	return alternate[rng.randi_range(0, alternate.size() - 1)]


func _shuffle_int_array(values: Array[int]) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: int = values[i]
		values[i] = values[j]
		values[j] = temp


func _packed_int32_has(values: PackedInt32Array, layer_index: int) -> bool:
	for value in values:
		if int(value) == layer_index:
			return true

	return false


func _create_layers_from_specs(
	layer_specs: Array,
	config: MapGenerationConfig,
	act_decision_counts: PackedInt32Array,
	pre_boss_recovery_plan: Dictionary = {}
) -> Array:
	var layers: Array = []
	var generated_counts: Dictionary = {}
	var pre_boss_generated_counts: Dictionary = {}
	var layer_type_history: Array = []
	var used_side_quests: Dictionary = {}
	var checkpoint_order_index: int = 0

	for layer_index in range(layer_specs.size()):
		var layer: Array[MapNode] = []
		var spec: Dictionary = layer_specs[layer_index]

		var node_count: int = max(1, int(spec.get("node_count", 1)))
		var layer_types: Array[int] = []

		for index_in_layer in range(node_count):
			var forced_type: int = int(spec.get("forced_type", TYPE_AUTO))
			var node_type: int = forced_type

			if node_type == TYPE_AUTO:
				node_type = _pick_regular_node_type(
					config,
					layer_index,
					layer_specs.size(),
					act_decision_counts,
					generated_counts,
					layer_type_history
				)

			var position: Vector2 = _get_node_position(layer_index, index_in_layer, node_count, config)
			var node: MapNode = MapNode.new(next_id, node_type, position, layer_index)
			node.act = _get_act_index_for_layer(layer_index, act_decision_counts)
			
			_assign_side_quest_if_needed(node, config, used_side_quests)
			checkpoint_order_index = _assign_checkpoint_if_needed(
				node,
				config,
				checkpoint_order_index,
				layer_specs.size()
			)
			
			layer.append(node)
			layer_types.append(node_type)
			_increment_node_count(generated_counts, node_type)
			next_id += 1

		_apply_pre_boss_recovery_for_layer(
			layer,
			layer_index,
			pre_boss_recovery_plan,
			config,
			generated_counts,
			pre_boss_generated_counts,
			layer_types
		)

		layers.append(layer)
		layer_type_history.append(layer_types)

	return layers


func _apply_pre_boss_recovery_for_layer(
	layer: Array,
	layer_index: int,
	plan: Dictionary,
	config: MapGenerationConfig,
	generated_counts: Dictionary,
	pre_boss_generated_counts: Dictionary,
	layer_types: Array[int]
) -> void:
	if layer.is_empty() or plan.is_empty():
		return

	var shop_layers: PackedInt32Array = plan.get("shop_layers", PackedInt32Array())
	var rest_layers: PackedInt32Array = plan.get("rest_layers", PackedInt32Array())
	var target_type: int = -1

	if _packed_int32_has(shop_layers, layer_index):
		target_type = MapEnums.NodeType.SHOP
	elif _packed_int32_has(rest_layers, layer_index):
		target_type = MapEnums.NodeType.REST
	else:
		return

	var preferred_node_index: int = -1
	if target_type == MapEnums.NodeType.SHOP:
		preferred_node_index = int(plan.get("shop_node_index", -1))
	elif target_type == MapEnums.NodeType.REST:
		preferred_node_index = int(plan.get("rest_node_index", -1))

	var node: MapNode = _pick_recovery_node_in_layer(layer, preferred_node_index)
	if node == null:
		push_warning(
			"MapGenerator: nie udało się wstrzyknąć recovery na warstwie %d." % layer_index
		)
		return

	var old_type: int = node.type
	if old_type == target_type:
		return

	_decrement_node_count(generated_counts, old_type)

	if old_type == MapEnums.NodeType.EVENT:
		node.side_quest_config = null

	node.type = target_type

	if config.pre_boss_recovery_use_separate_quota:
		_increment_node_count(pre_boss_generated_counts, target_type)
	else:
		_increment_node_count(generated_counts, target_type)

	var node_index: int = layer.find(node)
	if node_index >= 0 and node_index < layer_types.size():
		layer_types[node_index] = target_type


func _is_recovery_eligible_node(node: MapNode) -> bool:
	if node == null:
		return false

	if node.type == MapEnums.NodeType.CHECKPOINT:
		return false
	if node.type == MapEnums.NodeType.BOSS:
		return false

	return true


func _pick_recovery_node_in_layer(layer: Array, preferred_index: int = -1) -> MapNode:
	if layer.is_empty():
		return null

	var eligible_indices: Array[int] = []
	for index in range(layer.size()):
		var node: MapNode = layer[index] as MapNode
		if _is_recovery_eligible_node(node):
			eligible_indices.append(index)

	if eligible_indices.is_empty():
		return null

	if preferred_index >= 0 and eligible_indices.has(preferred_index):
		return layer[preferred_index] as MapNode

	var fallback_indices: Array[int] = eligible_indices.duplicate()
	_shuffle_int_array(fallback_indices)
	return layer[fallback_indices[0]] as MapNode


func _decrement_node_count(counts: Dictionary, node_type: int) -> void:
	var current_count: int = _get_node_count(counts, node_type)
	if current_count <= 0:
		return

	counts[node_type] = current_count - 1

func _assign_side_quest_if_needed(
	node: MapNode,
	config: MapGenerationConfig,
	used_side_quests: Dictionary
) -> void:
	if node == null:
		return

	if node.type != MapEnums.NodeType.EVENT:
		return

	# Nie przypinamy sidequesta do startowego eventu.
	if node.layer_index == 0:
		return

	if config.side_quest_pool.is_empty():
		return

	var quest: SideQuestConfig = _pick_side_quest_config(config, used_side_quests)

	if quest == null:
		return

	node.side_quest_config = quest

	var quest_key: String = quest.resource_path
	if quest_key.is_empty():
		quest_key = str(quest.get_instance_id())

	used_side_quests[quest_key] = true


func _assign_checkpoint_if_needed(
	node: MapNode,
	config: MapGenerationConfig,
	checkpoint_order_index: int,
	total_layers: int
) -> int:
	if node == null:
		return checkpoint_order_index

	if node.type != MapEnums.NodeType.CHECKPOINT:
		return checkpoint_order_index

	if config.checkpoint_pool.is_empty():
		return checkpoint_order_index

	var pre_boss_layer_index: int = total_layers - 2
	var is_pre_boss_checkpoint: bool = (
		config.require_pre_boss_story_event
		and node.layer_index == pre_boss_layer_index
	)

	if is_pre_boss_checkpoint:
		var final_checkpoint: CheckpointConfig = _get_checkpoint_by_id(config, FINAL_OATH_CHECKPOINT_ID)
		if final_checkpoint != null:
			node.checkpoint_config = final_checkpoint
			return checkpoint_order_index

	# Regularne checkpointy zawsze idą w stałej, fabularnej kolejności.
	# Jeśli generator stworzy więcej checkpointów niż długość listy,
	# kolejność będzie się powtarzać.
	var ordered_id: String = ""
	if not REGULAR_CHECKPOINT_ORDER.is_empty():
		ordered_id = REGULAR_CHECKPOINT_ORDER[checkpoint_order_index % REGULAR_CHECKPOINT_ORDER.size()]

	if not ordered_id.is_empty():
		var ordered_checkpoint: CheckpointConfig = _get_checkpoint_by_id(config, ordered_id)
		if ordered_checkpoint != null:
			node.checkpoint_config = ordered_checkpoint
			return checkpoint_order_index + 1

	# Fallback: jeżeli brakuje konkretnego zasobu w puli (np. usunięty .tres),
	# dobierz cokolwiek sensownego z puli (bez oath_stone).
	var regular_checkpoint_pool: Array[CheckpointConfig] = _get_checkpoint_pool_without_id(config, FINAL_OATH_CHECKPOINT_ID)
	if regular_checkpoint_pool.is_empty():
		regular_checkpoint_pool = _get_checkpoint_pool_without_id(config, "")
	if regular_checkpoint_pool.is_empty():
		return checkpoint_order_index

	var checkpoint_index: int = checkpoint_order_index % regular_checkpoint_pool.size()
	node.checkpoint_config = regular_checkpoint_pool[checkpoint_index]
	return checkpoint_order_index + 1


func _get_checkpoint_by_id(config: MapGenerationConfig, checkpoint_id: String) -> CheckpointConfig:
	for raw_checkpoint in config.checkpoint_pool:
		var checkpoint := raw_checkpoint as CheckpointConfig
		if checkpoint == null:
			continue

		if str(checkpoint.checkpoint_id) == checkpoint_id:
			return checkpoint

	return null


func _get_checkpoint_pool_without_id(config: MapGenerationConfig, excluded_id: String) -> Array[CheckpointConfig]:
	var result: Array[CheckpointConfig] = []

	for raw_checkpoint in config.checkpoint_pool:
		var checkpoint := raw_checkpoint as CheckpointConfig
		if checkpoint == null:
			continue

		if not excluded_id.is_empty() and str(checkpoint.checkpoint_id) == excluded_id:
			continue

		result.append(checkpoint)

	return result


func _pick_side_quest_config(
	config: MapGenerationConfig,
	used_side_quests: Dictionary
) -> SideQuestConfig:
	var available_quests: Array[SideQuestConfig] = []

	for quest in config.side_quest_pool:
		if quest == null:
			continue

		if not config.allow_repeating_side_quests:
			var quest_key: String = quest.resource_path
			if quest_key.is_empty():
				quest_key = str(quest.get_instance_id())

			if used_side_quests.has(quest_key):
				continue

		available_quests.append(quest)

	if available_quests.is_empty():
		return null

	var index: int = rng.randi_range(0, available_quests.size() - 1)
	return available_quests[index]


func _pick_regular_node_type(
	config: MapGenerationConfig,
	layer_index: int,
	total_layers: int,
	act_decision_counts: PackedInt32Array,
	generated_counts: Dictionary,
	layer_type_history: Array
) -> int:
	var act_index: int = _get_act_index_for_layer(layer_index, act_decision_counts)
	var act_rule: MapActRuleConfig = config.get_or_create_default_act_rule(act_index)

	var candidates: Array[int] = []
	var weights: Array[int] = []

	_add_weighted_node_candidate(
		candidates,
		weights,
		MapEnums.NodeType.BATTLE,
		_calculate_node_type_weight(
			MapEnums.NodeType.BATTLE,
			config,
			act_rule,
			layer_index,
			total_layers,
			generated_counts,
			layer_type_history
		)
	)

	_add_weighted_node_candidate(
		candidates,
		weights,
		MapEnums.NodeType.EVENT,
		_calculate_node_type_weight(
			MapEnums.NodeType.EVENT,
			config,
			act_rule,
			layer_index,
			total_layers,
			generated_counts,
			layer_type_history
		)
	)

	_add_weighted_node_candidate(
		candidates,
		weights,
		MapEnums.NodeType.SHOP,
		_calculate_node_type_weight(
			MapEnums.NodeType.SHOP,
			config,
			act_rule,
			layer_index,
			total_layers,
			generated_counts,
			layer_type_history
		)
	)

	_add_weighted_node_candidate(
		candidates,
		weights,
		MapEnums.NodeType.REST,
		_calculate_node_type_weight(
			MapEnums.NodeType.REST,
			config,
			act_rule,
			layer_index,
			total_layers,
			generated_counts,
			layer_type_history
		)
	)

	if candidates.is_empty():
		return config.dominant_node_type

	var total_weight: int = 0
	for weight_value in weights:
		total_weight += int(weight_value)

	if total_weight <= 0:
		return config.dominant_node_type

	var roll: int = rng.randi_range(1, total_weight)

	for i in range(candidates.size()):
		roll -= int(weights[i])
		if roll <= 0:
			return int(candidates[i])

	return int(candidates[0])


func _calculate_node_type_weight(
	node_type: int,
	config: MapGenerationConfig,
	act_rule: MapActRuleConfig,
	layer_index: int,
	total_layers: int,
	generated_counts: Dictionary,
	layer_type_history: Array
) -> int:
	var base_target: int = _get_base_target_for_node_type(config, node_type)
	var current_count: int = _get_node_count(generated_counts, node_type)
	var density_multiplier: float = _get_density_multiplier_for_node_type(node_type, act_rule)

	var weight: float = float(max(0, base_target - current_count))

	if node_type == config.dominant_node_type:
		weight += 2.0

	weight *= density_multiplier
	weight *= _get_position_multiplier_for_node_type(node_type, layer_index, total_layers, config)
	weight *= _get_history_multiplier_for_node_type(node_type, layer_type_history)
	weight *= _get_pacing_multiplier_for_node_type(node_type, layer_type_history)

	if _pre_boss_zone_layer_set.has(layer_index):
		if node_type == MapEnums.NodeType.SHOP or node_type == MapEnums.NodeType.REST:
			return 0

	return max(0, int(round(weight)))


func _get_base_target_for_node_type(config: MapGenerationConfig, node_type: int) -> int:
	match node_type:
		MapEnums.NodeType.BATTLE:
			return config.combat_target_count
		MapEnums.NodeType.EVENT:
			return config.optional_event_target_count
		MapEnums.NodeType.SHOP:
			return config.shop_target_count
		MapEnums.NodeType.REST:
			return config.rest_target_count
		_:
			return 0


func _get_density_multiplier_for_node_type(node_type: int, act_rule: MapActRuleConfig) -> float:
	match node_type:
		MapEnums.NodeType.BATTLE:
			return max(0.0, act_rule.combat_density)
		MapEnums.NodeType.EVENT:
			return max(0.0, act_rule.optional_event_density)
		MapEnums.NodeType.SHOP:
			return max(0.0, act_rule.shop_density)
		MapEnums.NodeType.REST:
			return max(0.0, act_rule.rest_density)
		_:
			return 1.0


func _get_position_multiplier_for_node_type(
	node_type: int,
	layer_index: int,
	total_layers: int,
	config: MapGenerationConfig
) -> float:
	if total_layers <= 1:
		return 1.0

	var progress: float = float(layer_index) / float(total_layers - 1)

	match node_type:
		MapEnums.NodeType.BATTLE:
			if progress < 0.20:
				return 1.30
			if progress > 0.80:
				return 0.90
			return 1.0

		MapEnums.NodeType.REST:
			if progress < 0.15:
				return 0.35
			if progress > 0.80 and not config.allow_rest_before_boss:
				return 0.15
			return 1.0

		MapEnums.NodeType.SHOP:
			if progress < 0.15:
				return 0.45
			if progress > 0.80 and not config.allow_shop_before_boss:
				return 0.20
			return 1.0

		MapEnums.NodeType.EVENT:
			if progress < 0.10:
				return 0.70
			return 1.0

		_:
			return 1.0


func _get_history_multiplier_for_node_type(node_type: int, layer_type_history: Array) -> float:
	if layer_type_history.is_empty():
		return 1.0

	var last_layer: Array = layer_type_history[layer_type_history.size() - 1]
	var second_last_layer: Array = []

	if layer_type_history.size() >= 2:
		second_last_layer = layer_type_history[layer_type_history.size() - 2]

	var in_last: bool = last_layer.has(node_type)
	var in_second_last: bool = second_last_layer.has(node_type)

	if node_type == MapEnums.NodeType.BATTLE:
		if in_last and in_second_last:
			return 0.85
		return 1.0

	if in_last and in_second_last:
		return 0.10

	if in_last:
		return 0.35

	return 1.0


func _get_pacing_multiplier_for_node_type(
	node_type: int,
	layer_type_history: Array,
) -> float:
	if layer_type_history.is_empty():
		return 1.0

	var recent_special_count: int = _count_recent_special_layers(layer_type_history, 2)

	match node_type:
		MapEnums.NodeType.BATTLE:
			if recent_special_count >= 2:
				return 1.20
			return 1.0

		MapEnums.NodeType.REST, MapEnums.NodeType.SHOP, MapEnums.NodeType.EVENT:
			if recent_special_count >= 2:
				return 0.40
			return 1.0

		_:
			return 1.0

func _count_recent_special_layers(layer_type_history: Array, depth: int) -> int:
	var count: int = 0
	var start_index: int = max(0, layer_type_history.size() - depth)

	for i in range(start_index, layer_type_history.size()):
		var layer_types: Array = layer_type_history[i]
		if _layer_contains_special_type(layer_types):
			count += 1

	return count


func _layer_contains_special_type(layer_types: Array) -> bool:
	return (
		layer_types.has(MapEnums.NodeType.REST)
		or layer_types.has(MapEnums.NodeType.SHOP)
		or layer_types.has(MapEnums.NodeType.EVENT)
	)


func _add_weighted_node_candidate(candidates: Array[int], weights: Array[int], node_type: int, weight: int) -> void:
	if weight <= 0:
		return

	candidates.append(node_type)
	weights.append(weight)


func _get_node_count(counts: Dictionary, node_type: int) -> int:
	return int(counts.get(node_type, 0))


func _increment_node_count(counts: Dictionary, node_type: int) -> void:
	counts[node_type] = _get_node_count(counts, node_type) + 1


func _get_act_index_for_layer(layer_index: int, act_decision_counts: PackedInt32Array) -> int:
	if act_decision_counts.is_empty():
		return 0

	if layer_index <= 0:
		return 0

	var slot_index: int = layer_index
	var cumulative: int = 0

	for act_index in range(act_decision_counts.size()):
		cumulative += int(act_decision_counts[act_index])
		if slot_index <= cumulative:
			return act_index

	return act_decision_counts.size() - 1


func _get_node_position(layer_index: int, index_in_layer: int, node_count: int, config: MapGenerationConfig) -> Vector2:
	var x: float = config.start_x + float(layer_index) * config.segment_spacing
	var y: float = config.top_margin + (index_in_layer + 1) * config.map_height / float(node_count + 1)

	x += rng.randf_range(-config.jitter_x, config.jitter_x)
	y += rng.randf_range(-config.jitter_y, config.jitter_y)

	return Vector2(round(x), round(y))


func _connect_layers(layers: Array, config: MapGenerationConfig) -> void:
	for layer_index in range(layers.size() - 1):
		var current_layer: Array = layers[layer_index]
		var next_layer: Array = layers[layer_index + 1]

		if current_layer.is_empty() or next_layer.is_empty():
			continue

		if next_layer.size() == 1:
			var target_node: MapNode = next_layer[0] as MapNode
			_connect_all_to_single(current_layer, target_node)
			continue

		if current_layer.size() == 1:
			var single_node: MapNode = current_layer[0] as MapNode
			_connect_single_to_all(single_node, next_layer)
			continue

		_connect_general_layers(current_layer, next_layer, config)


func _connect_all_to_single(current_layer: Array, target_node: MapNode) -> void:
	for raw_node in current_layer:
		var node: MapNode = raw_node as MapNode
		_add_connection_if_missing(node, target_node.id)


func _connect_single_to_all(single_node: MapNode, next_layer: Array) -> void:
	for raw_next_node in next_layer:
		var next_node: MapNode = raw_next_node as MapNode
		_add_connection_if_missing(single_node, next_node.id)


func _connect_general_layers(current_layer: Array, next_layer: Array, config: MapGenerationConfig) -> void:
	var current_count: int = current_layer.size()
	var next_count: int = next_layer.size()

	if current_count == 0 or next_count == 0:
		return

	for source_index in range(current_count):
		var node: MapNode = current_layer[source_index] as MapNode
		var primary_index: int = _get_primary_target_index(source_index, current_count, next_count)

		_add_connection_if_missing(node, (next_layer[primary_index] as MapNode).id)

		var secondary_index: int = _get_secondary_target_index(
			source_index,
			primary_index,
			current_count,
			next_count,
			config
		)

		if secondary_index != -1 and secondary_index != primary_index:
			_add_connection_if_missing(node, (next_layer[secondary_index] as MapNode).id)

	_ensure_every_next_node_has_incoming(current_layer, next_layer)


func _get_primary_target_index(source_index: int, current_count: int, next_count: int) -> int:
	if next_count <= 1:
		return 0

	if current_count <= 1:
		@warning_ignore("integer_division")
		return int(floor(next_count / 2))

	if current_count == next_count:
		return source_index

	var t: float = float(source_index) / float(max(1, current_count - 1))
	return clamp(int(round(t * float(next_count - 1))), 0, next_count - 1)


func _get_secondary_target_index(
	source_index: int,
	primary_index: int,
	current_count: int,
	next_count: int,
	config: MapGenerationConfig
) -> int:
	if next_count <= 1:
		return -1

	var wants_secondary: bool = false

	if next_count > current_count:
		wants_secondary = rng.randf() < config.path_split_chance
	elif next_count == current_count:
		wants_secondary = rng.randf() < (config.path_split_chance * 0.25)
	else:
		wants_secondary = rng.randf() < (config.path_merge_chance * 0.15)

	if not wants_secondary:
		return -1

	var candidate_indices: Array[int] = []

	if primary_index - 1 >= 0:
		candidate_indices.append(primary_index - 1)

	if primary_index + 1 < next_count:
		candidate_indices.append(primary_index + 1)

	if candidate_indices.is_empty():
		return -1

	if config.avoid_line_crossing_preference and current_count > 1 and next_count > 1:
		var normalized_source: float = float(source_index) / float(max(1, current_count - 1))
		var best_candidate: int = candidate_indices[0]
		var best_distance: float = INF

		for candidate_index in candidate_indices:
			var normalized_target: float = float(candidate_index) / float(max(1, next_count - 1))
			var distance: float = absf(normalized_source - normalized_target)

			if distance < best_distance:
				best_distance = distance
				best_candidate = candidate_index

		return best_candidate

	return int(candidate_indices[rng.randi_range(0, candidate_indices.size() - 1)])



func _ensure_every_next_node_has_incoming(current_layer: Array, next_layer: Array) -> void:
	for raw_next_node in next_layer:
		var next_node: MapNode = raw_next_node as MapNode
		var has_incoming: bool = false

		for raw_current_node in current_layer:
			var current_node: MapNode = raw_current_node as MapNode
			if current_node.connections.has(next_node.id):
				has_incoming = true
				break

		if has_incoming:
			continue

		var best_source: MapNode = _get_closest_node_by_y(next_node, current_layer)
		if best_source != null:
			_add_connection_if_missing(best_source, next_node.id)


func _get_closest_node_by_y(target_node: MapNode, nodes: Array) -> MapNode:
	var best_node: MapNode = null
	var best_distance: float = INF

	for raw_node in nodes:
		var node: MapNode = raw_node as MapNode
		var distance: float = absf(node.position.y - target_node.position.y)

		if distance < best_distance:
			best_distance = distance
			best_node = node

	return best_node



func _add_connection_if_missing(node: MapNode, target_id: int) -> void:
	if not node.connections.has(target_id):
		node.connections.append(target_id)


func _make_first_layer_available(layers: Array) -> void:
	if layers.is_empty():
		return

	var first_layer: Array = layers[0]

	for raw_node in first_layer:
		var node: MapNode = raw_node as MapNode
		node.available = true


func _flatten_layers(layers: Array) -> Array[MapNode]:
	var result: Array[MapNode] = []

	for layer_value in layers:
		var layer: Array = layer_value

		for raw_node in layer:
			var node: MapNode = raw_node as MapNode
			result.append(node)

	return result
