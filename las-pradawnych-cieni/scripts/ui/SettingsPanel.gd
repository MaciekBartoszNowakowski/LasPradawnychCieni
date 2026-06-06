class_name SettingsPanel
extends Control

signal panel_closed()

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel
@onready var music_slider: HSlider = $Panel/MarginContainer/VBox/Rows/MusicRow/MusicSlider
@onready var music_value_label: Label = $Panel/MarginContainer/VBox/Rows/MusicRow/MusicValueLabel
@onready var ui_slider: HSlider = $Panel/MarginContainer/VBox/Rows/UiRow/UiSlider
@onready var ui_value_label: Label = $Panel/MarginContainer/VBox/Rows/UiRow/UiValueLabel
@onready var close_button: Button = $Panel/MarginContainer/VBox/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_setup_style()
	close_button.pressed.connect(_on_close_pressed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	ui_slider.value_changed.connect(_on_ui_slider_changed)


func is_open() -> bool:
	return visible


func open() -> void:
	_sync_sliders_from_settings()
	_fade_in()


func close_panel() -> void:
	hide()
	panel_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func _sync_sliders_from_settings() -> void:
	music_slider.set_value_no_signal(GameSettings.music_volume * 100.0)
	ui_slider.set_value_no_signal(GameSettings.ui_volume * 100.0)
	_update_value_labels()


func _on_music_slider_changed(value: float) -> void:
	GameSettings.set_music_volume(value / 100.0)
	_update_value_labels()


func _on_ui_slider_changed(value: float) -> void:
	GameSettings.set_ui_volume(value / 100.0)
	_update_value_labels()


func _update_value_labels() -> void:
	music_value_label.text = "%d%%" % int(round(music_slider.value))
	ui_value_label.text = "%d%%" % int(round(ui_slider.value))


func _on_close_pressed() -> void:
	MenuPanelStyle.play_click()
	close_panel()


func _setup_style() -> void:
	panel.add_theme_stylebox_override("panel", MenuPanelStyle.create_panel_style())
	MenuPanelStyle.apply_title_label(title_label)
	MenuPanelStyle.apply_button_style(close_button)
	close_button.text = "Powrót"

	for label in [$Panel/MarginContainer/VBox/Rows/MusicRow/MusicLabel, $Panel/MarginContainer/VBox/Rows/UiRow/UiLabel]:
		MenuPanelStyle.apply_body_label(label as Label, 18)

	for value_label in [music_value_label, ui_value_label]:
		MenuPanelStyle.apply_muted_label(value_label as Label, 16)


func _fade_in() -> void:
	show()
	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.25)
