extends Node

const DEFAULT_RUN_PROFILE_PATH: String = "res://data/config/run/DefaultRunProfile.tres"

var map_nodes: Array[MapNode] = []
var map_generated: bool = false

var selected_node_type: int = -1
var selected_node_id: int = -1

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
	map_generated = true


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


func reset_map() -> void:
	map_nodes.clear()
	map_generated = false
	selected_node_type = -1
	selected_node_id = -1
	runtime_map_config = null
