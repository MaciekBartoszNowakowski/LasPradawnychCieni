extends Control

@onready var UIRoot: MarginContainer = $UIRoot
@onready var btn_new_game: Button = $UIRoot/CenterBox/MenuColumn/BoardPanel/BoardVBox/BtnNewGame
@onready var btn_exit: Button = $UIRoot/CenterBox/MenuColumn/BoardPanel/BoardVBox/BtnExit
@onready var audio_music: AudioStreamPlayer = $AudioMusic
@onready var prologue_intro: CanvasLayer = $PrologueIntro
@onready var village_gate: CanvasLayer = $VillageGateOverlay
@onready var notice_board = $NoticeBoardOverlay
@onready var mayor_house = $MayorHouseOverlay
@onready var mayor_house_interior = $MayorInteriorDialogOverlay

@export var debug := false

func _ready() -> void:
	audio_music.play()
	btn_new_game.pressed.connect(_on_btn_new_game_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)
	
	prologue_intro.hide()
	village_gate.hide()
	notice_board.hide()
	mayor_house.hide()
	mayor_house_interior.hide()
	
	if debug:
		UIRoot.hide()
		mayor_house_interior.play()
		return
	
	prologue_intro.finished.connect(_on_prologue_intro_finished)
	village_gate.finished.connect(_on_village_gate_finished)
	notice_board.finished.connect(_on_notice_board_finished)
	mayor_house.finished.connect(_on_mayor_house_finished)
	mayor_house_interior.finished.connect(_on_mayor_interior_house_finished)

func _on_btn_new_game_pressed() -> void:
	UiAudio.play_click()
	await get_tree().create_timer(0.08).timeout

	MapState.reset_map()
	GameState.player_team = Team.new()

	prologue_intro.play()

func _on_prologue_intro_finished() -> void:
	village_gate.play()

func _on_village_gate_finished() -> void:
	notice_board.play()
	
func _on_notice_board_finished() -> void:
	mayor_house.play()

func _on_mayor_house_finished() -> void:
	mayor_house_interior.play()

func _on_mayor_interior_house_finished() -> void:
	await SceneTransition.change_scene("res://scenes/map/Map.tscn")

func _on_btn_exit_pressed() -> void:
	UiAudio.play_click()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()
