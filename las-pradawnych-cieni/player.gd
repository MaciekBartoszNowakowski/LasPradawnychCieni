extends Node2D
class_name Player

const MOVE_SPEED := 220.0
const RADIUS := 18.0
const HP_BACK_COLOR := Color(0.04, 0.025, 0.018, 0.82)
const HP_ALLY_COLOR := Color(0.36, 0.76, 0.42, 0.94)
const HP_ENEMY_COLOR := Color(0.78, 0.30, 0.25, 0.94)

var grid_pos: Vector2i = Vector2i.ZERO
var cell_size: int = 64
var grid_offset: Vector2 = Vector2.ZERO

var character_name: String = "Unknown"
var initiative: int = 0
var speed: int = 6
var agility: int = 0
var strength: int = 0
var armour: int = 0
var max_life: int = 10
var current_life: int = 10

var color: Color = Color.DODGER_BLUE
var portrait_path: String = ""
var _portrait_cache: Texture2D = null

var actions: Array[BattleAction] = []
var has_acted: bool = false

var defending: bool = false
var stealthed: bool = false
var halve_stats_rounds: int = 0

var move_points_max: int = 6
var move_points_left: int = 6
var movement_speed_multiplier: float = 1.0
var equipped_item_ids: Array[String] = []

var _path: Array[Vector2i] = []
var _moving: bool = false
var _target_world: Vector2 = Vector2.ZERO
var _target_grid: Vector2i = Vector2i.ZERO
var _hit_flash_time: float = 0.0

func _ready() -> void:
	move_points_max = speed
	move_points_left = speed
	queue_redraw()

func _process(delta: float) -> void:
	if _hit_flash_time > 0.0:
		_hit_flash_time = maxf(0.0, _hit_flash_time - delta)
		queue_redraw()

	if not _moving:
		return

	global_position = global_position.move_toward(_target_world, MOVE_SPEED * movement_speed_multiplier * delta)

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
			_target_grid = next_cell
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
	_target_grid = next_cell
	_target_world = grid_to_world(next_cell)
	_moving = true

func reset_turn() -> void:
	move_points_left = move_points_max
	has_acted = false
	queue_redraw()

func is_moving() -> bool:
	return _moving


func get_remaining_path() -> Array[Vector2i]:
	if _moving:
		var moving_result: Array[Vector2i] = [_target_grid]
		moving_result.append_array(_path)
		return moving_result

	var result: Array[Vector2i] = [grid_pos]
	result.append_array(_path)
	return result


func get_remaining_path_world_points() -> Array[Vector2]:
	var result: Array[Vector2] = []

	if not _moving:
		for coord in get_remaining_path():
			result.append(grid_to_world(coord))
		return result

	result.append(global_position)
	result.append(_target_world)
	for coord in _path:
		result.append(grid_to_world(coord))
	return result

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * cell_size + cell_size * 0.5,
		cell.y * cell_size + cell_size * 0.5
	) + grid_offset

func world_to_grid(pos: Vector2) -> Vector2i:
	var adjusted := pos - grid_offset
	return Vector2i(
		floori(adjusted.x / cell_size),
		floori(adjusted.y / cell_size)
	)

func _draw() -> void:
	var portrait := get_portrait()
	if portrait != null:
		_draw_portrait_token(portrait)
	else:
		draw_circle(Vector2.ZERO, RADIUS, color)

	if _hit_flash_time > 0.0:
		var flash_alpha := clampf(_hit_flash_time / 0.18, 0.0, 1.0)
		draw_circle(Vector2.ZERO, RADIUS + 7.0, Color(1.0, 0.9, 0.55, 0.42 * flash_alpha))

	_draw_health_bar()

func _draw_portrait_token(portrait: Texture2D) -> void:
	var half := (RADIUS + 8.0) * 1.3
	draw_texture_rect(portrait, Rect2(Vector2(-half, -half), Vector2(half * 2, half * 2)), false)


func _draw_health_bar(fill_color: Color = HP_ALLY_COLOR, width: float = 44.0) -> void:
	if max_life <= 0 or current_life <= 0:
		return

	var ratio := clampf(float(current_life) / float(max_life), 0.0, 1.0)
	var height := 6.0
	var center := Vector2(0.0, RADIUS + 12.0)
	var rect := Rect2(center - Vector2(width * 0.5, height * 0.5), Vector2(width, height))
	var fill_rect := Rect2(rect.position, Vector2(width * ratio, height))

	draw_rect(rect.grow(2.0), Color(0.0, 0.0, 0.0, 0.34), true)
	draw_rect(rect, HP_BACK_COLOR, true)
	draw_rect(fill_rect, fill_color, true)
	draw_rect(rect, Color(0.94, 0.84, 0.62, 0.40), false, 1.0)


func apply_life_delta(amount: int) -> int:
	if amount == 0:
		return 0

	var previous_life: int = current_life

	current_life = clampi(
		current_life + amount,
		0,
		max_life
	)

	queue_redraw()

	return current_life - previous_life


func heal(amount: int) -> int:
	if amount <= 0:
		return 0

	return apply_life_delta(amount)


func damage(amount: int) -> int:
	if amount <= 0:
		return 0

	return apply_life_delta(-amount)


func flash_hit() -> void:
	_hit_flash_time = 0.18
	queue_redraw()


func heal_missing_percent(percent: float) -> int:
	var missing_life: int = max_life - current_life

	if missing_life <= 0:
		return 0

	var heal_amount: int = max(1, int(ceil(float(missing_life) * percent)))
	return heal(heal_amount)


func get_portrait() -> Texture2D:
	if _portrait_cache == null and portrait_path != "":
		_portrait_cache = load(portrait_path)
	return _portrait_cache


func add_equipment_item(item_id: String) -> void:
	if item_id.is_empty():
		return

	equipped_item_ids.append(item_id)
