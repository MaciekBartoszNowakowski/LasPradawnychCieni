extends Node2D
class_name Player

const MOVE_SPEED := 220.0
const RADIUS := 18.0

var grid_pos: Vector2i = Vector2i.ZERO
var cell_size: int = 64

var character_name: String = "Unknown"
var initiative: int = 0
var speed: int = 6
var agility: int = 0
var strength: int = 0
var armour: int = 0
var max_life: int = 10
var current_life: int = 10

var color: Color = Color.DODGER_BLUE

var move_points_max: int = 6
var move_points_left: int = 6

var _path: Array[Vector2i] = []
var _moving: bool = false
var _target_world: Vector2 = Vector2.ZERO

func _ready() -> void:
	move_points_max = speed
	move_points_left = speed
	queue_redraw()

func _process(delta: float) -> void:
	if not _moving:
		return

	global_position = global_position.move_toward(_target_world, MOVE_SPEED * delta)

	if global_position.distance_to(_target_world) < 1.0:
		global_position = _target_world
		grid_pos = world_to_grid(global_position)

		move_points_left -= 1
		if move_points_left < 0:
			move_points_left = 0

		queue_redraw()

		if _path.is_empty() or move_points_left <= 0:
			_moving = false
		else:
			var next_cell: Vector2i = _path.pop_front()
			_target_world = grid_to_world(next_cell)

func set_path(path: Array[Vector2i]) -> void:
	if move_points_left <= 0:
		return

	_path = path.duplicate()

	if not _path.is_empty() and _path[0] == grid_pos:
		_path.pop_front()

	if _path.is_empty():
		_moving = false
		return

	if _path.size() > move_points_left:
		_path = _path.slice(0, move_points_left)

	if _path.is_empty():
		_moving = false
		return

	var next_cell: Vector2i = _path.pop_front()
	_target_world = grid_to_world(next_cell)
	_moving = true

func reset_turn() -> void:
	move_points_left = move_points_max
	queue_redraw()

func is_moving() -> bool:
	return _moving

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * cell_size + cell_size * 0.5,
		cell.y * cell_size + cell_size * 0.5
	)

func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(pos.x / cell_size),
		floori(pos.y / cell_size)
	)

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, color)
