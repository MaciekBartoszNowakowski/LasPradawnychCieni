extends Node

const SETTINGS_PATH := "user://settings.json"

const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

const DEFAULT_MUSIC_VOLUME := 0.8
const DEFAULT_UI_VOLUME := 0.8

var music_volume: float = DEFAULT_MUSIC_VOLUME
var ui_volume: float = DEFAULT_UI_VOLUME


func _ready() -> void:
	load_settings()
	apply_settings()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return

	var data := parsed as Dictionary
	music_volume = clampf(float(data.get("music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	ui_volume = clampf(float(data.get("ui_volume", DEFAULT_UI_VOLUME)), 0.0, 1.0)


func save_settings() -> void:
	var payload := {
		"music_volume": music_volume,
		"ui_volume": ui_volume,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameSettings: nie udało się zapisać ustawień.")
		return
	file.store_string(JSON.stringify(payload, "\t"))


func apply_settings() -> void:
	_set_bus_volume(BUS_MUSIC, music_volume)
	_set_bus_volume(BUS_SFX, ui_volume)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_settings()
	save_settings()


func set_ui_volume(value: float) -> void:
	ui_volume = clampf(value, 0.0, 1.0)
	apply_settings()
	save_settings()


func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, _linear_to_db(linear_volume))


func _linear_to_db(linear_volume: float) -> float:
	if linear_volume <= 0.0001:
		return -80.0
	return linear_to_db(linear_volume)
