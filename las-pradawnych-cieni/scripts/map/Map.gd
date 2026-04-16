extends Node2D
class_name Map

const NODE_RADIUS: float = 22.0
const CHECKPOINT_RADIUS_BONUS: float = 6.0
const BOSS_RADIUS_BONUS: float = 10.0

const SCROLL_STEP: float = 120.0
const MAP_PADDING: float = 140.0
const SCROLL_SMOOTHNESS: float = 12.0
const SCROLL_SNAP_EPSILON: float = 0.5

const BOTTOM_BAR_HEIGHT: float = 96.0

@onready var map_world: Node2D = $MapWorld
@onready var backdrop_layer: BackdropLayer = $MapWorld/BackdropLayer
@onready var paths_layer: PathsLayer = $MapWorld/PathsLayer
@onready var nodes_layer: NodesLayer = $MapWorld/NodesLayer
@onready var marker_layer: MarkerLayer = $MapWorld/MarkerLayer

@onready var top_bar: Control = $UILayer/UIRoot/TopBar
@onready var bottom_bar = $UILayer/UIRoot/BottomBar
@onready var top_bar_shadow: CanvasItem = get_node_or_null("UILayer/UIRoot/TopBarShadow")

@onready var audio_ambient: AudioStreamPlayer2D = $AudioAmbient
@onready var audio_ui: AudioStreamPlayer2D = $AudioUI

var map_nodes: Array[MapNode] = []
var node_by_id: Dictionary = {}
var hovered_node_id: int = -1

var map_config: MapGenerationConfig = null
var node_bounds: Rect2 = Rect2()
var map_rect: Rect2 = Rect2()

var scroll_x: float = 0.0
var target_scroll_x: float = 0.0
var base_world_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	if top_bar_shadow != null:
		top_bar_shadow.visible = false

	_reset_world_transforms()

	_load_map_data()
	_build_node_index()

	_layout_bottom_bar()

	node_bounds = _get_node_bounds()
	map_rect = _get_map_rect()

	_push_data_to_layers()
	_recompute_world_offset()
	_setup_initial_view()
	_apply_world_offset()
	_update_hover()
	_update_bottom_bar()
	
	if audio_ambient != null and not audio_ambient.playing:
		audio_ambient.play()
	
	set_process(true)


func _process(delta: float) -> void:
	if absf(target_scroll_x - scroll_x) <= SCROLL_SNAP_EPSILON:
		if scroll_x != target_scroll_x:
			scroll_x = target_scroll_x
			_apply_world_offset()
			_update_hover()
		return

	var weight: float = clamp(delta * SCROLL_SMOOTHNESS, 0.0, 1.0)
	scroll_x = lerpf(scroll_x, target_scroll_x, weight)

	_apply_world_offset()
	_update_hover()


func _on_viewport_size_changed() -> void:
	_layout_bottom_bar()
	map_rect = _get_map_rect()

	backdrop_layer.setup(map_rect, map_config, _get_layer_count())

	var max_scroll: float = _get_max_scroll_x()

	scroll_x = clamp(scroll_x, 0.0, max_scroll)
	target_scroll_x = clamp(target_scroll_x, 0.0, max_scroll)

	_recompute_world_offset()
	_apply_world_offset()
	_update_hover()
	_update_bottom_bar()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_move_view_x(-SCROLL_STEP)
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_move_view_x(SCROLL_STEP)
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_select_node()
			return


func _reset_world_transforms() -> void:
	map_world.position = Vector2.ZERO
	map_world.scale = Vector2.ONE
	map_world.rotation = 0.0

	var layers: Array[Node2D] = [
		backdrop_layer,
		paths_layer,
		nodes_layer,
		marker_layer
	]

	for layer in layers:
		layer.position = Vector2.ZERO
		layer.scale = Vector2.ONE
		layer.rotation = 0.0


func _load_map_data() -> void:
	MapState.ensure_map_exists()
	map_nodes = MapState.map_nodes
	map_config = MapState.get_runtime_map_config()


func _build_node_index() -> void:
	node_by_id.clear()

	for node in map_nodes:
		node_by_id[node.id] = node


func _push_data_to_layers() -> void:
	var layer_count: int = _get_layer_count()

	backdrop_layer.setup(map_rect, map_config, layer_count)
	paths_layer.setup(map_nodes, node_by_id)
	nodes_layer.setup(map_nodes, hovered_node_id)
	marker_layer.setup(node_by_id, MapState.selected_node_id)


func _refresh_visual_layers() -> void:
	paths_layer.setup(map_nodes, node_by_id)
	nodes_layer.setup(map_nodes, hovered_node_id)
	marker_layer.setup(node_by_id, MapState.selected_node_id)


func _recompute_world_offset() -> void:
	base_world_offset = Vector2(
		-map_rect.position.x,
		round(_get_map_top_y() - map_rect.position.y)
	)


func _get_map_top_y() -> float:
	var rect: Rect2 = top_bar.get_global_rect()
	return rect.position.y + rect.size.y


func _get_map_bottom_y() -> float:
	return max(_get_map_top_y() + 1.0, get_viewport_rect().size.y - BOTTOM_BAR_HEIGHT)


func _layout_bottom_bar() -> void:
	if bottom_bar == null:
		return

	bottom_bar.anchor_left = 0.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_bottom = 1.0

	bottom_bar.offset_left = 0.0
	bottom_bar.offset_top = -BOTTOM_BAR_HEIGHT
	bottom_bar.offset_right = 0.0
	bottom_bar.offset_bottom = 0.0


func _setup_initial_view() -> void:
	if map_nodes.is_empty():
		scroll_x = 0.0
		target_scroll_x = 0.0
		return

	if MapState.selected_node_id == -1:
		_move_view_to_left_start()
	else:
		_center_view_on_selected_node()


func _move_view_to_left_start() -> void:
	scroll_x = 0.0
	target_scroll_x = 0.0


func _center_view_on_selected_node() -> void:
	if not node_by_id.has(MapState.selected_node_id):
		_move_view_to_left_start()
		return

	var selected_node: MapNode = node_by_id[MapState.selected_node_id] as MapNode
	var viewport_width: float = get_viewport_rect().size.x
	var selected_x_inside_map: float = selected_node.position.x - map_rect.position.x

	var centered_scroll: float = clamp(
		selected_x_inside_map - viewport_width * 0.5,
		0.0,
		_get_max_scroll_x()
	)

	scroll_x = centered_scroll
	target_scroll_x = centered_scroll


func _move_view_x(delta_x: float) -> void:
	target_scroll_x = clamp(
		target_scroll_x + delta_x,
		0.0,
		_get_max_scroll_x()
	)


func _apply_world_offset() -> void:
	map_world.position = Vector2(base_world_offset.x - scroll_x, base_world_offset.y)


func _update_hover() -> void:
	var mouse_screen_pos: Vector2 = get_viewport().get_mouse_position()
	var map_top_y: float = _get_map_top_y()
	var map_bottom_y: float = _get_map_bottom_y()

	if mouse_screen_pos.y < map_top_y or mouse_screen_pos.y > map_bottom_y:
		if hovered_node_id != -1:
			hovered_node_id = -1
			nodes_layer.set_hovered_node(hovered_node_id)

		_update_bottom_bar()
		return

	var mouse_world_pos: Vector2 = mouse_screen_pos - map_world.position
	var previous_hovered: int = hovered_node_id
	var hovered_node: MapNode = _get_node_at_position(mouse_world_pos)

	if hovered_node == null:
		hovered_node_id = -1
	else:
		hovered_node_id = hovered_node.id

	if previous_hovered != hovered_node_id:
		nodes_layer.set_hovered_node(hovered_node_id)

	_update_bottom_bar()


func _update_bottom_bar() -> void:
	if bottom_bar == null:
		return

	if hovered_node_id != -1 and node_by_id.has(hovered_node_id):
		bottom_bar.show_for_hovered_node(node_by_id[hovered_node_id] as MapNode)
		return

	if MapState.selected_node_id != -1 and node_by_id.has(MapState.selected_node_id):
		bottom_bar.show_for_selected_node(node_by_id[MapState.selected_node_id] as MapNode)
		return

	bottom_bar.show_default()


func _get_node_at_position(mouse_pos: Vector2) -> MapNode:
	var best_node: MapNode = null
	var best_distance_sq: float = INF

	for node in map_nodes:
		if not node.available:
			continue

		var radius: float = _get_node_radius(node)
		var radius_sq: float = radius * radius
		var dist_sq: float = mouse_pos.distance_squared_to(node.position)

		if dist_sq <= radius_sq and dist_sq < best_distance_sq:
			best_distance_sq = dist_sq
			best_node = node

	return best_node


func _try_select_node() -> void:
	var mouse_screen_pos: Vector2 = get_viewport().get_mouse_position()

	if mouse_screen_pos.y < _get_map_top_y() or mouse_screen_pos.y > _get_map_bottom_y():
		return

	if hovered_node_id == -1:
		return

	if not node_by_id.has(hovered_node_id):
		return

	var node: MapNode = node_by_id[hovered_node_id] as MapNode
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

	_refresh_visual_layers()
	_update_bottom_bar()
	
	_play_ui_click()
	await get_tree().create_timer(0.08).timeout
	
	get_tree().change_scene_to_file("res://scenes/RoomMock.tscn")


func _get_max_scroll_x() -> float:
	var viewport_width: float = get_viewport_rect().size.x
	return max(0.0, map_rect.size.x - viewport_width)


func _get_node_radius(node: MapNode) -> float:
	var radius: float = NODE_RADIUS

	if node.type == MapEnums.NodeType.CHECKPOINT:
		radius += CHECKPOINT_RADIUS_BONUS
	elif node.type == MapEnums.NodeType.BOSS:
		radius += BOSS_RADIUS_BONUS

	return radius


func _get_node_bounds() -> Rect2:
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


func _get_map_rect() -> Rect2:
	var available_height: float = max(1.0, _get_map_bottom_y() - _get_map_top_y())

	return Rect2(
		Vector2(node_bounds.position.x - MAP_PADDING, node_bounds.position.y - MAP_PADDING),
		Vector2(node_bounds.size.x + MAP_PADDING * 2.0, available_height)
	)


func _get_layer_count() -> int:
	if map_nodes.is_empty():
		return 0

	var max_layer_index: int = 0

	for node in map_nodes:
		max_layer_index = max(max_layer_index, node.layer_index)

	return max_layer_index + 1
	
func _play_ui_click() -> void:
	if audio_ui == null:
		return

	if audio_ui.playing:
		audio_ui.stop()

	audio_ui.play()
