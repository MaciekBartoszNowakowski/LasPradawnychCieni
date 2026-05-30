extends Node2D

const GRID_WIDTH := 30
const GRID_HEIGHT := 20
const CELL_SIZE := 64

const COLOR_GROUND := Color(0.25, 0.65, 0.25)
const COLOR_OBSTACLE := Color(0.45, 0.45, 0.45)
const COLOR_GRID := Color.BLACK
const COLOR_RANGE := Color(1.0, 0.0, 0.0, 0.25)

var cells: Dictionary = {}
var astar: AStarGrid2D = AStarGrid2D.new()

var player_characters: Array[Player] = []
var enemies: Array[Enemy] = []
var combatants: Array[Player] = []
var current_turn_index: int = 0
var last_player_character: Player = null
var _enemy_acting: bool = false

var _targeting_mode: bool = false
var _pending_action: BattleAction = null

var _initiative_container: VBoxContainer
var _actions_container: HBoxContainer
var _name_label: Label
var _life_label: Label
var _stats_label: Label
var _end_turn_button: Button
var _end_battle_button: Button

var _battle_log: Array[String] = []
var _log_panel: PanelContainer
var _log_scroll: ScrollContainer
var _log_container: VBoxContainer
var _log_visible: bool = false

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
			if not current.has_acted and current is Enemy:
				var attack_result := (current as Enemy).attack(player_characters)
				if not attack_result.is_empty():
					_log_attack(attack_result)
					_update_initiative_display()
				for pc: Player in player_characters.duplicate():
					_check_death_and_remove(pc)
				if combatants.is_empty():
					return
			_enemy_acting = false
			if not combatants.is_empty():
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
		(first as Enemy).move(astar, cells, player_characters, combatants)
	else:
		last_player_character = first
		_end_turn_button.disabled = false
		_update_stats_panel()
		_refresh_action_buttons()

func _advance_turn() -> void:
	current_turn_index = (current_turn_index + 1) % combatants.size()
	var current: Player = combatants[current_turn_index]
	current.reset_turn()
	_update_initiative_display()
	if current is Enemy:
		_enemy_acting = true
		_end_turn_button.disabled = true
		_refresh_action_buttons()
		(current as Enemy).move(astar, cells, player_characters, combatants)
	else:
		last_player_character = current
		_end_turn_button.disabled = false
		_update_stats_panel()
		_refresh_action_buttons()

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

	# Actions panel
	var actions_panel := PanelContainer.new()
	actions_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(actions_panel)

	_actions_container = HBoxContainer.new()
	_actions_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_actions_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_actions_container.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_panel.add_child(_actions_container)

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

	var log_button := Button.new()
	log_button.text = "Log"
	log_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_button.pressed.connect(_toggle_log)
	btn_vbox.add_child(log_button)

	# Log panel — hidden by default, anchored to left side above bottom panel
	_log_panel = PanelContainer.new()
	_log_panel.anchor_left = 0.0
	_log_panel.anchor_top = 0.0
	_log_panel.anchor_right = 0.0
	_log_panel.anchor_bottom = 1.0
	_log_panel.offset_left = 0.0
	_log_panel.offset_right = 300.0
	_log_panel.offset_top = 0.0
	_log_panel.offset_bottom = -130.0
	_log_panel.visible = false
	canvas.add_child(_log_panel)

	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_panel.add_child(_log_scroll)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_container)

func _refresh_action_buttons() -> void:
	for child in _actions_container.get_children():
		child.queue_free()
	if combatants.is_empty():
		return
	var current: Player = combatants[current_turn_index]
	if current is Enemy:
		return
	for action: BattleAction in current.actions:
		var btn := Button.new()
		btn.text = action.action_name
		btn.disabled = current.has_acted
		btn.custom_minimum_size = Vector2(120, 0)
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_action_button_pressed.bind(action))
		_actions_container.add_child(btn)

func _toggle_log() -> void:
	_log_visible = not _log_visible
	_log_panel.visible = _log_visible

func _log_attack(info: Dictionary) -> void:
	var msg: String
	if info["hit"]:
		msg = "%s used %s on %s — rolled %d (dodge %d%%) → HIT for %d dmg" % [
			info["attacker"], info["action"], info["target"],
			info["roll"], info["miss_chance"], info["damage"]
		]
	else:
		msg = "%s used %s on %s — rolled %d (dodge %d%%) → MISS" % [
			info["attacker"], info["action"], info["target"],
			info["roll"], info["miss_chance"]
		]
	_battle_log.append(msg)
	var label := Label.new()
	label.text = msg
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	_log_container.add_child(label)
	# Scroll to bottom on next frame so layout is computed first
	_log_scroll.call_deferred("set", "scroll_vertical", 999999)

func _on_action_button_pressed(action: BattleAction) -> void:
	if combatants.is_empty():
		return
	var current: Player = combatants[current_turn_index]
	if current is Enemy or current.has_acted or current.is_moving():
		return
	if _targeting_mode and _pending_action == action:
		_targeting_mode = false
		_pending_action = null
		queue_redraw()
		return
	_pending_action = action
	_targeting_mode = true
	queue_redraw()

func _update_initiative_display() -> void:
	for child in _initiative_container.get_children():
		child.queue_free()
	if combatants.is_empty():
		return
	var preview_count: int = combatants.size() * 6 + 1
	for i in range(preview_count):
		var idx: int = (current_turn_index + i) % combatants.size()
		var c: Player = combatants[idx]
		var label := Label.new()
		var hp_str := " %d/%d" % [c.current_life, c.max_life]

		if i == 0:
			label.text = "▶ " + c.character_name + hp_str
			label.add_theme_font_size_override("font_size", 18)
			label.modulate = Color.GOLD
		else:
			label.text = "  " + c.character_name + hp_str
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

		var clicked_cell: Vector2i = world_to_grid(get_global_mouse_position())

		if _targeting_mode:
			_targeting_mode = false
			queue_redraw()
			if not is_in_bounds(clicked_cell):
				_pending_action = null
				return
			var cell: CellData = cells[clicked_cell]
			if cell.occupant == null or not (cell.occupant is Enemy):
				_pending_action = null
				return
			var target := cell.occupant as Player
			if target.current_life <= 0:
				_pending_action = null
				return
			var dist: int = abs(current.grid_pos.x - target.grid_pos.x) \
						  + abs(current.grid_pos.y - target.grid_pos.y)
			if dist > _pending_action.range:
				_pending_action = null
				return
			current.has_acted = true
			var result := BattleAction.resolve(_pending_action, target)
			if result["hit"]:
				target.current_life = maxi(target.current_life - result["damage"], 0)
			var log_info := {
				"attacker": current.character_name,
				"action": _pending_action.action_name,
				"target": target.character_name,
				"hit": result["hit"],
				"roll": result["roll"],
				"miss_chance": result["miss_chance"],
				"damage": result["damage"],
			}
			_log_attack(log_info)
			_pending_action = null
			_refresh_action_buttons()
			_update_stats_panel()
			_update_initiative_display()
			_check_death_and_remove(target)
			return

		# Movement
		if current.move_points_left <= 0:
			return

		if not is_in_bounds(clicked_cell):
			return

		var target_cell: CellData = cells[clicked_cell]
		if not target_cell.walkable:
			return
		if target_cell.occupant != null:
			return

		var start: Vector2i = current.grid_pos
		var blocked_coords: Array[Vector2i] = []
		for combatant: Player in combatants:
			if combatant != current:
				astar.set_point_solid(combatant.grid_pos, true)
				blocked_coords.append(combatant.grid_pos)
		var path: Array[Vector2i] = astar.get_id_path(start, clicked_cell)
		for coord: Vector2i in blocked_coords:
			astar.set_point_solid(coord, false)
		if path.is_empty():
			return

		cells[current.grid_pos].occupant = null
		target_cell.occupant = current
		current.set_path(path)

func _check_death_and_remove(character: Player) -> void:
	if character.current_life <= 0:
		_remove_combatant(character)

func _remove_combatant(character: Player) -> void:
	var idx := combatants.find(character)
	if idx == -1:
		return
	cells[character.grid_pos].occupant = null
	combatants.remove_at(idx)
	player_characters.erase(character)
	enemies.erase(character)
	if idx < current_turn_index:
		current_turn_index -= 1
	elif idx == current_turn_index and not combatants.is_empty():
		current_turn_index = current_turn_index % combatants.size()
	character.queue_free()
	_update_initiative_display()
	if enemies.is_empty() or player_characters.is_empty():
		_end_battle()

func _end_battle() -> void:
	_targeting_mode = false
	_pending_action = null
	for char: Player in player_characters:
		if is_instance_valid(char) and char.get_parent() != null:
			char.reparent(GameState)
	get_tree().change_scene_to_file("res://scenes/map/Map.tscn")

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_WIDTH and cell.y >= 0 and cell.y < GRID_HEIGHT

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)

func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))

func _draw() -> void:
	draw_cells()
	draw_grid_lines()
	_draw_action_range()

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

func _draw_action_range() -> void:
	if not _targeting_mode or _pending_action == null or combatants.is_empty():
		return
	var current: Player = combatants[current_turn_index]
	var r: int = _pending_action.range
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if abs(dx) + abs(dy) > r:
				continue
			var coord := current.grid_pos + Vector2i(dx, dy)
			if not is_in_bounds(coord):
				continue
			var rect := Rect2(
				Vector2(coord.x * CELL_SIZE, coord.y * CELL_SIZE),
				Vector2(CELL_SIZE, CELL_SIZE)
			)
			draw_rect(rect, COLOR_RANGE, true)

func _on_end_turn_button_pressed() -> void:
	var current: Player = combatants[current_turn_index]
	if current is Enemy or current.is_moving():
		return
	_targeting_mode = false
	_pending_action = null
	queue_redraw()
	_advance_turn()

func _on_end_battle_button_pressed() -> void:
	for char: Player in player_characters:
		if char.is_moving():
			return
	for char: Player in player_characters:
		char.reparent(GameState)
	get_tree().change_scene_to_file("res://scenes/map/Map.tscn")
