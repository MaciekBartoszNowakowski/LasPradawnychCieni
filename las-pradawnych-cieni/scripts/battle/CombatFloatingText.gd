class_name CombatFloatingText

const FONT_SIZE := 24
const OUTLINE_SIZE := 4
const RISE_DISTANCE := 48.0
const DURATION := 0.9
const POP_SCALE := 1.15

static func show_at(parent: Control, screen_pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	parent.add_child(label)
	label.reset_size()
	label.pivot_offset = label.size * 0.5
	label.position = screen_pos - label.pivot_offset

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - RISE_DISTANCE, DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "scale", Vector2(POP_SCALE, POP_SCALE), DURATION * 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_callback(label.queue_free)
