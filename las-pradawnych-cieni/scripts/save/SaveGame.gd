extends Node

const SAVE_VERSION := 1
const SLOT_COUNT := 3
const SAVES_DIR := "user://saves/"

const DEFAULT_RUN_PROFILE_PATH := MapState.DEFAULT_RUN_PROFILE_PATH

var pending_map_ui: Dictionary = {}


func _ready() -> void:
	_ensure_saves_dir()


func _ensure_saves_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVES_DIR):
		DirAccess.make_dir_recursive_absolute(SAVES_DIR)


func get_slot_path(slot_index: int) -> String:
	return SAVES_DIR + "slot_%d.json" % slot_index


func has_slot(slot_index: int) -> bool:
	if not _is_valid_slot(slot_index):
		return false
	return FileAccess.file_exists(get_slot_path(slot_index))


func has_any_slot() -> bool:
	for slot_index in range(SLOT_COUNT):
		if has_slot(slot_index):
			return true
	return false


func get_slot_summary(slot_index: int) -> Dictionary:
	var summary := {
		"slot_index": slot_index,
		"occupied": false,
		"title": "Slot %d" % (slot_index + 1),
		"subtitle": "Pusty",
		"saved_at_unix": 0,
		"money": 0,
		"lore_count": 0,
		"alignment_label": "",
	}

	if not has_slot(slot_index):
		return summary

	var data := _read_slot_file(slot_index)
	if data.is_empty():
		return summary

	summary["occupied"] = true
	summary["saved_at_unix"] = int(data.get("saved_at_unix", 0))

	var game_state: Dictionary = data.get("game_state", {}) as Dictionary
	summary["money"] = int(game_state.get("money", 0))

	var map_state: Dictionary = data.get("map_state", {}) as Dictionary
	var lore_tags: Array = map_state.get("discovered_lore_tags", []) as Array
	summary["lore_count"] = lore_tags.size()
	summary["alignment_label"] = _alignment_label(str(map_state.get("final_alignment", "")))

	var time_label := _format_saved_at(summary["saved_at_unix"])
	summary["subtitle"] = (
		"Złoto: %d · %d wskazówek · %s%s"
		% [
			summary["money"],
			summary["lore_count"],
			summary["alignment_label"],
			time_label,
		]
	)

	return summary


func save_to_slot(slot_index: int, map_ui: Dictionary = {}) -> bool:
	if not _is_valid_slot(slot_index):
		return false

	if MapState.run_completed or MapState.finale_battle_active:
		return false

	if not MapState.map_generated or MapState.map_nodes.is_empty():
		return false

	_ensure_saves_dir()

	var payload := {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"run_profile_path": DEFAULT_RUN_PROFILE_PATH,
		"map_state": MapState.export_state(),
		"game_state": GameState.export_state(),
		"map_ui": map_ui,
	}

	var json_text := JSON.stringify(payload, "\t")
	var file := FileAccess.open(get_slot_path(slot_index), FileAccess.WRITE)
	if file == null:
		push_error("SaveGame: nie udało się zapisać slotu %d." % slot_index)
		return false

	file.store_string(json_text)
	return true


func load_from_slot(slot_index: int) -> bool:
	if not has_slot(slot_index):
		return false

	var data := _read_slot_file(slot_index)
	if data.is_empty():
		return false

	if int(data.get("version", 0)) != SAVE_VERSION:
		push_warning("SaveGame: nieobsługiwana wersja zapisu w slocie %d." % slot_index)
		return false

	var run_profile_path: String = str(data.get("run_profile_path", DEFAULT_RUN_PROFILE_PATH))
	var map_state: Dictionary = data.get("map_state", {}) as Dictionary
	var game_state: Dictionary = data.get("game_state", {}) as Dictionary

	if not MapState.import_state(map_state, run_profile_path):
		return false

	GameState.import_state(game_state)
	pending_map_ui = data.get("map_ui", {}) as Dictionary
	return true


func take_pending_map_ui() -> Dictionary:
	var ui := pending_map_ui.duplicate()
	pending_map_ui.clear()
	return ui


func delete_slot(slot_index: int) -> bool:
	if not has_slot(slot_index):
		return false

	var absolute_path := ProjectSettings.globalize_path(get_slot_path(slot_index))
	var err := DirAccess.remove_absolute(absolute_path)
	if err != OK:
		push_warning("SaveGame: nie udało się usunąć slotu %d (błąd %d)." % [slot_index, err])
		return false

	return true


func _read_slot_file(slot_index: int) -> Dictionary:
	var path := get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary

	return {}


func _is_valid_slot(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < SLOT_COUNT


func _alignment_label(alignment: String) -> String:
	if alignment == str(MapState.ALIGNMENT_PEOPLE):
		return "przysięga: ludzie"
	if alignment == str(MapState.ALIGNMENT_FOREST):
		return "przysięga: las"
	return "bez przysięgi"


func _format_saved_at(saved_at_unix: int) -> String:
	if saved_at_unix <= 0:
		return ""

	var timezone := Time.get_time_zone_from_system()
	var bias_minutes := int(timezone.get("bias", 0))
	var local_unix := saved_at_unix + bias_minutes * 60
	var datetime := Time.get_datetime_dict_from_unix_time(local_unix)
	return (
		" · %02d.%02d.%04d %02d:%02d"
		% [
			int(datetime.get("day", 0)),
			int(datetime.get("month", 0)),
			int(datetime.get("year", 0)),
			int(datetime.get("hour", 0)),
			int(datetime.get("minute", 0)),
		]
	)
