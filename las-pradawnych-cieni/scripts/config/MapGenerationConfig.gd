class_name MapGenerationConfig
extends Resource

const MIN_ACT_COUNT: int = 1

enum MinibossMode {
	OPTIONAL,
	SEMI_REQUIRED,
	REQUIRED
}

@export_group("Run Structure")
@export var act_count: int = 3
@export var base_decision_length: int = 12
@export var act_length_weights: PackedFloat32Array = PackedFloat32Array([1.0, 1.35, 1.0])

@export var mandatory_story_event_count: int = 2
@export var mandatory_story_spacing_min: int = 3
@export var mandatory_story_spacing_max: int = 6

@export var start_node_type: int = MapEnums.NodeType.EVENT
@export var boss_node_type: int = MapEnums.NodeType.BOSS

@export_group("Topology")
@export var max_active_paths: int = 4
@export var preferred_active_paths_min: int = 2
@export var preferred_active_paths_max: int = 3

@export var path_commitment_length_min: int = 3
@export var path_commitment_length_max: int = 5

@export var short_branch_length_min: int = 1
@export var short_branch_length_max: int = 2

@export_range(0.0, 1.0, 0.01) var branch_spawn_chance: float = 0.22
@export_range(0.0, 1.0, 0.01) var path_split_chance: float = 0.35
@export_range(0.0, 1.0, 0.01) var path_merge_chance: float = 0.40

#@export var allow_path_absorption: bool = true
#@export var allow_path_rebirth: bool = true

#@export_range(0.0, 1.0, 0.01) var single_node_random_occurrence_chance: float = 0.10
#@export_range(0.0, 1.0, 0.01) var topology_smoothness: float = 0.75

@export_group("Content Distribution")
@export var dominant_node_type: int = MapEnums.NodeType.BATTLE

@export var combat_target_count: int = 7
@export var combat_min_count: int = 5
@export var combat_max_count: int = 10

@export var rest_target_count: int = 2
@export var rest_min_count: int = 0
@export var rest_max_count: int = 3
#@export var rest_allow_zero: bool = true

@export var shop_target_count: int = 1
@export var shop_min_count: int = 0
@export var shop_max_count: int = 2
#@export var shop_allow_zero: bool = true

@export var optional_event_target_count: int = 3
@export var optional_event_min_count: int = 1
@export var optional_event_max_count: int = 5

@export var miniboss_mode: MinibossMode = MinibossMode.OPTIONAL
@export var miniboss_target_count: int = 1
@export var miniboss_allowed_acts: PackedInt32Array = PackedInt32Array([1])
#@export var miniboss_can_be_side_branch_only: bool = false
#@export var miniboss_can_be_main_path: bool = true

@export_group("Act Rules")
@export var act_rules: Array[MapActRuleConfig] = []

@export_group("Boss Phase Rules")
@export var require_pre_boss_story_event: bool = true
#@export var pre_boss_node_must_be_single: bool = true
@export var allow_rest_before_boss: bool = false
@export var allow_shop_before_boss: bool = false

@export_group("Visibility Rules")
#@export var generate_full_map_upfront: bool = true
@export var show_start_always: bool = true
@export var show_boss_always: bool = true
@export var show_visited_nodes: bool = true
@export var show_currently_reachable_nodes: bool = true
@export var show_unreachable_future_nodes: bool = false
@export var developer_reveal_all: bool = false

@export_group("Layout Rules")
@export var start_x: float = 150.0
#@export var act_spacing: float = 280.0
@export var segment_spacing: float = 200.0
@export var top_margin: float = 100.0
@export var map_height: float = 500.0
@export var jitter_x: float = 15.0
@export var jitter_y: float = 20.0
#@export var single_node_centering: bool = true
@export var avoid_line_crossing_preference: bool = true
#@export_range(0.0, 1.0, 0.01) var merge_visual_compactness: float = 0.65

@export_group("Validation Rules")
@export var require_boss_reachable: bool = true
@export var require_all_main_story_events_reachable: bool = true
@export var require_no_dead_end_main_paths: bool = true
@export var allow_dead_end_side_branches: bool = true
@export var max_dead_end_branch_length: int = 2
@export var max_consecutive_combats: int = 4
@export var retry_generation_on_validation_fail: bool = true
@export var generation_retry_limit: int = 20


func get_safe_act_count() -> int:
	return max(MIN_ACT_COUNT, act_count)


func get_safe_base_decision_length() -> int:
	return max(1, base_decision_length)


func get_act_length_weight(act_index: int) -> float:
	if act_index < 0:
		return 1.0

	if act_index >= act_length_weights.size():
		return 1.0

	return max(0.01, float(act_length_weights[act_index]))


func get_all_act_length_weights() -> Array[float]:
	var count: int = get_safe_act_count()
	var result: Array[float] = []

	for act_index in range(count):
		result.append(get_act_length_weight(act_index))

	return result


func get_total_act_length_weight() -> float:
	var weights: Array[float] = get_all_act_length_weights()
	var total: float = 0.0

	for value in weights:
		total += float(value)

	return max(total, 0.01)


#func get_estimated_decisions_for_act(act_index: int) -> int:
	#var total_weight: float = get_total_act_length_weight()
	#var act_weight: float = get_act_length_weight(act_index)
	#var estimated: float = float(get_safe_base_decision_length()) * act_weight / total_weight
	#return max(1, int(round(estimated)))


func get_story_spacing_min() -> int:
	return max(1, mandatory_story_spacing_min)


func get_story_spacing_max() -> int:
	return max(get_story_spacing_min(), mandatory_story_spacing_max)


func get_preferred_active_paths_min() -> int:
	return clamp(preferred_active_paths_min, 1, max(1, max_active_paths))


func get_preferred_active_paths_max() -> int:
	return clamp(preferred_active_paths_max, get_preferred_active_paths_min(), max(1, max_active_paths))


func get_path_commitment_length_min() -> int:
	return max(1, path_commitment_length_min)


func get_path_commitment_length_max() -> int:
	return max(get_path_commitment_length_min(), path_commitment_length_max)


func get_short_branch_length_min() -> int:
	return max(1, short_branch_length_min)


func get_short_branch_length_max() -> int:
	return max(get_short_branch_length_min(), short_branch_length_max)


func get_act_rule(act_index: int) -> MapActRuleConfig:
	for rule in act_rules:
		if rule != null and rule.act_id == act_index:
			return rule

	return null


func get_or_create_default_act_rule(act_index: int) -> MapActRuleConfig:
	var existing_rule: MapActRuleConfig = get_act_rule(act_index)
	if existing_rule != null:
		return existing_rule

	var fallback_rule := MapActRuleConfig.new()
	fallback_rule.act_id = act_index
	fallback_rule.display_name = "Act %d" % [act_index + 1]
	fallback_rule.relative_length_weight = get_act_length_weight(act_index)
	fallback_rule.preferred_path_count = clamp(2, 1, max(1, max_active_paths))
	return fallback_rule


func is_act_allowed_for_miniboss(act_index: int) -> bool:
	return miniboss_allowed_acts.has(act_index)


#func get_target_count_for_node_type(node_type: int) -> int:
	#match node_type:
		#MapEnums.NodeType.BATTLE:
			#return combat_target_count
		#MapEnums.NodeType.REST:
			#return rest_target_count
		#MapEnums.NodeType.SHOP:
			#return shop_target_count
		#MapEnums.NodeType.EVENT:
			#return optional_event_target_count
		#_:
			#return 0


#func get_min_count_for_node_type(node_type: int) -> int:
	#match node_type:
		#MapEnums.NodeType.BATTLE:
			#return combat_min_count
		#MapEnums.NodeType.REST:
			#return rest_min_count
		#MapEnums.NodeType.SHOP:
			#return shop_min_count
		#MapEnums.NodeType.EVENT:
			#return optional_event_min_count
		#_:
			#return 0
#
#
#func get_max_count_for_node_type(node_type: int) -> int:
	#match node_type:
		#MapEnums.NodeType.BATTLE:
			#return max(combat_min_count, combat_max_count)
		#MapEnums.NodeType.REST:
			#return max(rest_min_count, rest_max_count)
		#MapEnums.NodeType.SHOP:
			#return max(shop_min_count, shop_max_count)
		#MapEnums.NodeType.EVENT:
			#return max(optional_event_min_count, optional_event_max_count)
		#_:
			#return 0


func duplicate_config() -> MapGenerationConfig:
	return duplicate(true) as MapGenerationConfig
