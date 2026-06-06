class_name BattleMap
extends Node2D

const GRID_WIDTH := 20
const GRID_HEIGHT := 9
const CELL_SIZE := 64

const COLOR_GROUND := Color(0.25, 0.65, 0.25)
const COLOR_OBSTACLE := Color(0.45, 0.45, 0.45)
const COLOR_GRID := Color.BLACK
const COLOR_RANGE := Color(1.0, 0.0, 0.0, 0.25)

const OBSTACLE_COLORS: Dictionary = {
	"stone": Color(0.5, 0.5, 0.55),
	"tree_log": Color(0.4, 0.25, 0.1),
	"river": Color(0.2, 0.45, 0.9)
}

const TOP_BAR_HEIGHT: float = 64.0
const BOTTOM_BAR_HEIGHT: float = 80.0

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
var _background_texture: Texture2D = null
var _obstacle_textures: Dictionary = {}
var _cell_textures: Dictionary = {}

var _initiative_container: HBoxContainer
var _actions_container: HBoxContainer
var _name_label: Label
var _stats_label: Label
var _end_turn_button: Button
var _end_battle_button: Button

var _battle_log: Array[String] = []
var _log_panel: PanelContainer
var _log_scroll: ScrollContainer
var _log_container: VBoxContainer
var _log_visible: bool = false
var _floating_text_root: Control

func _ready() -> void:
	_configure_presentation()
	create_grid()
	_load_map_layout()
	setup_astar()
	_setup_battle()
	build_combatants()
	_setup_ui()
	_update_initiative_display()
	_update_stats_panel()
	start_first_turn()
	queue_redraw()


func _configure_presentation() -> void:
	pass


func _setup_battle() -> void:
	spawn_characters()
	_spawn_enemies_for_current_act()


func _should_show_end_battle_button() -> bool:
	return true


func _get_victory_scene_path() -> String:
	return "res://scenes/map/Map.tscn"


func _on_all_enemies_defeated() -> void:
	_reparent_players_to_game_state()
	_go_to_scene(_get_victory_scene_path())


func _on_party_wiped() -> void:
	_reparent_players_to_game_state()
	_go_to_scene("res://scenes/map/Map.tscn")

func _process(_delta: float) -> void:
	if _enemy_acting:
		var current: Player = combatants[current_turn_index]
		if not current.is_moving():
			if not current.has_acted and current is Enemy:
				var attack_result := (current as Enemy).attack(player_characters)
				if not attack_result.is_empty():
					if attack_result["hit"]:
						var intended: Player = attack_result["target_ref"]
						var actual: Player = _find_defender_for(intended)
						actual.current_life = maxi(actual.current_life - attack_result["damage"], 0)
						if actual != intended:
							attack_result["target"] = actual.character_name + " (defended for " + intended.character_name + ")"
						attack_result["target_ref"] = actual
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

func _load_map_layout() -> void:
	var layout := BattleMapLayouts.get_random_layout()

	_background_texture = load("res://assets/ui/map/battle_maps/base_map.png")

	var obs_tex_paths: Dictionary = layout.get("obstacle_textures", {})
	for terrain: String in obs_tex_paths:
		var path: String = obs_tex_paths[terrain]
		if path != "":
			_obstacle_textures[terrain] = load(path)

	var cell_tex_paths: Dictionary = layout.get("cell_textures", {})
	for coord: Vector2i in cell_tex_paths:
		var path: String = cell_tex_paths[coord]
		if path != "":
			_cell_textures[coord] = load(path)

	for coord: Vector2i in layout["stones"]:
		var b := StoneBlock.new()
		b.visible = false
		add_block(b, coord)
	for coord: Vector2i in layout["trees"]:
		var b := TreeLogBlock.new()
		b.visible = false
		add_block(b, coord)
	for coord: Vector2i in layout["rivers"]:
		var b := RiverBlock.new()
		b.visible = false
		add_block(b, coord)

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

func _spawn_enemies_for_current_act() -> void:
	var act: int = MapState.selected_node_act
	var set_enemies: Array[Enemy] = EnemyEncounterSets.get_random_set_for_act(act)
	var positions: Array[Vector2i] = [
		Vector2i(12, 1), Vector2i(15, 5), Vector2i(17, 7),
		Vector2i(13, 2), Vector2i(16, 6), Vector2i(18, 2), Vector2i(14, 6)
	]
	for i in range(set_enemies.size()):
		spawn_enemy(set_enemies[i], positions[i])


func spawn_enemy(enemy: Enemy, start_cell: Vector2i) -> void:
	spawn_character(enemy, start_cell)
	enemies.append(enemy)


func spawn_character(character: Player, start_cell: Vector2i) -> void:
	character.cell_size = CELL_SIZE
	character.grid_offset = Vector2(0.0, TOP_BAR_HEIGHT)
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

	if not (current is Enemy):
		current.defending = false
		current.stealthed = false
		for action: BattleAction in current.actions:
			if action.cooldown_remaining > 0:
				action.cooldown_remaining -= 1

	current.reset_turn()

	if current.halve_stats_rounds > 0:
		current.move_points_left = maxi(1, current.move_points_left / 2)
		current.halve_stats_rounds -= 1

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

	# === TOP INITIATIVE BAR (full width, above the grid) ===
	var init_panel := PanelContainer.new()
	init_panel.anchor_left = 0.0
	init_panel.anchor_top = 0.0
	init_panel.anchor_right = 1.0
	init_panel.anchor_bottom = 0.0
	init_panel.offset_left = 0.0
	init_panel.offset_right = 0.0
	init_panel.offset_top = 0.0
	init_panel.offset_bottom = TOP_BAR_HEIGHT
	canvas.add_child(init_panel)

	var init_scroll := ScrollContainer.new()
	init_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	init_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	init_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	init_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	init_panel.add_child(init_scroll)

	_initiative_container = HBoxContainer.new()
	_initiative_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_initiative_container.add_theme_constant_override("separation", 12)
	init_scroll.add_child(_initiative_container)

	# === BOTTOM PANEL (full width, below the grid) ===
	var bottom_panel := PanelContainer.new()
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 0.0
	bottom_panel.offset_right = 0.0
	bottom_panel.offset_top = -BOTTOM_BAR_HEIGHT
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
	_name_label.add_theme_font_size_override("font_size", 14)
	stats_vbox.add_child(_name_label)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 12)
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

	# Buttons section (horizontal so all three are always visible)
	var btn_hbox := HBoxContainer.new()
	btn_hbox.custom_minimum_size = Vector2(240, 0)
	btn_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(btn_hbox)

	_end_turn_button = Button.new()
	_end_turn_button.text = "End Turn"
	_end_turn_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_turn_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	btn_hbox.add_child(_end_turn_button)

	_end_battle_button = Button.new()
	_end_battle_button.text = "End Battle"
	_end_battle_button.visible = _should_show_end_battle_button()
	_end_battle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_battle_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_end_battle_button.pressed.connect(_on_end_battle_button_pressed)
	btn_hbox.add_child(_end_battle_button)

	var log_button := Button.new()
	log_button.text = "Log"
	log_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_button.pressed.connect(_toggle_log)
	btn_hbox.add_child(log_button)

	# Log panel — hidden by default, left side between the two bars
	_log_panel = PanelContainer.new()
	_log_panel.anchor_left = 0.0
	_log_panel.anchor_top = 0.0
	_log_panel.anchor_right = 0.0
	_log_panel.anchor_bottom = 1.0
	_log_panel.offset_left = 0.0
	_log_panel.offset_right = 300.0
	_log_panel.offset_top = TOP_BAR_HEIGHT
	_log_panel.offset_bottom = -BOTTOM_BAR_HEIGHT
	_log_panel.visible = false
	canvas.add_child(_log_panel)

	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_panel.add_child(_log_scroll)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_container)

	var feedback_layer := CanvasLayer.new()
	feedback_layer.name = "CombatFeedbackLayer"
	feedback_layer.layer = 20
	add_child(feedback_layer)

	_floating_text_root = Control.new()
	_floating_text_root.name = "FloatingTextRoot"
	_floating_text_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_floating_text_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_layer.add_child(_floating_text_root)

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
		if action.cooldown_remaining > 0:
			btn.text = action.action_name + " (%d)" % action.cooldown_remaining
		else:
			btn.text = action.action_name
		btn.disabled = current.has_acted or action.cooldown_remaining > 0
		btn.custom_minimum_size = Vector2(120, 0)
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_action_button_pressed.bind(action))
		_actions_container.add_child(btn)

func _toggle_log() -> void:
	_log_visible = not _log_visible
	_log_panel.visible = _log_visible

func _show_floating_feedback(info: Dictionary) -> void:
	if _floating_text_root == null:
		return

	var target: Player = info.get("target_ref") as Player
	if target == null:
		return

	var life_drain: int = int(info.get("life_drain", 0))
	if life_drain > 0:
		var attacker_ref: Player = info.get("attacker_ref") as Player
		if attacker_ref != null:
			var heal_pos := attacker_ref.global_position + Vector2(0.0, -Player.RADIUS - 10.0)
			CombatFloatingText.show_at(_floating_text_root, heal_pos, "+%d" % life_drain, Color(0.3, 0.95, 0.4))

	if info["hit"]:
		var damage: int = int(info.get("damage", 0))
		if damage <= 0:
			return
		var text := "-%d" % damage
		var color := Color(1.0, 0.35, 0.35) if target in player_characters else Color(1.0, 0.85, 0.2)
		var screen_pos := target.global_position + Vector2(0.0, -Player.RADIUS - 10.0)
		CombatFloatingText.show_at(_floating_text_root, screen_pos, text, color)
	else:
		var screen_pos := target.global_position + Vector2(0.0, -Player.RADIUS - 10.0)
		CombatFloatingText.show_at(_floating_text_root, screen_pos, "PUDŁO", Color(0.75, 0.75, 0.8))

func _log_attack(info: Dictionary) -> void:
	_show_floating_feedback(info)
	var msg: String
	if info["hit"]:
		msg = "%s used %s on %s — rolled %d (dodge %d%%) → HIT for %d dmg" % [
			info["attacker"], info["action"], info["target"],
			info["roll"], info["miss_chance"], info["damage"]
		]
		if int(info.get("life_drain", 0)) > 0:
			msg += " (+%d HP)" % int(info["life_drain"])
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

	match action.action_type:
		"aoe_adjacent":
			_execute_wide_slash(action)
			return
		"self_defend":
			current.defending = true
			current.has_acted = true
			_log_attack({"attacker": current.character_name, "action": "Defend",
				"target": "self", "hit": true, "roll": 0, "miss_chance": 0, "damage": 0})
			_refresh_action_buttons()
			_update_stats_panel()
			return
		"self_hide":
			current.stealthed = true
			action.cooldown_remaining = action.cooldown_max
			current.has_acted = true
			_log_attack({"attacker": current.character_name, "action": "Hide",
				"target": "self", "hit": true, "roll": 0, "miss_chance": 0, "damage": 0})
			_refresh_action_buttons()
			return

	_pending_action = action
	_targeting_mode = true
	queue_redraw()


func _execute_wide_slash(action: BattleAction) -> void:
	if combatants.is_empty():
		return
	var current: Player = combatants[current_turn_index]
	current.has_acted = true
	var hit_any: bool = false
	for enemy: Player in enemies.duplicate():
		var dist: int = abs(current.grid_pos.x - enemy.grid_pos.x) + abs(current.grid_pos.y - enemy.grid_pos.y)
		if dist > 1:
			continue
		hit_any = true
		var half_action := BattleAction.new()
		half_action.action_name = action.action_name
		half_action.damage = maxi(1, int(float(action.damage) * action.damage_multiplier))
		half_action.range = action.range
		var result := BattleAction.resolve(half_action, enemy)
		if result["hit"]:
			enemy.current_life = maxi(enemy.current_life - result["damage"], 0)
		_log_attack({"attacker": current.character_name, "action": action.action_name,
			"target": enemy.character_name, "target_ref": enemy, "hit": result["hit"],
			"roll": result["roll"], "miss_chance": result["miss_chance"], "damage": result["damage"]})
		_check_death_and_remove(enemy)
	if not hit_any:
		_log_attack({"attacker": current.character_name, "action": action.action_name,
			"target": "no enemies in range", "hit": false, "roll": 0, "miss_chance": 0, "damage": 0})
	_refresh_action_buttons()
	_update_initiative_display()


func _find_defender_for(target: Player) -> Player:
	for c: Player in player_characters:
		if c != target and c.defending:
			if abs(c.grid_pos.x - target.grid_pos.x) + abs(c.grid_pos.y - target.grid_pos.y) == 1:
				return c
	return target

func _update_initiative_display() -> void:
	for child in _initiative_container.get_children():
		child.queue_free()
	if combatants.is_empty():
		return

	var preview_count: int = mini(combatants.size() * 3, 20)
	for i in range(preview_count):
		var idx: int = (current_turn_index + i) % combatants.size()
		var c: Player = combatants[idx]

		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(110, 0)
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot.add_child(vbox)

		var name_lbl := Label.new()
		var hp_lbl := Label.new()
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.text = "%d/%d" % [c.current_life, c.max_life]

		if i == 0:
			name_lbl.text = "▶ " + c.character_name
			name_lbl.add_theme_font_size_override("font_size", 14)
			hp_lbl.add_theme_font_size_override("font_size", 12)
			slot.modulate = Color.GOLD
		else:
			name_lbl.text = c.character_name
			name_lbl.add_theme_font_size_override("font_size", 11)
			hp_lbl.add_theme_font_size_override("font_size", 10)
			if c is Enemy:
				slot.modulate = Color(1.0, 0.75, 0.75)
			else:
				slot.modulate = Color(0.75, 0.9, 1.0)

		vbox.add_child(name_lbl)
		vbox.add_child(hp_lbl)
		_initiative_container.add_child(slot)

func _update_stats_panel() -> void:
	if last_player_character == null:
		return
	var c := last_player_character
	_name_label.text = "%s   HP: %d / %d" % [c.character_name, c.current_life, c.max_life]
	_stats_label.text = "SPD:%d INI:%d AGI:%d STR:%d ARM:%d" % [
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
			var result: Dictionary
			if _pending_action.action_type == "arrow_knee":
				var half := BattleAction.new()
				half.damage = maxi(1, _pending_action.damage / 2)
				half.range = _pending_action.range
				result = BattleAction.resolve(half, target)
				if result["hit"]:
					target.current_life = maxi(target.current_life - result["damage"], 0)
					target.halve_stats_rounds = 2
			else:
				result = BattleAction.resolve(_pending_action, target)
				if result["hit"]:
					target.current_life = maxi(target.current_life - result["damage"], 0)
			var log_info := {
				"attacker": current.character_name,
				"action": _pending_action.action_name,
				"target": target.character_name,
				"target_ref": target,
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
	if player_characters.is_empty():
		_on_party_wiped()
		return
	if enemies.is_empty():
		_on_all_enemies_defeated()


func _reparent_players_to_game_state() -> void:
	_targeting_mode = false
	_pending_action = null
	for char: Player in player_characters:
		if is_instance_valid(char) and char.get_parent() != null:
			char.reparent(GameState)


func _go_to_scene(scene_path: String) -> void:
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("change_scene"):
		transition.change_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_WIDTH and cell.y >= 0 and cell.y < GRID_HEIGHT

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5 + TOP_BAR_HEIGHT)

func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori((pos.y - TOP_BAR_HEIGHT) / CELL_SIZE))

func _draw() -> void:
	draw_cells()
	draw_grid_lines()
	_draw_action_range()

func draw_cells() -> void:
	var grid_rect := Rect2(Vector2(0.0, TOP_BAR_HEIGHT), Vector2(GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE))
	if _background_texture != null:
		draw_texture_rect(_background_texture, grid_rect, false)

	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var cell: CellData = cells[Vector2i(x, y)]
			if cell.walkable:
				continue
			var rect := Rect2(Vector2(x * CELL_SIZE, y * CELL_SIZE + TOP_BAR_HEIGHT), Vector2(CELL_SIZE, CELL_SIZE))
			var terrain := str(cell.terrain_type)
			var tex: Texture2D = _cell_textures.get(Vector2i(x, y), _obstacle_textures.get(terrain, null))
			if tex != null:
				draw_texture_rect(tex, rect, false)
			else:
				var base_color: Color = OBSTACLE_COLORS.get(terrain, COLOR_OBSTACLE)
				draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, 0.4), true)

func draw_grid_lines() -> void:
	var total_width := GRID_WIDTH * CELL_SIZE
	var total_height := GRID_HEIGHT * CELL_SIZE
	for x in range(GRID_WIDTH + 1):
		var px := x * CELL_SIZE
		draw_line(Vector2(px, TOP_BAR_HEIGHT), Vector2(px, total_height + TOP_BAR_HEIGHT), COLOR_GRID, 2.0)
	for y in range(GRID_HEIGHT + 1):
		var py := y * CELL_SIZE + TOP_BAR_HEIGHT
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
				Vector2(coord.x * CELL_SIZE, coord.y * CELL_SIZE + TOP_BAR_HEIGHT),
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
	_reparent_players_to_game_state()
	_go_to_scene(_get_victory_scene_path())
