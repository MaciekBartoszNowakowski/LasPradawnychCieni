extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"
const NOTICE_FONT_PATH := "res://assets/ui/fonts/IMFellEnglishSC-Regular.ttf"
const BG_PATH := "res://assets/ui/finale/backgrounds/finale_08_epilogue_village.png"
const BG_FALLBACK_PATH := "res://assets/ui/checkpoints/oath_stone/cp_005_intro.png"

const TEXT_COLOR := Color(0.8666667, 0.827451, 0.7372549, 1.0)
const TEXT_HOVER_COLOR := Color(0.9411765, 0.90588236, 0.8156863, 1.0)
const TEXT_PRESSED_COLOR := Color(0.7607843, 0.6901961, 0.52156866, 1.0)
const TEXT_SECONDARY_COLOR := Color(0.78, 0.69, 0.58, 1.0)
const TEXT_MUTED_COLOR := Color(0.7176471, 0.68235296, 0.6, 1.0)
const OUTLINE_COLOR := Color(0.09411765, 0.078431375, 0.07058824, 1.0)

@onready var scene_background: TextureRect = $BackgroundLayer/Background
@onready var base_tint: ColorRect = $BackgroundLayer/BaseTint
@onready var dark_overlay: ColorRect = $BackgroundLayer/DarkOverlay
@onready var vignette: TextureRect = $BackgroundLayer/Vignette
@onready var panel: PanelContainer = $Root/Panel
@onready var title_label: Label = $Root/Panel/MarginContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $Root/Panel/MarginContainer/VBox/SubtitleLabel
@onready var summary_label: Label = $Root/Panel/MarginContainer/VBox/SummaryLabel
@onready var divider: ColorRect = $Root/Panel/MarginContainer/VBox/Divider
@onready var body_text: RichTextLabel = $Root/Panel/MarginContainer/VBox/BodyText
@onready var continue_button: Button = $Root/Panel/MarginContainer/VBox/ContinueButton

var _can_continue := false


func _ready() -> void:
	_setup_style()
	_reset_visuals()
	continue_button.pressed.connect(_on_continue_pressed)
	_populate_epilogue()
	call_deferred("_play_intro")


func _reset_visuals() -> void:
	scene_background.modulate.a = 0.0
	base_tint.modulate.a = 1.0
	dark_overlay.modulate.a = 0.0
	if vignette != null:
		vignette.modulate.a = 0.0
	panel.modulate.a = 0.0
	continue_button.modulate.a = 0.0
	continue_button.disabled = true
	_can_continue = false


func _populate_epilogue() -> void:
	var data: Dictionary = FinaleNarrative.get_epilogue(MapState.finale_resolution)
	title_label.text = str(data.get("title", "Koniec wyprawy"))
	subtitle_label.text = str(data.get("subtitle", ""))
	summary_label.text = str(data.get("summary", ""))
	body_text.text = str(data.get("body", ""))


func _play_intro() -> void:
	var bg_path := BG_PATH
	if not ResourceLoader.exists(bg_path):
		bg_path = BG_FALLBACK_PATH
	if ResourceLoader.exists(bg_path):
		scene_background.texture = load(bg_path) as Texture2D

	var intro := create_tween()
	intro.tween_property(scene_background, "modulate:a", 1.0, 1.0)
	intro.parallel().tween_property(dark_overlay, "modulate:a", 1.0, 1.0)
	if vignette != null:
		intro.parallel().tween_property(vignette, "modulate:a", 0.5, 1.0)
	await intro.finished

	var panel_tween := create_tween()
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	await panel_tween.finished

	_can_continue = true
	continue_button.disabled = false

	var btn := create_tween()
	btn.tween_property(continue_button, "modulate:a", 1.0, 0.3)


func _on_continue_pressed() -> void:
	if not _can_continue:
		return

	_can_continue = false
	continue_button.disabled = true

	if has_node("/root/UiAudio"):
		UiAudio.play_click()

	MapState.reset_map()
	GameState.reset_game()

	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("change_scene"):
		transition.change_scene(MAIN_MENU_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _setup_style() -> void:
	dark_overlay.color = Color(0, 0, 0, 0.45)
	divider.color = Color(0.84705883, 0.8, 0.68235296, 0.34)
	panel.add_theme_stylebox_override("panel", _create_panel_style())
	_apply_button_style(continue_button)

	var font := _get_font()
	if font == null:
		return

	for label: Label in [title_label, subtitle_label, summary_label]:
		label.add_theme_font_override("font", font)

	body_text.add_theme_font_override("normal_font", font)

	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	title_label.add_theme_font_size_override("font_size", 42)
	subtitle_label.add_theme_color_override("font_color", TEXT_MUTED_COLOR)
	subtitle_label.add_theme_font_size_override("font_size", 22)
	summary_label.add_theme_color_override("font_color", TEXT_MUTED_COLOR)
	summary_label.add_theme_font_size_override("font_size", 17)
	body_text.add_theme_color_override("default_color", TEXT_SECONDARY_COLOR)
	body_text.add_theme_font_size_override("normal_font_size", 22)


func _create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.72)
	style.border_color = Color(0.84705883, 0.8, 0.68235296, 0.35)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 16
	style.set_content_margin(SIDE_LEFT, 4.0)
	style.set_content_margin(SIDE_TOP, 4.0)
	style.set_content_margin(SIDE_RIGHT, 4.0)
	style.set_content_margin(SIDE_BOTTOM, 4.0)
	return style


func _create_button_style(is_hover := false, is_disabled := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_content_margin(SIDE_LEFT, 18.0)
	style.set_content_margin(SIDE_TOP, 10.0)
	style.set_content_margin(SIDE_RIGHT, 18.0)
	style.set_content_margin(SIDE_BOTTOM, 10.0)
	style.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.58)
	style.border_color = Color(0.84705883, 0.8, 0.68235296, 0.32)

	if is_hover:
		style.bg_color = Color(0.12, 0.085, 0.045, 0.72)
		style.border_color = Color(0.9019608, 0.8666667, 0.78431374, 0.55)
	if is_disabled:
		style.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.28)

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	return style


func _apply_button_style(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _create_button_style())
	button.add_theme_stylebox_override("hover", _create_button_style(true))
	button.add_theme_stylebox_override("pressed", _create_button_style(true))
	button.add_theme_stylebox_override("disabled", _create_button_style(false, true))
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_HOVER_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_PRESSED_COLOR)
	button.add_theme_font_size_override("font_size", 24)

	var font := _get_font()
	if font != null:
		button.add_theme_font_override("font", font)


func _get_font() -> Font:
	if ResourceLoader.exists(NOTICE_FONT_PATH):
		return load(NOTICE_FONT_PATH) as Font
	return null
