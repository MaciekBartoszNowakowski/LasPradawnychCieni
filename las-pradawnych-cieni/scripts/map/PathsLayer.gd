extends Node2D
class_name PathsLayer

const CURVE_FACTOR: float = 0.16
const MIN_CONTROL_OFFSET: float = 20.0
const MAX_CONTROL_OFFSET: float = 64.0
const CURVE_SAMPLES: int = 28

const DASH_LENGTH: float = 14.0
const GAP_LENGTH: float = 10.0

const SHADOW_OFFSET: Vector2 = Vector2(0.0, 2.0)
const HIGHLIGHT_OFFSET: Vector2 = Vector2(0.0, -1.0)
const PATH_END_PADDING: float = 4.0

var map_nodes: Array[MapNode] = []
var node_by_id: Dictionary = {}


func setup(new_map_nodes: Array[MapNode], new_node_by_id: Dictionary) -> void:
	map_nodes = new_map_nodes
	node_by_id = new_node_by_id
	queue_redraw()


func _draw() -> void:
	for node in map_nodes:
		for target_id in node.connections:
			if not node_by_id.has(target_id):
				continue

			var target: MapNode = node_by_id[target_id] as MapNode

			# Gdyby połączenia były zapisane w obie strony.
			if node.id > target.id:
				continue

			_draw_connection(node, target)


func _draw_connection(from_node: MapNode, to_node: MapNode) -> void:
	var raw_points: PackedVector2Array = _build_curve_points(from_node.position, to_node.position)

	var start_trim: float = _get_node_visual_radius(from_node) + PATH_END_PADDING
	var end_trim: float = _get_node_visual_radius(to_node) + PATH_END_PADDING
	var points: PackedVector2Array = _trim_polyline_ends(raw_points, start_trim, end_trim)

	if points.size() < 2:
		return

	var palette: Dictionary = _get_connection_palette(from_node, to_node)

	# 1. delikatny cień
	_draw_dashed_polyline(
		points,
		palette.shadow,
		6.0,
		DASH_LENGTH,
		GAP_LENGTH,
		SHADOW_OFFSET
	)

	# 2. ciemna baza
	_draw_dashed_polyline(
		points,
		palette.outline,
		4.8,
		DASH_LENGTH,
		GAP_LENGTH
	)

	# 3. główna linia
	_draw_dashed_polyline(
		points,
		palette.main,
		2.8,
		DASH_LENGTH,
		GAP_LENGTH
	)

	# 4. bardzo subtelny highlight
	_draw_dashed_polyline(
		points,
		palette.highlight,
		1.0,
		DASH_LENGTH,
		GAP_LENGTH,
		HIGHLIGHT_OFFSET
	)


func _build_curve_points(start: Vector2, end: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()

	var delta: Vector2 = end - start
	var dx: float = abs(delta.x)

	if dx <= 0.001:
		points.append(start)
		points.append(end)
		return points

	var control_offset: float = clamp(dx * CURVE_FACTOR, MIN_CONTROL_OFFSET, MAX_CONTROL_OFFSET)

	var p0: Vector2 = start
	var p1: Vector2 = start + Vector2(control_offset, 0.0)
	var p2: Vector2 = end - Vector2(control_offset, 0.0)
	var p3: Vector2 = end

	for i in range(CURVE_SAMPLES + 1):
		var t: float = float(i) / float(CURVE_SAMPLES)
		points.append(_cubic_bezier(p0, p1, p2, p3, t))

	return points


func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return \
		(u * u * u) * p0 + \
		(3.0 * u * u * t) * p1 + \
		(3.0 * u * t * t) * p2 + \
		(t * t * t) * p3


func _draw_dashed_polyline(
	points: PackedVector2Array,
	color: Color,
	width: float,
	dash_length: float,
	gap_length: float,
	offset: Vector2 = Vector2.ZERO
) -> void:
	var cycle: float = dash_length + gap_length
	var traveled: float = 0.0

	for i in range(points.size() - 1):
		var a: Vector2 = points[i] + offset
		var b: Vector2 = points[i + 1] + offset
		var segment: Vector2 = b - a
		var segment_length: float = segment.length()

		if segment_length <= 0.001:
			continue

		var dir: Vector2 = segment / segment_length
		var local_pos: float = 0.0

		while local_pos < segment_length:
			var phase: float = fposmod(traveled + local_pos, cycle)

			if phase < dash_length:
				var dash_start: float = local_pos
				var dash_end: float = min(local_pos + (dash_length - phase), segment_length)

				var p0: Vector2 = a + dir * dash_start
				var p1: Vector2 = a + dir * dash_end
				draw_line(p0, p1, color, width)

				local_pos = dash_end
			else:
				local_pos += min(cycle - phase, segment_length - local_pos)

		traveled += segment_length


func _trim_polyline_ends(points: PackedVector2Array, start_trim: float, end_trim: float) -> PackedVector2Array:
	if points.size() < 2:
		return points

	var trimmed: PackedVector2Array = _trim_polyline_from_start(points, start_trim)
	trimmed = _reverse_points(_trim_polyline_from_start(_reverse_points(trimmed), end_trim))

	if trimmed.size() < 2:
		return points

	return trimmed


func _trim_polyline_from_start(points: PackedVector2Array, trim_amount: float) -> PackedVector2Array:
	if points.size() < 2 or trim_amount <= 0.0:
		return points

	var remaining: float = trim_amount

	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var seg: Vector2 = b - a
		var seg_length: float = seg.length()

		if seg_length <= 0.001:
			continue

		if remaining >= seg_length:
			remaining -= seg_length
			continue

		var dir: Vector2 = seg / seg_length
		var new_start: Vector2 = a + dir * remaining

		var result: PackedVector2Array = PackedVector2Array()
		result.append(new_start)

		for j in range(i + 1, points.size()):
			result.append(points[j])

		return result

	return points


func _reverse_points(points: PackedVector2Array) -> PackedVector2Array:
	var reversed_points: PackedVector2Array = PackedVector2Array()

	for i in range(points.size() - 1, -1, -1):
		reversed_points.append(points[i])

	return reversed_points


func _get_node_visual_radius(node: MapNode) -> float:
	match node.type:
		MapEnums.NodeType.BOSS:
			return 33.0

		MapEnums.NodeType.ELITE:
			return 29.0

		MapEnums.NodeType.CHECKPOINT:
			return 28.0

		_:
			return 26.0


func _get_connection_palette(from_node: MapNode, to_node: MapNode) -> Dictionary:
	var shadow: Color = Color(0.0, 0.0, 0.0, 0.14)
	var outline: Color = Color(0.17, 0.13, 0.10, 0.82)
	var main: Color = Color(0.31, 0.26, 0.21, 0.88)
	var highlight: Color = Color(0.58, 0.50, 0.40, 0.16)

	if from_node.visited and to_node.visited:
		shadow = Color(0.0, 0.02, 0.01, 0.14)
		outline = Color(0.08, 0.18, 0.10, 0.86)
		main = Color(0.24, 0.48, 0.29, 0.92)
		highlight = Color(0.66, 0.82, 0.69, 0.18)

	elif (from_node.visited and to_node.available) or (to_node.visited and from_node.available):
		shadow = Color(0.02, 0.01, 0.00, 0.14)
		outline = Color(0.29, 0.23, 0.15, 0.88)
		main = Color(0.63, 0.55, 0.37, 0.94)
		highlight = Color(0.88, 0.80, 0.58, 0.20)

	elif from_node.available or to_node.available:
		shadow = Color(0.01, 0.01, 0.00, 0.14)
		outline = Color(0.24, 0.20, 0.15, 0.84)
		main = Color(0.46, 0.40, 0.31, 0.90)
		highlight = Color(0.69, 0.62, 0.49, 0.18)

	return {
		"shadow": shadow,
		"outline": outline,
		"main": main,
		"highlight": highlight,
	}
