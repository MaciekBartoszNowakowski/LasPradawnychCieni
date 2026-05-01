extends Node2D

const GRID_WIDTH := 30
const GRID_HEIGHT := 20
const CELL_SIZE := 64

const COLOR_GROUND := Color(0.25, 0.65, 0.25)
const COLOR_OBSTACLE := Color(0.45, 0.45, 0.45)
const COLOR_GRID := Color.BLACK

var cells: Dictionary = {}
var astar: AStarGrid2D = AStarGrid2D.new()

var player_characters: Array[Player] = []
var enemies: Array[Enemy] = []
var combatants: Array[Player] = []
var current_turn_index: int = 0
var last_player_character: Player = null
var _enemy_acting: bool = false

var _initiative_container: VBoxContainer
var _name_label: Label
var _life_label: Label
var _stats_label: Label
var _end_turn_button: Button
var _end_battle_button: Button

func _ready() -> void:
	create_grid()
	add_test_blocks()
	setup_astar()
	spawn_characters()
	spawn_test_enemies()
	build_combatants()
	_setup_ui()
	_update_initiative_display()
	_update_stats_panel()
	start_first_turn()
	queue_redraw()

func _process(_delta: float) -> void:
	if _enemy_acting:
		var current: Player = combatants[current_turn_index]
		if not current.is_moving():
			_enemy_acting = false
			_advance_turn()

func create_grid() -> void:
	cells.clear()
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var coord := Vector2i(x, y)
			var cell := CellData.new()
			cell.walkable = true
			cell.movement_cost = 1
			cell.terrain_type = &"ground"
			cells[coord] = cell

func add_block(block: Block, coord: Vector2i) -> void:
	if not cells.has(coord):
		return
	var cell: CellData = cells[coord]
	cell.walkable = false
	cell.terrain_type = block.block_type
	block.position = grid_to_world(coord)
	add_child(block)

func add_test_blocks() -> void:
	for coord: Vector2i in [Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4), Vector2i(10, 8), Vector2i(10, 9), Vector2i(20, 5), Vector2i(20, 6), Vector2i(25, 10), Vector2i(15, 15)]:
		add_block(StoneBlock.new(), coord)
	for coord: Vector2i in [Vector2i(8, 1), Vector2i(9, 1), Vector2i(12, 6), Vector2i(12, 7), Vector2i(18, 12), Vector2i(22, 3), Vector2i(27, 14)]:
		add_block(TreeLogBlock.new(), coord)
	for coord: Vector2i in [Vector2i(15, 4), Vector2i(15, 5), Vector2i(15, 6), Vector2i(15, 7), Vector2i(15, 8), Vector2i(7, 14), Vector2i(7, 15), Vector2i(7, 16)]:
		add_block(RiverBlock.new(), coord)

func setup_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, GRID_WIDTH, GRID_HEIGHT)
	astar.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for coord: Vector2i in cells.keys():
		var cell: CellData = cells[coord]
		if not cell.walkable:
			astar.set_point_solid(coord, true)

func spawn_characters() -> void:
	var start_cells := [Vector2i(1, 1), Vector2i(1, 3), Vector2i(1, 5)]
	player_characters = GameState.player_team.characters
	for i in range(mini(player_characters.size(), start_cells.size())):
		spawn_character(player_characters[i], start_cells[i])

func spawn_test_enemies() -> void:
	var wolves: Array[Enemy] = [Wolf.new(), Wolf.new()]
	var start_cells := [Vector2i(14, 7), Vector2i(16, 9)]
	for i in range(wolves.size()):
		spawn_character(wolves[i], start_cells[i])
		enemies.append(wolves[i])

func spawn_character(character: Player, start_cell: Vector2i) -> void:
	character.cell_size = CELL_SIZE
	character.grid_pos = start_cell
	if character.get_parent() != null:
		character.reparent(self)
	else:
		add_child(character)
	character.global_position = grid_to_world(start_cell)
	character.reset_turn()
	cells[start_cell].occupant = character

func build_combatants() -> void:
	combatants.clear()
	for c: Player in player_characters:
		combatants.append(c)
	for e: Enemy in enemies:
		combatants.append(e)
	combatants.sort_custom(func(a: Player, b: Player) -> bool:
		return a.initiative > b.initiative)

func start_first_turn() -> void:
	for c: Player in combatants:
		if not (c is Enemy):
			last_player_character = c
			break
	var first: Player = combatants[0]
	first.reset_turn()
	if first is Enemy:
		_enemy_acting = true
		_end_turn_button.disabled = true
		(first as Enemy).move(astar, cells, player_characters)
	else:
		last_player_character = first
		_end_turn_button.disabled = false
		_update_stats_panel()

func _advance_turn() -> void:
	current_turn_index = (current_turn_index + 1) % combatants.size()
	var current: Player = combatants[current_turn_index]
	current.reset_turn()
	_update_initiative_display()
	if current is Enemy:
		_enemy_acting = true
		_end_turn_button.disabled = true
		(current as Enemy).move(astar, cells, player_characters)
	else:
		last_player_character = current
		_end_turn_button.disabled = false
		_update_stats_panel()

func _setup_ui() -> void:
	var canvas: CanvasLayer = $CanvasLayer

	# Initiative panel (right side, above bottom panel)
	var init_panel := PanelContainer.new()
	init_panel.anchor_left = 1.0
	init_panel.anchor_top = 0.0
	init_panel.anchor_right = 1.0
	init_panel.anchor_bottom = 1.0
	init_panel.offset_left = -185.0
	init_panel.offset_right = 0.0
	init_panel.offset_top = 0.0
	init_panel.offset_bottom = -130.0
	canvas.add_child(init_panel)

	var init_scroll := ScrollContainer.new()
	init_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	init_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	init_panel.add_child(init_scroll)

	_initiative_container = VBoxContainer.new()
	_initiative_container.custom_minimum_size = Vector2(175, 0)
	init_scroll.add_child(_initiative_container)

	# Bottom panel (full width, 130px tall)
	var bottom_panel := PanelContainer.new()
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 0.0
	bottom_panel.offset_right = 0.0
	bottom_panel.offset_top = -130.0
	bottom_panel.offset_bottom = 0.0
	canvas.add_child(bottom_panel)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_panel.add_child(hbox)

	# Stats section
	var stats_vbox := VBoxContainer.new()
	stats_vbox.custom_minimum_size = Vector2(300, 0)
	stats_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(stats_vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	stats_vbox.add_child(_name_label)

	_life_label = Label.new()
	stats_vbox.add_child(_life_label)

	_stats_label = Label.new()
	stats_vbox.add_child(_stats_label)

	# Actions placeholder (expands to fill remaining horizontal space)
	var actions_panel := PanelContainer.new()
	actions_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var actions_label := Label.new()
	actions_label.text = "[Actions]"
	actions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	actions_panel.add_child(actions_label)
	hbox.add_child(actions_panel)

	# Buttons section
	var btn_vbox := VBoxContainer.new()
	btn_vbox.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(btn_vbox)

	_end_turn_button = Button.new()
	_end_turn_button.text = "End Turn"
	_end_turn_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	btn_vbox.add_child(_end_turn_button)

	_end_battle_button = Button.new()
	_end_battle_button.text = "End Battle"
	_end_battle_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_end_battle_button.pressed.connect(_on_end_battle_button_pressed)
	btn_vbox.add_child(_end_battle_button)

func _update_initiative_display() -> void:
	for child in _initiative_container.get_children():
		child.queue_free()

	var preview_count: int = combatants.size() * 6 + 1
	for i in range(preview_count):
		var idx: int = (current_turn_index + i) % combatants.size()
		var c: Player = combatants[idx]
		var label := Label.new()

		if i == 0:
			label.text = "▶ " + c.character_name
			label.add_theme_font_size_override("font_size", 18)
			label.modulate = Color.GOLD
		else:
			label.text = "  " + c.character_name
			label.add_theme_font_size_override("font_size", 13)
			if c is Enemy:
				label.modulate = Color(1.0, 0.55, 0.55)
			else:
				label.modulate = Color(0.65, 0.85, 1.0)

		_initiative_container.add_child(label)

func _update_stats_panel() -> void:
	if last_player_character == null:
		return
	var c := last_player_character
	_name_label.text = c.character_name
	_life_label.text = "HP: %d / %d" % [c.current_life, c.max_life]
	_stats_label.text = "SPD: %d  INI: %d  AGI: %d  STR: %d  ARM: %d" % [
		c.speed, c.initiative, c.agility, c.strength, c.armour
	]

func _unhandled_input(event: InputEvent) -> void:
	if combatants.is_empty():
		return
	var current: Player = combatants[current_turn_index]
	if current is Enemy:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current.is_moving():
			return
		if current.move_points_left <= 0:
			return

		var clicked_cell: Vector2i = world_to_grid(get_global_mouse_position())
		if not is_in_bounds(clicked_cell):
			return

		var target_cell: CellData = cells[clicked_cell]
		if not target_cell.walkable:
			return
		if target_cell.occupant != null:
			return

		var start: Vector2i = current.grid_pos
		var path: Array[Vector2i] = astar.get_id_path(start, clicked_cell)
		if path.is_empty():
			return

		cells[current.grid_pos].occupant = null
		target_cell.occupant = current
		current.set_path(path)

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_WIDTH and cell.y >= 0 and cell.y < GRID_HEIGHT

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)

func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))

func _draw() -> void:
	draw_cells()
	draw_grid_lines()

func draw_cells() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var coord := Vector2i(x, y)
			var rect := Rect2(Vector2(x * CELL_SIZE, y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
			var cell: CellData = cells[coord]
			var color := COLOR_GROUND
			if not cell.walkable:
				color = COLOR_OBSTACLE
			draw_rect(rect, color, true)

func draw_grid_lines() -> void:
	var total_width := GRID_WIDTH * CELL_SIZE
	var total_height := GRID_HEIGHT * CELL_SIZE
	for x in range(GRID_WIDTH + 1):
		var px := x * CELL_SIZE
		draw_line(Vector2(px, 0), Vector2(px, total_height), COLOR_GRID, 2.0)
	for y in range(GRID_HEIGHT + 1):
		var py := y * CELL_SIZE
		draw_line(Vector2(0, py), Vector2(total_width, py), COLOR_GRID, 2.0)

func _on_end_turn_button_pressed() -> void:
	var current: Player = combatants[current_turn_index]
	if current is Enemy or current.is_moving():
		return
	_advance_turn()

func _on_end_battle_button_pressed() -> void:
	for char: Player in player_characters:
		if char.is_moving():
			return
	for char: Player in player_characters:
		char.reparent(GameState)
	get_tree().change_scene_to_file("res://scenes/map/Map.tscn")
