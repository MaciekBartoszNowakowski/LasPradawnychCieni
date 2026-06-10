extends Control

const MAP_SCENE_PATH := "res://scenes/map/Map.tscn"
const NOTICE_FONT_PATH := "res://assets/ui/fonts/IMFellEnglishSC-Regular.ttf"

const TEXT_COLOR := Color(0.8666667, 0.827451, 0.7372549, 1.0)
const TEXT_HOVER_COLOR := Color(0.9411765, 0.90588236, 0.8156863, 1.0)
const TEXT_PRESSED_COLOR := Color(0.7607843, 0.6901961, 0.52156866, 1.0)
const TEXT_DISABLED_COLOR := Color(0.5529412, 0.52156866, 0.46666667, 1.0)
const TEXT_SECONDARY_COLOR := Color(0.78, 0.69, 0.58, 1.0)
const TEXT_MUTED_COLOR := Color(0.62, 0.55, 0.46, 1.0)
const OUTLINE_COLOR := Color(0.09411765, 0.078431375, 0.07058824, 1.0)

const PANEL_WIDTH := 580.0
const PANEL_HEIGHT := 660.0
const PANEL_SIDE_MARGIN := 96.0
const PANEL_BOTTOM_MARGIN := 92.0
const PANEL_TOP_MARGIN := 110.0

@export var fallback_quest: SideQuestConfig = null
@export var fallback_background: Texture2D = null
@export var fallback_vignette: Texture2D = null
@export_range(0.0, 1.0, 0.01) var fallback_dark_overlay_alpha: float = 0.34
@export_range(0.0, 1.0, 0.01) var fallback_vignette_alpha: float = 0.45

@onready var background_layer: Control = $BackgroundLayer
@onready var background: TextureRect = $BackgroundLayer/Background
@onready var base_tint: ColorRect = $BackgroundLayer/BaseTint
@onready var dark_overlay: ColorRect = $BackgroundLayer/DarkOverlay
@onready var vignette: TextureRect = $BackgroundLayer/Vignette

@onready var root: Control = $Root
@onready var quest_panel: Panel = $Root/QuestPanel
@onready var title_label: Label = $Root/QuestPanel/MarginContainer/VBox/TitleLabel
@onready var divider: ColorRect = $Root/QuestPanel/MarginContainer/VBox/Divider
@onready var description_text: RichTextLabel = $Root/QuestPanel/MarginContainer/VBox/DescriptionText
@onready var choices_title_label: Label = $Root/QuestPanel/MarginContainer/VBox/ChoicesTitleLabel
@onready var choices_container: VBoxContainer = $Root/QuestPanel/MarginContainer/VBox/ChoicesContainer
@onready var result_box: VBoxContainer = $Root/QuestPanel/MarginContainer/VBox/ResultBox
@onready var result_title_label: Label = $Root/QuestPanel/MarginContainer/VBox/ResultBox/ResultTitleLabel
@onready var result_text: RichTextLabel = $Root/QuestPanel/MarginContainer/VBox/ResultBox/ResultText
@onready var effect_label: Label = $Root/QuestPanel/MarginContainer/VBox/ResultBox/EffectLabel
@onready var continue_button: Button = $Root/QuestPanel/MarginContainer/VBox/ContinueButton

var current_quest: SideQuestConfig = null
var selected_choice: SideQuestChoiceConfig = null
var _can_continue := false
var _is_finishing := false
var _current_background: Texture2D = null
var _target_vignette_alpha: float = 0.0


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	_setup_static_style()
	_layout_scene()
	_reset_visuals()

	continue_button.pressed.connect(_on_continue_button_pressed)

	current_quest = _get_current_quest()
	_render_quest()

	call_deferred("_play_intro")


func _on_viewport_size_changed() -> void:
	_layout_scene()


func _setup_static_style() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE

	quest_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	quest_panel.add_theme_stylebox_override("panel", _create_panel_style())

	_apply_label_style(title_label, 34, TEXT_COLOR, true)
	_apply_label_style(choices_title_label, 20, TEXT_MUTED_COLOR, false)
	_apply_label_style(result_title_label, 22, TEXT_COLOR, true)
	_apply_label_style(effect_label, 18, Color(0.82, 0.71, 0.50, 1.0), false)
	_apply_rich_text_style(description_text, 23)
	_apply_rich_text_style(result_text, 21)
	_apply_button_style(continue_button)

	divider.color = Color(0.84705883, 0.8, 0.68235296, 0.34)
	base_tint.color = Color(0.012, 0.014, 0.018, 1.0)


func _layout_scene() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	_layout_full_rect(background_layer)
	_layout_full_rect(root)

	if background != null:
		_layout_full_rect(background)
	if base_tint != null:
		_layout_full_rect(base_tint)
	if dark_overlay != null:
		_layout_full_rect(dark_overlay)
	if vignette != null:
		_layout_full_rect(vignette)

	_layout_quest_panel()


func _layout_full_rect(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _layout_quest_panel() -> void:
	if quest_panel == null:
		return

	var viewport_size := get_viewport_rect().size
	var width: float = min(PANEL_WIDTH, max(560.0, viewport_size.x - 160.0))
	var height: float = min(PANEL_HEIGHT, max(560.0, viewport_size.y - PANEL_TOP_MARGIN - PANEL_BOTTOM_MARGIN))
	var side := "right"

	if current_quest != null:
		side = current_quest.panel_side

	quest_panel.custom_minimum_size = Vector2(width, height)
	quest_panel.anchor_top = 0.0
	quest_panel.anchor_bottom = 0.0
	quest_panel.offset_top = PANEL_TOP_MARGIN
	quest_panel.offset_bottom = PANEL_TOP_MARGIN + height

	match side:
		"left":
			quest_panel.anchor_left = 0.0
			quest_panel.anchor_right = 0.0
			quest_panel.offset_left = PANEL_SIDE_MARGIN
			quest_panel.offset_right = PANEL_SIDE_MARGIN + width
		"center":
			quest_panel.anchor_left = 0.5
			quest_panel.anchor_right = 0.5
			quest_panel.offset_left = -width * 0.5
			quest_panel.offset_right = width * 0.5
		_:
			quest_panel.anchor_left = 1.0
			quest_panel.anchor_right = 1.0
			quest_panel.offset_left = -PANEL_SIDE_MARGIN - width
			quest_panel.offset_right = -PANEL_SIDE_MARGIN


func _reset_visuals() -> void:
	_can_continue = false
	_is_finishing = false

	background.modulate.a = 0.0
	base_tint.modulate.a = 1.0
	dark_overlay.modulate.a = 0.0
	vignette.modulate.a = 0.0
	quest_panel.modulate.a = 0.0

	continue_button.disabled = true
	continue_button.modulate.a = 0.0
	continue_button.visible = false

	result_box.visible = false
	result_box.modulate.a = 0.0


func _get_current_quest() -> SideQuestConfig:
	if has_node("/root/MapState") and MapState.has_method("get_selected_side_quest"):
		var quest := MapState.get_selected_side_quest()
		if quest != null:
			return quest

	return fallback_quest


func _render_quest() -> void:
	_clear_choices()
	selected_choice = null
	choices_title_label.visible = true
	choices_title_label.modulate.a = 1.0
	choices_container.visible = true
	choices_container.modulate.a = 1.0
	result_box.visible = false
	result_box.modulate.a = 0.0
	continue_button.visible = false
	continue_button.disabled = true
	continue_button.modulate.a = 0.0

	if current_quest == null:
		_render_missing_quest()
		return

	title_label.text = current_quest.title
	description_text.text = current_quest.description
	choices_title_label.text = "Wybierz działanie"
	continue_button.text = "Wróć na mapę"

	_apply_background(_get_initial_background(), true)
	_apply_overlay_alpha(current_quest.dark_overlay_alpha, true)
	_apply_vignette_alpha(current_quest.vignette_alpha, true)
	_layout_quest_panel()

	var choices := current_quest.get_choices()

	if choices.is_empty():
		choices_title_label.text = "Brak dostępnych decyzji"
		_add_return_button()
		return

	for choice in choices:
		_add_choice_button(choice)


func _render_missing_quest() -> void:
	title_label.text = "Nieznane wydarzenie"
	description_text.text = "Brak przypisanego side questa do tego punktu mapy."
	choices_title_label.text = ""
	_apply_background(fallback_background, true)
	_apply_overlay_alpha(fallback_dark_overlay_alpha, true)
	_apply_vignette_alpha(fallback_vignette_alpha, true)
	_add_return_button()


func _get_initial_background() -> Texture2D:
	if current_quest != null and current_quest.background != null:
		return current_quest.background

	return fallback_background


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()


func _add_choice_button(choice: SideQuestChoiceConfig) -> void:
	var button := Button.new()
	button.text = choice.text
	button.custom_minimum_size = Vector2(0.0, 56.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_choice_pressed.bind(choice))
	_apply_button_style(button)
	choices_container.add_child(button)


func _add_return_button() -> void:
	var button := Button.new()
	button.text = "Wróć na mapę"
	button.custom_minimum_size = Vector2(0.0, 56.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_continue_button_pressed)
	_apply_button_style(button)
	choices_container.add_child(button)


func _play_intro() -> void:
	var bg_alpha := 1.0 if _current_background != null else 0.0

	var intro_tween := create_tween()
	intro_tween.tween_property(background, "modulate:a", bg_alpha, 0.75)
	intro_tween.parallel().tween_property(dark_overlay, "modulate:a", 1.0, 0.75)
	intro_tween.parallel().tween_property(vignette, "modulate:a", _target_vignette_alpha, 0.75)
	await intro_tween.finished

	var panel_tween := create_tween()
	panel_tween.tween_property(quest_panel, "modulate:a", 1.0, 0.45)
	await panel_tween.finished


func _on_choice_pressed(choice: SideQuestChoiceConfig) -> void:
	if selected_choice != null or _is_finishing:
		return

	selected_choice = choice
	_play_click_sound()
	_disable_choice_buttons()
	_apply_choice_effects(choice)
	await _show_choice_result(choice)


func _disable_choice_buttons() -> void:
	for child in choices_container.get_children():
		var button := child as Button
		if button != null:
			button.disabled = true
			button.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _hide_choices_section() -> void:
	if choices_container == null or choices_title_label == null:
		return

	if not choices_container.visible and not choices_title_label.visible:
		return

	var tween := create_tween()
	tween.tween_property(choices_title_label, "modulate:a", 0.0, 0.14)
	tween.parallel().tween_property(choices_container, "modulate:a", 0.0, 0.14)
	await tween.finished

	choices_title_label.visible = false
	choices_container.visible = false
	_layout_quest_panel()
	await get_tree().process_frame


func _show_choice_result(choice: SideQuestChoiceConfig) -> void:
	# Po wyborze decyzji usuwamy z układu listę opcji.
	# Dzięki temu wynik decyzji nie jest dokładany pod istniejące przyciski
	# i panel nie próbuje powiększać się ponad ekran.
	await _hide_choices_section()

	if choice.result_background != null:
		await _apply_background(choice.result_background, false)

	if choice.result_dark_overlay_alpha >= 0.0:
		await _apply_overlay_alpha(choice.result_dark_overlay_alpha, false)

	var effect_summary := choice.get_effect_summary()

	result_title_label.text = "Skutek decyzji"
	result_text.text = choice.result_text

	if effect_summary.is_empty():
		effect_label.text = ""
		effect_label.visible = false
	else:
		effect_label.text = "Efekt: " + effect_summary
		effect_label.visible = true

	result_box.visible = true
	result_box.modulate.a = 0.0
	_layout_quest_panel()

	var result_tween := create_tween()
	result_tween.tween_property(result_box, "modulate:a", 1.0, 0.35)
	await result_tween.finished

	_can_continue = true
	continue_button.text = choice.continue_button_text
	continue_button.visible = true
	continue_button.disabled = false
	continue_button.modulate.a = 0.0

	var button_tween := create_tween()
	button_tween.tween_property(continue_button, "modulate:a", 1.0, 0.25)


func _apply_choice_effects(choice: SideQuestChoiceConfig) -> void:
	if has_node("/root/GameState") and GameState.has_method("apply_sidequest_choice"):
		GameState.apply_sidequest_choice(choice)
		return

	print("SideQuest effect fallback: gold=%d, health=%d" % [
		choice.gold_delta,
		choice.health_delta
	])


func _on_continue_button_pressed() -> void:
	if _is_finishing:
		return

	_is_finishing = true
	_can_continue = false
	_play_click_sound()

	if continue_button != null:
		continue_button.disabled = true

	if has_node("/root/MapState") and MapState.has_method("complete_selected_side_quest"):
		MapState.complete_selected_side_quest()
	if has_node("/root/MapState") and MapState.has_method("complete_selected_map_node"):
		MapState.complete_selected_map_node()

	var out_tween := create_tween()
	out_tween.tween_property(quest_panel, "modulate:a", 0.0, 0.35)
	out_tween.parallel().tween_property(background, "modulate:a", 0.0, 0.55)
	out_tween.parallel().tween_property(dark_overlay, "modulate:a", 0.0, 0.55)
	out_tween.parallel().tween_property(vignette, "modulate:a", 0.0, 0.55)
	await out_tween.finished

	var transition := get_node_or_null("/root/SceneTransition")

	if transition != null and transition.has_method("change_scene"):
		transition.change_scene(MAP_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(MAP_SCENE_PATH)


func _apply_background(texture: Texture2D, immediate: bool) -> void:
	if immediate:
		_current_background = texture
		background.texture = texture
		background.modulate.a = 0.0
		return

	var fade_out := create_tween()
	fade_out.tween_property(background, "modulate:a", 0.0, 0.20)
	await fade_out.finished

	_current_background = texture
	background.texture = texture

	if texture == null:
		background.modulate.a = 0.0
		return

	var fade_in := create_tween()
	fade_in.tween_property(background, "modulate:a", 1.0, 0.35)
	await fade_in.finished


func _apply_overlay_alpha(alpha: float, immediate: bool) -> void:
	dark_overlay.color = Color(0.0, 0.0, 0.0, clamp(alpha, 0.0, 1.0))

	if immediate:
		dark_overlay.modulate.a = 0.0
		return

	var tween := create_tween()
	tween.tween_property(dark_overlay, "modulate:a", 1.0, 0.25)
	await tween.finished


func _apply_vignette_alpha(alpha: float, immediate: bool) -> void:
	_target_vignette_alpha = clamp(alpha, 0.0, 1.0)
	vignette.texture = fallback_vignette if fallback_vignette != null else vignette.texture

	if immediate:
		vignette.modulate = Color(1.0, 1.0, 1.0, 0.0)
		return

	var tween := create_tween()
	tween.tween_property(vignette, "modulate:a", _target_vignette_alpha, 0.25)
	await tween.finished


func _create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_content_margin(SIDE_LEFT, 0.0)
	style.set_content_margin(SIDE_TOP, 0.0)
	style.set_content_margin(SIDE_RIGHT, 0.0)
	style.set_content_margin(SIDE_BOTTOM, 0.0)
	style.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.38)
	style.border_color = Color(0.84705883, 0.8, 0.68235296, 0.28)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 12
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
		style.border_color = Color(0.84705883, 0.8, 0.68235296, 0.15)

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
	button.add_theme_stylebox_override("normal", _create_button_style())
	button.add_theme_stylebox_override("hover", _create_button_style(true))
	button.add_theme_stylebox_override("pressed", _create_button_style(true))
	button.add_theme_stylebox_override("focus", _create_button_style())
	button.add_theme_stylebox_override("disabled", _create_button_style(false, true))

	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_HOVER_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_PRESSED_COLOR)
	button.add_theme_color_override("font_disabled_color", TEXT_DISABLED_COLOR)
	button.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_font_size_override("font_size", 24)

	var notice_font := _get_notice_font()
	if notice_font != null:
		button.add_theme_font_override("font", notice_font)


func _apply_label_style(label: Label, font_size: int, color: Color, stronger_outline: bool) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2 if stronger_outline else 1)
	label.add_theme_font_size_override("font_size", font_size)

	var notice_font := _get_notice_font()
	if notice_font != null:
		label.add_theme_font_override("font", notice_font)


func _apply_rich_text_style(rich_text: RichTextLabel, font_size: int) -> void:
	rich_text.add_theme_color_override("default_color", TEXT_SECONDARY_COLOR)
	rich_text.add_theme_font_size_override("normal_font_size", font_size)
	rich_text.add_theme_constant_override("line_separation", 5)
	rich_text.bbcode_enabled = false
	rich_text.scroll_active = false
	rich_text.fit_content = false
	rich_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var notice_font := _get_notice_font()
	if notice_font != null:
		rich_text.add_theme_font_override("normal_font", notice_font)


func _get_notice_font() -> Font:
	if ResourceLoader.exists(NOTICE_FONT_PATH):
		return load(NOTICE_FONT_PATH) as Font

	return null


func _play_click_sound() -> void:
	if has_node("/root/UiAudio"):
		UiAudio.play_click()
