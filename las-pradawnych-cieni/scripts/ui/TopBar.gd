extends Control
class_name GameTopBar

signal save_pressed()

@export var title_text: String = ""
@export var objective_text: String = ""
@export var show_gold: bool = true
@export var show_save_button: bool = false

@onready var title_label: Label = $MarginContainer/HBoxContainer/LeftBlock/TitleLabel
@onready var objective_label: Label = $MarginContainer/HBoxContainer/CenterBlock/ObejctiveLabel
@onready var save_button: Button = $MarginContainer/HBoxContainer/RightBlock/SaveButton
@onready var gold_label: Label = $MarginContainer/HBoxContainer/RightBlock/GoldLabel

var _default_objective_text: String = ""


func _ready() -> void:
	_default_objective_text = objective_text
	save_button.pressed.connect(_on_save_pressed)
	_apply_save_button_style()
	_apply_texts()
	_connect_team()
	_refresh_gold()


func setup(title: String, objective: String) -> void:
	title_text = title
	objective_text = objective
	_default_objective_text = objective
	_apply_texts()
	_refresh_gold()


func set_save_button_visible(visible: bool) -> void:
	show_save_button = visible
	if save_button != null:
		save_button.visible = visible


func refresh_team_display() -> void:
	_connect_team()
	_refresh_gold()


func show_temporary_objective(message: String, duration: float = 2.0) -> void:
	objective_label.text = message
	await get_tree().create_timer(duration).timeout
	objective_label.text = _default_objective_text


func _apply_texts() -> void:
	title_label.text = title_text
	objective_label.text = objective_text
	gold_label.visible = show_gold
	if save_button != null:
		save_button.visible = show_save_button


func _on_save_pressed() -> void:
	save_pressed.emit()


func _connect_team() -> void:
	if GameState.player_team == null:
		return
	
	if not GameState.player_team.money_changed.is_connected(_on_team_money_changed):
		GameState.player_team.money_changed.connect(_on_team_money_changed)


func _refresh_gold() -> void:
	if not show_gold:
		return
	
	if GameState.player_team == null:
		gold_label.text = "Złoto: 0"
		return
	
	gold_label.text = "Złoto: " + str(GameState.player_team.money)


func _on_team_money_changed(new_money: int) -> void:
	if show_gold:
		gold_label.text = "Złoto: " + str(new_money)


func _apply_save_button_style() -> void:
	if save_button == null:
		return

	save_button.focus_mode = Control.FOCUS_NONE
	save_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	save_button.custom_minimum_size = Vector2(108.0, 30.0)
	save_button.add_theme_stylebox_override("normal", _create_save_button_style())
	save_button.add_theme_stylebox_override("hover", _create_save_button_style(true))
	save_button.add_theme_stylebox_override("pressed", _create_save_button_style(true))
	save_button.add_theme_color_override("font_color", Color(0.9098039, 0.8509804, 0.74509805, 1.0))
	save_button.add_theme_color_override("font_hover_color", Color(0.9411765, 0.90588236, 0.8156863, 1.0))
	save_button.add_theme_color_override("font_pressed_color", Color(0.8117647, 0.77254903, 0.68235296, 1.0))
	save_button.add_theme_font_size_override("font_size", 18)

	var font := title_label.get_theme_font("font")
	if font != null:
		save_button.add_theme_font_override("font", font)


func _create_save_button_style(is_hover := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_content_margin(SIDE_LEFT, 12.0)
	style.set_content_margin(SIDE_TOP, 4.0)
	style.set_content_margin(SIDE_RIGHT, 12.0)
	style.set_content_margin(SIDE_BOTTOM, 4.0)
	style.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.72)
	style.border_color = Color(0.84705883, 0.8, 0.68235296, 0.38)

	if is_hover:
		style.bg_color = Color(0.12, 0.085, 0.045, 0.88)
		style.border_color = Color(0.9019608, 0.8666667, 0.78431374, 0.55)

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style
