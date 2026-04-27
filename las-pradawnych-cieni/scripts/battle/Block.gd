class_name Block
extends Node2D

var block_type: StringName = &"block"
var color: Color = Color.GRAY
const HALF := 26.0

func _draw() -> void:
	draw_rect(Rect2(-HALF, -HALF, HALF * 2, HALF * 2), color, true)
