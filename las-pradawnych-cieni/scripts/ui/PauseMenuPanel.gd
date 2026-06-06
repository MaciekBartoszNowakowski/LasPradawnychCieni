class_name PauseMenuPanel
extends Control

signal save_requested()
signal settings_requested()
signal exit_requested()
signal panel_closed()

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel
@onready var save_button: Button = $Panel/MarginContainer/VBox/Buttons/SaveButton
@onready var settings_button: Button = $Panel/MarginContainer/VBox/Buttons/SettingsButton
@onready var exit_button: Button = $Panel/MarginContainer/VBox/Buttons/ExitButton
@onready var resume_button: Button = $Panel/MarginContainer/VBox/Buttons/ResumeButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_setup_style()
	save_button.pressed.connect(_on_save_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	resume_button.pressed.connect(_on_resume_pressed)


func is_open() -> bool:
	return visible


func open() -> void:
	_fade_in()


func close_panel() -> void:
	hide()
	panel_closed.emit()


func _on_save_pressed() -> void:
	MenuPanelStyle.play_click()
	save_requested.emit()


func _on_settings_pressed() -> void:
	MenuPanelStyle.play_click()
	settings_requested.emit()


func _on_exit_pressed() -> void:
	MenuPanelStyle.play_click()
	exit_requested.emit()


func _on_resume_pressed() -> void:
	MenuPanelStyle.play_click()
	close_panel()


func _setup_style() -> void:
	panel.add_theme_stylebox_override("panel", MenuPanelStyle.create_panel_style())
	MenuPanelStyle.apply_title_label(title_label)
	title_label.text = "Menu"

	for button in [save_button, settings_button, exit_button, resume_button]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.custom_minimum_size = Vector2(0.0, 48.0)
		MenuPanelStyle.apply_button_style(button)


func _fade_in() -> void:
	show()
	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.25)
