extends Control

@onready var UIRoot: MarginContainer = $UIRoot
@onready var btn_new_game: Button = $UIRoot/CenterBox/MenuColumn/BoardPanel/BoardVBox/BtnNewGame
@onready var btn_load_game: Button = $UIRoot/CenterBox/MenuColumn/BoardPanel/BoardVBox/BtnContinue
@onready var btn_options: Button = $UIRoot/CenterBox/MenuColumn/BoardPanel/BoardVBox/BtnOptions
@onready var btn_exit: Button = $UIRoot/CenterBox/MenuColumn/BoardPanel/BoardVBox/BtnExit
@onready var audio_music: AudioStreamPlayer = $AudioMusic
@onready var prologue_intro: CanvasLayer = $PrologueIntro
@onready var village_gate: CanvasLayer = $VillageGateOverlay
@onready var notice_board = $NoticeBoardOverlay
@onready var mayor_house = $MayorHouseOverlay
@onready var mayor_house_interior = $MayorInteriorDialogOverlay
@onready var save_slots_panel: SaveSlotsPanel = $SaveSlotsPanel
@onready var settings_panel: SettingsPanel = $SettingsPanel

var prologue_backdrop: ColorRect

@export var debug := false

const MAP_SCENE_PATH := "res://scenes/map/Map.tscn"


func _ready() -> void:
	_create_prologue_backdrop()
	UIRoot.modulate.a = 1.0
	audio_music.play()
	btn_new_game.pressed.connect(_on_btn_new_game_pressed)
	btn_load_game.pressed.connect(_on_btn_load_game_pressed)
	btn_options.pressed.connect(_on_btn_options_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)
	save_slots_panel.slot_selected.connect(_on_save_slot_selected)
	save_slots_panel.slot_deleted.connect(_on_save_slot_deleted)

	prologue_intro.hide()
	village_gate.hide()
	notice_board.hide()
	mayor_house.hide()
	mayor_house_interior.hide()
	prologue_backdrop.hide()

	_refresh_load_button()

	if debug:
		UIRoot.hide()
		prologue_backdrop.show()
		mayor_house_interior.play()
		return

	prologue_intro.finished.connect(_on_prologue_intro_finished)
	village_gate.finished.connect(_on_village_gate_finished)
	notice_board.finished.connect(_on_notice_board_finished)
	mayor_house.finished.connect(_on_mayor_house_finished)
	mayor_house_interior.finished.connect(_on_mayor_interior_house_finished)


func _create_prologue_backdrop() -> void:
	prologue_backdrop = ColorRect.new()
	prologue_backdrop.name = "PrologueBackdrop"
	prologue_backdrop.color = Color.BLACK
	prologue_backdrop.modulate.a = 1.0
	prologue_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	prologue_backdrop.z_index = 100
	prologue_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(prologue_backdrop)
	move_child(prologue_backdrop, 3)


func _refresh_load_button() -> void:
	btn_load_game.text = "Wczytaj grę"
	btn_load_game.disabled = not SaveGame.has_any_slot()


func _on_btn_new_game_pressed() -> void:
	btn_new_game.disabled = true
	btn_load_game.disabled = true
	btn_exit.disabled = true
	UiAudio.play_click()
	await get_tree().create_timer(0.08).timeout

	MapState.reset_map()
	GameState.reset_game()

	prologue_backdrop.show()
	prologue_backdrop.modulate.a = 0.0

	var fade_to_black := create_tween()
	fade_to_black.tween_property(prologue_backdrop, "modulate:a", 1.0, 0.4)

	await fade_to_black.finished

	UIRoot.hide()
	prologue_intro.play()


func _on_btn_load_game_pressed() -> void:
	if not SaveGame.has_any_slot():
		return

	MenuPanelStyle.play_click()
	save_slots_panel.open(SaveSlotsPanel.MODE_LOAD)


func _on_btn_options_pressed() -> void:
	MenuPanelStyle.play_click()
	settings_panel.open()


func _on_save_slot_deleted(_slot_index: int) -> void:
	_refresh_load_button()


func _on_save_slot_selected(slot_index: int) -> void:
	if not SaveGame.load_from_slot(slot_index):
		push_warning("MainMenu: nie udało się wczytać slotu %d." % slot_index)
		return

	btn_new_game.disabled = true
	btn_load_game.disabled = true
	btn_exit.disabled = true

	if has_node("/root/SceneTransition"):
		await SceneTransition.change_scene(MAP_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(MAP_SCENE_PATH)


func _on_prologue_intro_finished() -> void:
	village_gate.play()


func _on_village_gate_finished() -> void:
	notice_board.play()


func _on_notice_board_finished() -> void:
	mayor_house.play()


func _on_mayor_house_finished() -> void:
	mayor_house_interior.play()


func _on_mayor_interior_house_finished() -> void:
	await SceneTransition.change_scene(MAP_SCENE_PATH)


func _on_btn_exit_pressed() -> void:
	UiAudio.play_click()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if settings_panel.is_open():
		settings_panel.close_panel()
		get_viewport().set_input_as_handled()
		return

	if save_slots_panel.is_open():
		save_slots_panel.close_panel()
		get_viewport().set_input_as_handled()
