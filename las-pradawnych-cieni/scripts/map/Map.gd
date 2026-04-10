extends Node2D

const NODE_RADIUS: float = 22.0
const CHECKPOINT_RADIUS_BONUS: float = 6.0
const BOSS_RADIUS_BONUS: float = 10.0

const SCROLL_STEP: float = 120.0
const CAMERA_MARGIN: float = 120.0
const BACKGROUND_PADDING: float = 90.0

@onready var camera: Camera2D = $Camera2D

var map_nodes: Array[MapNode] = []
var node_by_id: Dictionary = {}
var hovered_node_id: int = -1

var map_config: MapGenerationConfig = null


func _ready() -> void:
	MapState.ensure_map_exists()
	map_nodes = MapState.map_nodes
	map_config = MapState.get_runtime_map_config()

	node_by_id.clear()
	for node in map_nodes:
		node_by_id[node.id] = node

	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_smoothed = true

	_setup_camera_limits()
	_setup_initial_camera_position()
	_update_hover()
	queue_redraw()


func _draw() -> void:
	_draw_map_background()
	_draw_connections()
	_draw_nodes()


func _draw_map_background() -> void:
	if map_nodes.is_empty():
		return

	var rect: Rect2 = _get_map_bounds().grow(BACKGROUND_PADDING)

	draw_rect(rect, Color(0.08, 0.09, 0.11, 1.0), true)
	draw_rect(rect, Color(0.18, 0.19, 0.22, 1.0), false, 4.0)

	if map_config != null:
		var layer_count: int = _get_layer_count()

		for layer_index in range(layer_count):
			var x: float = map_config.start_x + float(layer_index) * map_config.segment_spacing
			draw_line(
				Vector2(x, rect.position.y),
				Vector2(x, rect.position.y + rect.size.y),
				Color(1, 1, 1, 0.04),
				2.0
			)


func _draw_connections() -> void:
	for node in map_nodes:
		for target_id in node.connections:
			if not node_by_id.has(target_id):
				continue

			var target: MapNode = node_by_id[target_id] as MapNode
			var color: Color = Color(0.35, 0.35, 0.38, 1.0)

			if node.visited and target.visited:
				color = Color(0.25, 0.70, 0.35, 1.0)
			elif node.visited and target.available:
				color = Color(0.85, 0.85, 0.85, 1.0)
			elif node.available:
				color = Color(0.65, 0.65, 0.68, 1.0)

			draw_line(node.position, target.position, color, 3.0)


func _draw_nodes() -> void:
	for node in map_nodes:
		var radius: float = _get_node_radius(node)
		var fill_color: Color = _get_node_fill_color(node)
		var outline_color: Color = Color.BLACK

		if node.visited:
			outline_color = Color(0.05, 0.22, 0.09, 1.0)
		elif node.id == hovered_node_id and node.available:
			outline_color = Color(1.0, 0.90, 0.2, 1.0)
		elif node.available:
			outline_color = Color(0.95, 0.95, 0.95, 1.0)

		draw_circle(node.position, radius, fill_color)
		draw_arc(node.position, radius, 0.0, TAU, 32, outline_color, 2.0)

		if node.available and not node.visited:
			draw_arc(node.position, radius + 4.0, 0.0, TAU, 32, Color(1, 1, 1, 0.20), 2.0)

		if node.id == hovered_node_id and node.available:
			draw_arc(node.position, radius + 7.0, 0.0, TAU, 32, Color(1.0, 0.90, 0.2, 0.45), 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_move_camera_x(-SCROLL_STEP)
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_move_camera_x(SCROLL_STEP)
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_select_node()
			return

	if event is InputEventMouseMotion:
		_update_hover()


func _move_camera_x(delta_x: float) -> void:
	camera.position.x += delta_x
	camera.position.x = clamp(camera.position.x, float(camera.limit_left), float(camera.limit_right))
	_update_hover()
	queue_redraw()


func _update_hover() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var previous_hovered: int = hovered_node_id
	var hovered_node: MapNode = _get_node_at_position(mouse_pos)

	if hovered_node == null:
		hovered_node_id = -1
	else:
		hovered_node_id = hovered_node.id

	if previous_hovered != hovered_node_id:
		queue_redraw()


func _get_node_at_position(mouse_pos: Vector2) -> MapNode:
	for node in map_nodes:
		var radius: float = _get_node_radius(node)
		if mouse_pos.distance_to(node.position) <= radius:
			return node

	return null


func _try_select_node() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var node: MapNode = _get_node_at_position(mouse_pos)

	if node == null:
		return

	if node.available:
		_select_node(node)


func _select_node(node: MapNode) -> void:
	for other_node in map_nodes:
		other_node.available = false

	node.visited = true

	for next_id in node.connections:
		if node_by_id.has(next_id):
			var next_node: MapNode = node_by_id[next_id] as MapNode
			next_node.available = true

	MapState.selected_node_id = node.id

	var room_type: int = node.type
	if room_type == MapEnums.NodeType.CHECKPOINT:
		room_type = MapEnums.NodeType.EVENT

	MapState.selected_node_type = room_type
	get_tree().change_scene_to_file("res://scenes/RoomMock.tscn")


func _get_node_radius(node: MapNode) -> float:
	var radius: float = NODE_RADIUS

	if node.type == MapEnums.NodeType.CHECKPOINT:
		radius += CHECKPOINT_RADIUS_BONUS
	elif node.type == MapEnums.NodeType.BOSS:
		radius += BOSS_RADIUS_BONUS

	return radius


func _get_node_fill_color(node: MapNode) -> Color:
	if node.visited:
		return Color(0.22, 0.85, 0.35, 1.0)

	var color: Color = _get_base_color_for_type(node.type)

	if not node.available:
		color = color.darkened(0.55)
	elif node.id == hovered_node_id:
		color = color.lightened(0.20)

	return color


func _get_base_color_for_type(node_type: int) -> Color:
	match node_type:
		MapEnums.NodeType.BATTLE:
			return Color(0.82, 0.82, 0.82, 1.0)
		MapEnums.NodeType.EVENT:
			return Color(0.66, 0.50, 0.96, 1.0)
		MapEnums.NodeType.SHOP:
			return Color(0.95, 0.78, 0.28, 1.0)
		MapEnums.NodeType.REST:
			return Color(0.33, 0.82, 0.48, 1.0)
		MapEnums.NodeType.ELITE:
			return Color(0.88, 0.36, 0.29, 1.0)
		MapEnums.NodeType.CHECKPOINT:
			return Color(0.25, 0.68, 0.95, 1.0)
		MapEnums.NodeType.BOSS:
			return Color(0.78, 0.13, 0.13, 1.0)
		_:
			return Color(0.60, 0.60, 0.60, 1.0)


func _setup_camera_limits() -> void:
	if map_nodes.is_empty():
		return

	var rect: Rect2 = _get_map_bounds().grow(CAMERA_MARGIN)

	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.position.x + rect.size.x)
	camera.limit_bottom = int(rect.position.y + rect.size.y)


func _setup_initial_camera_position() -> void:
	if map_nodes.is_empty():
		return

	if MapState.selected_node_id == -1:
		_move_camera_to_left_start()
	else:
		_center_camera_on_selected_node()


func _move_camera_to_left_start() -> void:
	var rect: Rect2 = _get_map_bounds()

	camera.position = Vector2(
		float(camera.limit_left),
		rect.position.y + rect.size.y * 0.5
	)


func _center_camera_on_selected_node() -> void:
	if not node_by_id.has(MapState.selected_node_id):
		_move_camera_to_left_start()
		return

	var selected_node: MapNode = node_by_id[MapState.selected_node_id] as MapNode
	var rect: Rect2 = _get_map_bounds()

	camera.position = Vector2(
		clamp(selected_node.position.x, float(camera.limit_left), float(camera.limit_right)),
		rect.position.y + rect.size.y * 0.5
	)


func _get_map_bounds() -> Rect2:
	if map_nodes.is_empty():
		return Rect2()

	var min_x: float = map_nodes[0].position.x
	var max_x: float = map_nodes[0].position.x
	var min_y: float = map_nodes[0].position.y
	var max_y: float = map_nodes[0].position.y

	for node in map_nodes:
		min_x = min(min_x, node.position.x)
		max_x = max(max_x, node.position.x)
		min_y = min(min_y, node.position.y)
		max_y = max(max_y, node.position.y)

	return Rect2(
		Vector2(min_x, min_y),
		Vector2(max_x - min_x, max_y - min_y)
	)


func _get_layer_count() -> int:
	if map_nodes.is_empty():
		return 0

	var max_layer_index: int = 0

	for node in map_nodes:
		max_layer_index = max(max_layer_index, node.layer_index)

	return max_layer_index + 1
