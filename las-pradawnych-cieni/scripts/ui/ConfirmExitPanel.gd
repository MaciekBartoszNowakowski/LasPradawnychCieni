class_name ConfirmExitPanel
extends Control

signal confirmed()
signal cancelled()

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var message_label: Label = $Panel/MarginContainer/VBox/MessageLabel
@onready var confirm_button: Button = $Panel/MarginContainer/VBox/Buttons/ConfirmButton
@onready var cancel_button: Button = $Panel/MarginContainer/VBox/Buttons/CancelButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_setup_style()
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func is_open() -> bool:
	return visible


func open() -> void:
	_fade_in()


func close_panel() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()


func _on_confirm_pressed() -> void:
	MenuPanelStyle.play_click()
	close_panel()
	confirmed.emit()


func _on_cancel_pressed() -> void:
	MenuPanelStyle.play_click()
	close_panel()
	cancelled.emit()


func _setup_style() -> void:
	panel.add_theme_stylebox_override("panel", MenuPanelStyle.create_panel_style())
	MenuPanelStyle.apply_muted_label(message_label, 18)
	message_label.text = (
		"Wrócić do menu głównego?\n"
		+ "Postęp od ostatniego zapisu zostanie utracony."
	)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	for button in [confirm_button, cancel_button]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.custom_minimum_size = Vector2(0.0, 44.0)
		MenuPanelStyle.apply_button_style(button, 20)

	confirm_button.text = "Tak"
	cancel_button.text = "Anuluj"


func _fade_in() -> void:
	show()
	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.25)
