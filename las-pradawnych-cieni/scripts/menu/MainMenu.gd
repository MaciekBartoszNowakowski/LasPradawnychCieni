extends Control

@onready var btn_new_game: Button = $UIRoot/CenterBox/MenuColumn/BoardPanel/BoardVBox/BtnNewGame
@onready var btn_exit: Button = $UIRoot/CenterBox/MenuColumn/BoardPanel/BoardVBox/BtnExit

@onready var audio_music: AudioStreamPlayer = $AudioMusic
@onready var audio_ui: AudioStreamPlayer = $AudioUI

const MAP_SCENE_PATH := "res://scenes/map/Map.tscn"

func _ready() -> void:
	audio_music.play()
	btn_new_game.pressed.connect(_on_btn_new_game_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)

func _play_click() -> void:
	audio_ui.play()

func _on_btn_new_game_pressed() -> void:
	_play_click()
	await get_tree().create_timer(0.08).timeout
	MapState.reset_map()
	GameState.player_team = Team.new()
	get_tree().change_scene_to_file(MAP_SCENE_PATH)

func _on_btn_exit_pressed() -> void:
	_play_click()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()
