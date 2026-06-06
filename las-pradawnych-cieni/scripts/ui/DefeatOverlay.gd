class_name DefeatOverlay
extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var message_label: Label = $Panel/MarginContainer/VBox/MessageLabel
@onready var menu_button: Button = $Panel/MarginContainer/VBox/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_setup_style()
	menu_button.pressed.connect(_on_menu_pressed)


func show_overlay() -> void:
	show()
	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.3)


func _on_menu_pressed() -> void:
	MenuPanelStyle.play_click()
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("change_scene"):
		transition.change_scene(MAIN_MENU_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _setup_style() -> void:
	panel.add_theme_stylebox_override("panel", MenuPanelStyle.create_panel_style())
	MenuPanelStyle.apply_muted_label(message_label, 20)
	message_label.text = "Drużyna upadła w sercu lasu."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MenuPanelStyle.apply_button_style(menu_button, 22)
	menu_button.text = "Menu główne"
