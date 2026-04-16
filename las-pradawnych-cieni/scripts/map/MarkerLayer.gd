extends Node2D
class_name MarkerLayer

const MARKER_OFFSET_Y: float = -42.0
const STAFF_HEIGHT: float = 18.0
const FLAG_WIDTH: float = 15.0
const FLAG_HEIGHT: float = 10.0
const RING_RADIUS: float = 31.0

var node_by_id: Dictionary = {}
var selected_node_id: int = -1


func setup(new_node_by_id: Dictionary, new_selected_node_id: int) -> void:
	node_by_id = new_node_by_id
	selected_node_id = new_selected_node_id
	queue_redraw()


func _draw() -> void:
	if selected_node_id == -1:
		return

	if not node_by_id.has(selected_node_id):
		return

	var node: MapNode = node_by_id[selected_node_id] as MapNode
	if node == null:
		return

	var node_pos: Vector2 = node.position
	var marker_top: Vector2 = node_pos + Vector2(0.0, MARKER_OFFSET_Y)
	var marker_bottom: Vector2 = marker_top + Vector2(0.0, STAFF_HEIGHT)

	_draw_current_ring(node_pos)
	_draw_staff(marker_top, marker_bottom)
	_draw_flag(marker_top)


func _draw_current_ring(center: Vector2) -> void:
	draw_arc(
		center,
		RING_RADIUS,
		0.0,
		TAU,
		48,
		Color(0.96, 0.88, 0.66, 0.20),
		2.0
	)

	draw_arc(
		center,
		RING_RADIUS - 4.0,
		0.0,
		TAU,
		48,
		Color(0.22, 0.18, 0.11, 0.55),
		1.0
	)


func _draw_staff(top: Vector2, bottom: Vector2) -> void:
	draw_line(
		top + Vector2(1.0, 1.0),
		bottom + Vector2(1.0, 1.0),
		Color(0.0, 0.0, 0.0, 0.30),
		3.0
	)


	draw_line(
		top,
		bottom,
		Color(0.84, 0.74, 0.52, 0.95),
		2.0
	)

	draw_circle(top, 2.4, Color(0.92, 0.84, 0.62, 1.0))
	draw_circle(top, 1.2, Color(0.20, 0.15, 0.09, 1.0))


func _draw_flag(staff_top: Vector2) -> void:
	var anchor: Vector2 = staff_top + Vector2(1.0, 2.0)

	var shadow_points: PackedVector2Array = PackedVector2Array([
		anchor + Vector2(1.0, 1.0),
		anchor + Vector2(FLAG_WIDTH + 1.0, 2.0),
		anchor + Vector2(FLAG_WIDTH * 0.65 + 1.0, FLAG_HEIGHT * 0.55 + 1.0),
		anchor + Vector2(1.0, FLAG_HEIGHT + 1.0),
	])

	var flag_points: PackedVector2Array = PackedVector2Array([
		anchor,
		anchor + Vector2(FLAG_WIDTH, 1.0),
		anchor + Vector2(FLAG_WIDTH * 0.62, FLAG_HEIGHT * 0.55),
		anchor + Vector2(0.0, FLAG_HEIGHT),
	])

	draw_colored_polygon(shadow_points, Color(0.0, 0.0, 0.0, 0.22))
	draw_colored_polygon(flag_points, Color(0.86, 0.80, 0.62, 0.95))

	for i in range(flag_points.size()):
		var a: Vector2 = flag_points[i]
		var b: Vector2 = flag_points[(i + 1) % flag_points.size()]
		draw_line(a, b, Color(0.25, 0.19, 0.11, 0.95), 1.0)

	var emblem_center: Vector2 = anchor + Vector2(FLAG_WIDTH * 0.42, FLAG_HEIGHT * 0.45)
	draw_circle(emblem_center, 1.4, Color(0.28, 0.20, 0.11, 0.90))
	draw_circle(emblem_center, 0.6, Color(0.92, 0.84, 0.62, 0.90))
