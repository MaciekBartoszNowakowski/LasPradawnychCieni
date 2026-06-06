extends Control

const BATTLE_SCENE_PATH := "res://scenes/battle/BattleMap.tscn"
const EPILOGUE_SCENE_PATH := "res://scenes/finale/Epilogue.tscn"
const NOTICE_FONT_PATH := "res://assets/ui/fonts/IMFellEnglishSC-Regular.ttf"

const TEXT_COLOR := Color(0.8666667, 0.827451, 0.7372549, 1.0)
const TEXT_HOVER_COLOR := Color(0.9411765, 0.90588236, 0.8156863, 1.0)
const TEXT_PRESSED_COLOR := Color(0.7607843, 0.6901961, 0.52156866, 1.0)
const TEXT_SECONDARY_COLOR := Color(0.78, 0.69, 0.58, 1.0)
const TEXT_MUTED_COLOR := Color(0.62, 0.55, 0.46, 1.0)
const OUTLINE_COLOR := Color(0.09411765, 0.078431375, 0.07058824, 1.0)

const PANEL_WIDTH := 600.0
const PANEL_HEIGHT := 680.0
const PANEL_SIDE_MARGIN := 96.0
const PANEL_TOP_MARGIN := 100.0

@onready var scene_background: TextureRect = $BackgroundLayer/Background
@onready var base_tint: ColorRect = $BackgroundLayer/BaseTint
@onready var dark_overlay: ColorRect = $BackgroundLayer/DarkOverlay
@onready var vignette: TextureRect = $BackgroundLayer/Vignette

@onready var finale_panel: Panel = $Root/CheckpointPanel
@onready var title_label: Label = $Root/CheckpointPanel/MarginContainer/VBox/TitleLabel
@onready var description_text: RichTextLabel = $Root/CheckpointPanel/MarginContainer/VBox/DescriptionText
@onready var choices_title_label: Label = $Root/CheckpointPanel/MarginContainer/VBox/ChoicesTitleLabel
@onready var choices_container: VBoxContainer = $Root/CheckpointPanel/MarginContainer/VBox/ChoicesContainer
@onready var result_box: VBoxContainer = $Root/CheckpointPanel/MarginContainer/VBox/ResultBox
@onready var result_title_label: Label = $Root/CheckpointPanel/MarginContainer/VBox/ResultBox/ResultTitleLabel
@onready var result_text: RichTextLabel = $Root/CheckpointPanel/MarginContainer/VBox/ResultBox/ResultText
@onready var continue_button: Button = $Root/CheckpointPanel/MarginContainer/VBox/ContinueButton

var _steps: Array = []
var _step_index: int = -1
var _awaiting_continue: bool = false
var _is_transitioning: bool = false
var _pending_choice: Dictionary = {}


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_setup_style()
	_layout_scene()
	_reset_visuals()
	continue_button.pressed.connect(_on_continue_pressed)
	_steps = FinaleNarrative.build_steps()
	if not _steps.is_empty():
		_apply_step_content(_steps[0] as Dictionary, true, false)
	call_deferred("_play_intro")


func _on_viewport_size_changed() -> void:
	_layout_scene()


func _layout_scene() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if finale_panel == null:
		return

	var viewport_size := get_viewport_rect().size
	var width: float = min(PANEL_WIDTH, max(560.0, viewport_size.x - 160.0))
	var height: float = min(PANEL_HEIGHT, max(560.0, viewport_size.y - PANEL_TOP_MARGIN - 80.0))

	finale_panel.custom_minimum_size = Vector2(width, height)
	finale_panel.offset_top = PANEL_TOP_MARGIN
	finale_panel.offset_bottom = PANEL_TOP_MARGIN + height
	finale_panel.offset_left = -PANEL_SIDE_MARGIN - width
	finale_panel.offset_right = -PANEL_SIDE_MARGIN


func _reset_visuals() -> void:
	_is_transitioning = false
	_awaiting_continue = false
	_pending_choice = {}

	scene_background.modulate.a = 0.0
	base_tint.modulate.a = 1.0
	dark_overlay.modulate.a = 0.0
	if vignette != null:
		vignette.modulate.a = 0.0
	finale_panel.modulate.a = 0.0

	title_label.text = ""
	description_text.text = ""
	choices_title_label.visible = false
	choices_container.visible = false
	result_box.visible = false
	continue_button.visible = false


func _play_intro() -> void:
	var first_bg_alpha := 1.0
	if scene_background.texture == null:
		first_bg_alpha = 0.0

	var intro_tween := create_tween()
	intro_tween.tween_property(scene_background, "modulate:a", first_bg_alpha, 0.75)
	intro_tween.parallel().tween_property(dark_overlay, "modulate:a", 1.0, 0.75)
	if vignette != null:
		intro_tween.parallel().tween_property(vignette, "modulate:a", 0.48, 0.75)

	await intro_tween.finished

	var panel_tween := create_tween()
	panel_tween.tween_property(finale_panel, "modulate:a", 1.0, 0.4)
	await panel_tween.finished

	_step_index = 0
	if not _steps.is_empty():
		_reveal_step_interaction(_steps[0] as Dictionary)


func _advance_step() -> void:
	_step_index += 1

	if _step_index >= _steps.size():
		push_error("Finale: brak kroków narracji.")
		return

	_render_step(_steps[_step_index] as Dictionary)


func _render_step(step: Dictionary) -> void:
	_apply_step_content(step, _step_index == 0, true)


func _apply_step_content(step: Dictionary, immediate_bg: bool, reveal_interaction: bool) -> void:
	_clear_choices()
	_hide_result()
	_pending_choice = {}
	_awaiting_continue = false
	continue_button.visible = false
	continue_button.disabled = true
	continue_button.modulate.a = 0.0
	choices_title_label.visible = false
	choices_container.visible = false

	title_label.text = str(step.get("title", ""))
	description_text.text = str(step.get("description", ""))

	var bg_path: String = str(step.get("background", ""))
	_set_background_from_path(bg_path, immediate_bg)
	_layout_scene()

	if reveal_interaction:
		_reveal_step_interaction(step)


func _reveal_step_interaction(step: Dictionary) -> void:
	var mode: String = str(step.get("mode", "continue"))
	if mode == "choices":
		choices_title_label.visible = true
		choices_title_label.modulate.a = 1.0
		choices_title_label.text = "Wybierz działanie"
		choices_container.visible = true
		choices_container.modulate.a = 1.0

		for raw_choice in step.get("choices", []) as Array:
			_add_finale_choice_button(raw_choice as Dictionary)
	else:
		continue_button.text = str(step.get("continue_text", "Dalej"))
		_show_continue_button()


func _add_finale_choice_button(choice: Dictionary) -> void:
	var button := Button.new()
	button.text = str(choice.get("text", ""))
	button.custom_minimum_size = Vector2(0.0, 56.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_finale_choice_pressed.bind(choice))
	_apply_button_style(button)
	choices_container.add_child(button)


func _on_finale_choice_pressed(choice: Dictionary) -> void:
	if _is_transitioning:
		return

	if has_node("/root/UiAudio"):
		UiAudio.play_click()

	_pending_choice = choice
	var resolution_id: StringName = choice.get("resolution_id", &"") as StringName
	MapState.set_finale_resolution(resolution_id)

	for child in choices_container.get_children():
		var button := child as Button
		if button != null:
			button.disabled = true

	await _show_choice_result(choice)


func _show_choice_result(choice: Dictionary) -> void:
	await _hide_choices_section()

	var result_bg_path: String = str(choice.get("result_background", ""))
	if not result_bg_path.is_empty():
		_set_background_from_path(result_bg_path, false)

	result_title_label.text = "Skutek decyzji"
	result_text.text = str(choice.get("result_text", ""))
	result_box.visible = true
	result_box.modulate.a = 0.0
	_layout_scene()

	var result_tween := create_tween()
	result_tween.tween_property(result_box, "modulate:a", 1.0, 0.35)
	await result_tween.finished

	var needs_battle: bool = bool(choice.get("needs_battle", false))
	continue_button.text = "Ruszaj do walki" if needs_battle else "Zobacz epilog"
	_show_continue_button()


func _hide_choices_section() -> void:
	if choices_container == null or choices_title_label == null:
		return

	var tween := create_tween()
	tween.tween_property(choices_title_label, "modulate:a", 0.0, 0.14)
	tween.parallel().tween_property(choices_container, "modulate:a", 0.0, 0.14)
	await tween.finished

	choices_title_label.visible = false
	choices_container.visible = false


func _hide_result() -> void:
	result_box.visible = false
	result_box.modulate.a = 0.0


func _show_continue_button() -> void:
	_awaiting_continue = true
	continue_button.visible = true
	continue_button.disabled = false

	var tween := create_tween()
	tween.tween_property(continue_button, "modulate:a", 1.0, 0.25)


func _on_continue_pressed() -> void:
	if not _awaiting_continue or _is_transitioning:
		return

	if has_node("/root/UiAudio"):
		UiAudio.play_click()

	if not _pending_choice.is_empty():
		_finish_after_choice()
		return

	_advance_step()


func _finish_after_choice() -> void:
	_is_transitioning = true
	_awaiting_continue = false
	continue_button.disabled = true

	var needs_battle: bool = bool(_pending_choice.get("needs_battle", false))
	if needs_battle:
		MapState.finale_battle_active = true
		_go_to_scene(BATTLE_SCENE_PATH)
	else:
		MapState.mark_run_completed()
		_go_to_scene(EPILOGUE_SCENE_PATH)


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()


func _set_background_from_path(path: String, immediate: bool) -> void:
	var texture: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		texture = load(path) as Texture2D

	if immediate:
		scene_background.texture = texture
		scene_background.modulate.a = 1.0 if texture != null else 0.0
		return

	# Zawsze przejdź przez fade przy czyszczeniu tekstury (np. krok lasu bez PNG).
	if scene_background.texture == texture and texture != null:
		return

	var fade_out := create_tween()
	fade_out.tween_property(scene_background, "modulate:a", 0.0, 0.22)
	await fade_out.finished

	scene_background.texture = texture

	var fade_in := create_tween()
	fade_in.tween_property(scene_background, "modulate:a", 1.0 if texture != null else 0.0, 0.38)
	await fade_in.finished


func _go_to_scene(scene_path: String) -> void:
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("change_scene"):
		transition.change_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)


func _setup_style() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	finale_panel.add_theme_stylebox_override("panel", _create_panel_style())

	_apply_label_style(title_label, 36, TEXT_COLOR, true)
	_apply_label_style(choices_title_label, 20, TEXT_MUTED_COLOR, false)
	_apply_label_style(result_title_label, 22, TEXT_COLOR, true)
	_apply_rich_text_style(description_text, 23)
	_apply_rich_text_style(result_text, 21)
	_apply_button_style(continue_button)
	base_tint.color = Color(0.012, 0.014, 0.018, 1.0)
	dark_overlay.color = Color(0.0156863, 0.0196078, 0.0235294, 0.48)


func _create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.42)
	style.border_color = Color(0.84705883, 0.8, 0.68235296, 0.32)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 14
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
	button.add_theme_stylebox_override("normal", _create_button_style())
	button.add_theme_stylebox_override("hover", _create_button_style(true))
	button.add_theme_stylebox_override("pressed", _create_button_style(true))
	button.add_theme_stylebox_override("disabled", _create_button_style(false, true))
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_HOVER_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_PRESSED_COLOR)
	button.add_theme_font_size_override("font_size", 24)

	var font := _get_notice_font()
	if font != null:
		button.add_theme_font_override("font", font)


func _apply_label_style(label: Label, font_size: int, color: Color, strong: bool) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2 if strong else 1)
	label.add_theme_font_size_override("font_size", font_size)

	var font := _get_notice_font()
	if font != null:
		label.add_theme_font_override("font", font)


func _apply_rich_text_style(rich_text: RichTextLabel, font_size: int) -> void:
	rich_text.add_theme_color_override("default_color", TEXT_SECONDARY_COLOR)
	rich_text.add_theme_font_size_override("normal_font_size", font_size)
	rich_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var font := _get_notice_font()
	if font != null:
		rich_text.add_theme_font_override("normal_font", font)


func _get_notice_font() -> Font:
	if ResourceLoader.exists(NOTICE_FONT_PATH):
		return load(NOTICE_FONT_PATH) as Font
	return null
