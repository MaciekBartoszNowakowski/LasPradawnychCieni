extends Node

const DEFAULT_RUN_PROFILE_PATH: String = "res://data/config/run/DefaultRunProfile.tres"

var map_nodes: Array[MapNode] = []
var map_generated: bool = false

var selected_node_type: int = -1
var selected_node_id: int = -1
var selected_node_act: int = 0
var selected_side_quest: SideQuestConfig = null
var completed_side_quest_ids: Dictionary = {}
var selected_checkpoint: CheckpointConfig = null
var completed_checkpoint_ids: Dictionary = {}

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
	if not ResourceLoader.exists(path):
		push_warning("RunProfile nie istnieje: %s" % path)
		return

	var loaded_profile := load(path) as RunProfile

	if loaded_profile == null:
		push_warning("Nie udało się załadować RunProfile z: %s" % path)
		return

	set_run_profile(loaded_profile)


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
