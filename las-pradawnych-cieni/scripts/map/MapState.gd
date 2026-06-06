extends Node

const DEFAULT_RUN_PROFILE_PATH: String = "res://data/config/run/DefaultRunProfile.tres"

const ALIGNMENT_PEOPLE: StringName = &"oath_people"
const ALIGNMENT_FOREST: StringName = &"oath_forest"
const OATH_CHECKPOINT_ID: String = "oath_stone"

var map_nodes: Array[MapNode] = []
var map_generated: bool = false

var selected_node_type: int = -1
var selected_node_id: int = -1
var selected_node_act: int = 0
var selected_side_quest: SideQuestConfig = null
var completed_side_quest_ids: Dictionary = {}
var selected_checkpoint: CheckpointConfig = null
var completed_checkpoint_ids: Dictionary = {}

var discovered_lore_tags: Dictionary = {}
var final_alignment: StringName = &""
var finale_resolution: StringName = &""
var finale_battle_active: bool = false
var run_completed: bool = false

var run_profile: RunProfile = null
var runtime_map_config: MapGenerationConfig = null


func _ready() -> void:
	_load_default_run_profile()


func ensure_map_exists() -> void:
	if map_generated:
		return

	if run_profile == null:
		_load_default_run_profile()

	if run_profile == null:
		push_error("Brak RunProfile - nie można wygenerować mapy.")
		return

	runtime_map_config = run_profile.build_runtime_map_config()

	if runtime_map_config == null:
		push_error("Nie udało się zbudować runtime MapGenerationConfig.")
		return

	var generator := MapGenerator.new()
	map_nodes = generator.generate_map(runtime_map_config, run_profile)

	_initialize_start_node()

	map_generated = true


func _initialize_start_node() -> void:
	if map_nodes.is_empty():
		selected_node_id = -1
		selected_node_type = -1
		return

	var start_node := _get_start_node()

	if start_node == null:
		selected_node_id = -1
		selected_node_type = -1
		return

	for node in map_nodes:
		node.available = false
		node.visited = false

	start_node.visited = true
	start_node.available = false

	selected_node_id = start_node.id
	selected_node_type = start_node.type

	for next_id in start_node.connections:
		var next_node := get_node_by_id(next_id)

		if next_node != null:
			next_node.available = true


func _get_start_node() -> MapNode:
	if map_nodes.is_empty():
		return null

	var start_node: MapNode = map_nodes[0]

	for node in map_nodes:
		if node.layer_index < start_node.layer_index:
			start_node = node
		elif node.layer_index == start_node.layer_index:
			if node.position.y < start_node.position.y:
				start_node = node

	return start_node


func get_node_by_id(node_id: int) -> MapNode:
	for node in map_nodes:
		if node.id == node_id:
			return node

	return null


func _load_default_run_profile() -> void:
	if not ResourceLoader.exists(DEFAULT_RUN_PROFILE_PATH):
		push_warning("Nie znaleziono domyślnego RunProfile: %s" % DEFAULT_RUN_PROFILE_PATH)
		return

	run_profile = load(DEFAULT_RUN_PROFILE_PATH) as RunProfile

	if run_profile == null:
		push_error("Nie udało się załadować RunProfile z: %s" % DEFAULT_RUN_PROFILE_PATH)


func set_run_profile(new_run_profile: RunProfile) -> void:
	run_profile = new_run_profile
	reset_map()


func set_run_profile_from_path(path: String) -> void:
	var loaded_profile := _load_run_profile_from_path(path)
	if loaded_profile == null:
		return
	set_run_profile(loaded_profile)


func load_run_profile_from_path(path: String) -> bool:
	var loaded_profile := _load_run_profile_from_path(path)
	if loaded_profile == null:
		return false
	run_profile = loaded_profile
	return true


func _load_run_profile_from_path(path: String) -> RunProfile:
	if not ResourceLoader.exists(path):
		push_warning("RunProfile nie istnieje: %s" % path)
		return null

	var loaded_profile := load(path) as RunProfile
	if loaded_profile == null:
		push_warning("Nie udało się załadować RunProfile z: %s" % path)
	return loaded_profile


func get_runtime_map_config() -> MapGenerationConfig:
	return runtime_map_config


func get_run_profile() -> RunProfile:
	return run_profile


func set_selected_side_quest(quest: SideQuestConfig) -> void:
	selected_side_quest = quest


func get_selected_side_quest() -> SideQuestConfig:
	return selected_side_quest


func clear_selected_side_quest() -> void:
	selected_side_quest = null


func set_selected_checkpoint(checkpoint: CheckpointConfig) -> void:
	selected_checkpoint = checkpoint


func get_selected_checkpoint() -> CheckpointConfig:
	return selected_checkpoint


func clear_selected_checkpoint() -> void:
	selected_checkpoint = null


func complete_selected_checkpoint() -> void:
	if selected_checkpoint == null:
		return

	var checkpoint_id: String = str(selected_checkpoint.checkpoint_id)
	if not checkpoint_id.is_empty():
		completed_checkpoint_ids[checkpoint_id] = true

	selected_checkpoint = null


func is_checkpoint_completed(checkpoint_id: String) -> bool:
	return completed_checkpoint_ids.has(checkpoint_id)


func complete_selected_side_quest() -> void:
	if selected_side_quest == null:
		return

	if selected_side_quest.quest_id != "":
		completed_side_quest_ids[selected_side_quest.quest_id] = true

	selected_side_quest = null


func is_side_quest_completed(quest_id: String) -> bool:
	return completed_side_quest_ids.has(quest_id)


func record_lore_tag(tag: StringName) -> void:
	if tag.is_empty():
		return

	discovered_lore_tags[tag] = true


func has_lore_tag(tag: StringName) -> bool:
	return discovered_lore_tags.has(tag)


func get_discovered_lore_count() -> int:
	return discovered_lore_tags.size()


func knows_mayor_truth() -> bool:
	return (
		has_lore_tag(&"ledger_opened")
		or has_lore_tag(&"bridge_letter")
		or has_lore_tag(&"ledger_seals")
		or has_lore_tag(&"village_coverup")
	)


func set_final_alignment_from_lore_tag(tag: StringName) -> void:
	if tag == ALIGNMENT_PEOPLE or tag == ALIGNMENT_FOREST:
		final_alignment = tag


func set_finale_resolution(resolution_id: StringName) -> void:
	finale_resolution = resolution_id


func clear_finale_battle() -> void:
	finale_battle_active = false


func mark_run_completed() -> void:
	run_completed = true


func reset_narrative() -> void:
	discovered_lore_tags.clear()
	final_alignment = &""
	finale_resolution = &""
	finale_battle_active = false
	run_completed = false


func reset_map() -> void:
	map_nodes.clear()
	map_generated = false
	selected_node_type = -1
	selected_node_id = -1
	selected_node_act = 0
	runtime_map_config = null
	selected_side_quest = null
	selected_checkpoint = null
	completed_side_quest_ids.clear()
	completed_checkpoint_ids.clear()
	reset_narrative()


func export_state() -> Dictionary:
	var nodes: Array = []
	for node in map_nodes:
		nodes.append(_node_to_dict(node))

	return {
		"nodes": nodes,
		"selected_node_id": selected_node_id,
		"selected_node_type": selected_node_type,
		"completed_checkpoint_ids": _dict_keys_to_array(completed_checkpoint_ids),
		"completed_side_quest_ids": _dict_keys_to_array(completed_side_quest_ids),
		"discovered_lore_tags": _dict_keys_to_array(discovered_lore_tags),
		"final_alignment": str(final_alignment),
		"finale_resolution": str(finale_resolution),
		"finale_battle_active": finale_battle_active,
		"run_completed": run_completed,
	}


func import_state(data: Dictionary, run_profile_path: String) -> bool:
	if data.is_empty():
		return false

	if not load_run_profile_from_path(run_profile_path):
		return false

	runtime_map_config = run_profile.build_runtime_map_config()
	if runtime_map_config == null:
		return false

	map_nodes.clear()
	for raw_node in data.get("nodes", []) as Array:
		var node := _node_from_dict(raw_node as Dictionary)
		if node != null:
			map_nodes.append(node)

	selected_node_id = int(data.get("selected_node_id", -1))
	selected_node_type = int(data.get("selected_node_type", -1))
	selected_side_quest = null
	selected_checkpoint = null

	completed_checkpoint_ids = _array_to_dict(data.get("completed_checkpoint_ids", []))
	completed_side_quest_ids = _array_to_dict(data.get("completed_side_quest_ids", []))
	discovered_lore_tags = _array_to_dict(data.get("discovered_lore_tags", []))
	final_alignment = StringName(str(data.get("final_alignment", "")))
	finale_resolution = StringName(str(data.get("finale_resolution", "")))
	finale_battle_active = bool(data.get("finale_battle_active", false))
	run_completed = bool(data.get("run_completed", false))

	map_generated = true
	return true


func _node_to_dict(node: MapNode) -> Dictionary:
	var checkpoint_id := ""
	if node.checkpoint_config != null:
		checkpoint_id = str(node.checkpoint_config.checkpoint_id)

	var quest_id := ""
	if node.side_quest_config != null:
		quest_id = str(node.side_quest_config.quest_id)

	return {
		"id": node.id,
		"type": node.type,
		"position": {"x": node.position.x, "y": node.position.y},
		"layer_index": node.layer_index,
		"act": node.act,
		"connections": node.connections.duplicate(),
		"available": node.available,
		"visited": node.visited,
		"checkpoint_id": checkpoint_id,
		"quest_id": quest_id,
	}


func _node_from_dict(data: Dictionary) -> MapNode:
	var pos_data: Dictionary = data.get("position", {}) as Dictionary
	var position := Vector2(float(pos_data.get("x", 0.0)), float(pos_data.get("y", 0.0)))
	var node := MapNode.new(
		int(data.get("id", -1)),
		int(data.get("type", 0)),
		position,
		int(data.get("layer_index", 0))
	)
	node.act = int(data.get("act", 0))

	node.connections = []
	for raw_id in data.get("connections", []) as Array:
		node.connections.append(int(raw_id))

	node.available = bool(data.get("available", false))
	node.visited = bool(data.get("visited", false))

	var checkpoint_id: String = str(data.get("checkpoint_id", ""))
	if not checkpoint_id.is_empty():
		node.checkpoint_config = _resolve_checkpoint(checkpoint_id)

	var quest_id: String = str(data.get("quest_id", ""))
	if not quest_id.is_empty():
		node.side_quest_config = _resolve_side_quest(quest_id)

	return node


func _resolve_checkpoint(checkpoint_id: String) -> CheckpointConfig:
	if runtime_map_config == null:
		return null

	for raw_checkpoint in runtime_map_config.checkpoint_pool:
		var checkpoint := raw_checkpoint as CheckpointConfig
		if checkpoint != null and str(checkpoint.checkpoint_id) == checkpoint_id:
			return checkpoint

	return null


func _resolve_side_quest(quest_id: String) -> SideQuestConfig:
	if runtime_map_config == null:
		return null

	for raw_quest in runtime_map_config.side_quest_pool:
		var quest := raw_quest as SideQuestConfig
		if quest != null and str(quest.quest_id) == quest_id:
			return quest

	return null


func _dict_keys_to_array(source: Dictionary) -> Array:
	var keys: Array = []
	for key in source.keys():
		keys.append(str(key))
	return keys


func _array_to_dict(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if source is Array:
		for raw_key in source as Array:
			result[str(raw_key)] = true
	return result
