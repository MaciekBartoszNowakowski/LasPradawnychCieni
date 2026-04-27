# Abstract base class for enemies. Subclasses override stats in _init().
class_name Enemy
extends Player

func _init() -> void:
	character_name = "Enemy"
	color = Color(0.8, 0.2, 0.2)

# Moves toward the closest player character using A*.
func move(astar: AStarGrid2D, cells: Dictionary, player_characters: Array[Player]) -> void:
	var closest := _find_closest_player(player_characters)
	if closest == null:
		return

	var full_path: Array[Vector2i] = astar.get_id_path(grid_pos, closest.grid_pos)
	if full_path.size() <= 1:
		return

	full_path.pop_back()  # Don't step onto player's cell

	if full_path.size() <= 1:
		return  # Enemy is already adjacent to player

	full_path.pop_front()  # Remove start cell; remainder = movement steps

	if full_path.size() > move_points_left:
		full_path = full_path.slice(0, move_points_left)

	# Walk back from end to find an unoccupied destination
	while not full_path.is_empty() and cells[full_path[full_path.size() - 1]].occupant != null:
		full_path.pop_back()

	if full_path.is_empty():
		return

	var destination: Vector2i = full_path[full_path.size() - 1]
	cells[grid_pos].occupant = null
	cells[destination].occupant = self

	var path_with_start: Array[Vector2i] = [grid_pos]
	path_with_start.append_array(full_path)
	set_path(path_with_start)

func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -RADIUS),
		Vector2(RADIUS, RADIUS),
		Vector2(-RADIUS, RADIUS)
	])
	draw_colored_polygon(points, color)

func _find_closest_player(player_characters: Array[Player]) -> Player:
	var closest: Player = null
	var min_dist := INF
	for char: Player in player_characters:
		var d: float = float(grid_pos.distance_squared_to(char.grid_pos))
		if d < min_dist:
			min_dist = d
			closest = char
	return closest
