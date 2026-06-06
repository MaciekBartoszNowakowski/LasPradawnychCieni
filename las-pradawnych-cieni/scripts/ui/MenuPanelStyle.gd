class_name MenuPanelStyle

const FONT_PATH := "res://assets/ui/fonts/IMFellEnglishSC-Regular.ttf"

const TEXT_COLOR := Color(0.8666667, 0.827451, 0.7372549, 1.0)
const TEXT_HOVER_COLOR := Color(0.9411765, 0.90588236, 0.8156863, 1.0)
const TEXT_PRESSED_COLOR := Color(0.7607843, 0.6901961, 0.52156866, 1.0)
const TEXT_MUTED_COLOR := Color(0.7176471, 0.68235296, 0.6, 1.0)
const TITLE_COLOR := Color(0.84705883, 0.8, 0.68235296, 1.0)


static func get_font() -> Font:
	if ResourceLoader.exists(FONT_PATH):
		return load(FONT_PATH) as Font
	return null


static func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.92)
	style.border_color = Color(0.84705883, 0.8, 0.68235296, 0.35)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 18
	style.set_content_margin(SIDE_LEFT, 8.0)
	style.set_content_margin(SIDE_TOP, 8.0)
	style.set_content_margin(SIDE_RIGHT, 8.0)
	style.set_content_margin(SIDE_BOTTOM, 8.0)
	return style


static func create_button_style(is_hover := false, is_disabled := false) -> StyleBoxFlat:
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


static func apply_button_style(button: Button, font_size: int = 22) -> void:
	button.add_theme_stylebox_override("normal", create_button_style())
	button.add_theme_stylebox_override("hover", create_button_style(true))
	button.add_theme_stylebox_override("pressed", create_button_style(true))
	button.add_theme_stylebox_override("disabled", create_button_style(false, true))
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_HOVER_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_PRESSED_COLOR)
	button.add_theme_font_size_override("font_size", font_size)

	var font := get_font()
	if font != null:
		button.add_theme_font_override("font", font)


static func apply_title_label(label: Label, font_size: int = 30) -> void:
	label.add_theme_color_override("font_color", TITLE_COLOR)
	label.add_theme_font_size_override("font_size", font_size)
	var font := get_font()
	if font != null:
		label.add_theme_font_override("font", font)


static func apply_muted_label(label: Label, font_size: int = 17) -> void:
	label.add_theme_color_override("font_color", TEXT_MUTED_COLOR)
	label.add_theme_font_size_override("font_size", font_size)
	var font := get_font()
	if font != null:
		label.add_theme_font_override("font", font)


static func apply_body_label(label: Label, font_size: int = 18) -> void:
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", font_size)
	var font := get_font()
	if font != null:
		label.add_theme_font_override("font", font)


static func play_click() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root.has_node("UiAudio"):
		UiAudio.play_click()
