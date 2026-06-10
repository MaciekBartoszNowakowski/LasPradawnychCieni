class_name BattleMap
extends Node2D

const GRID_WIDTH := 20
const GRID_HEIGHT := 9
const CELL_SIZE := 64

const COLOR_GROUND := Color(0.25, 0.65, 0.25)
const COLOR_OBSTACLE := Color(0.45, 0.45, 0.45)
const COLOR_GRID := Color(0.10, 0.075, 0.055, 0.30)
const COLOR_RANGE := Color(0.82, 0.42, 0.30, 0.18)

const OBSTACLE_COLORS: Dictionary = {
	"stone": Color(0.5, 0.5, 0.55),
	"tree_log": Color(0.4, 0.25, 0.1),
	"river": Color(0.2, 0.45, 0.9)
}

const TOP_BAR_HEIGHT: float = 64.0
const BOTTOM_BAR_HEIGHT: float = 92.0

const BATTLE_GOLD_REWARD: int = 50
const DEFEAT_OVERLAY_SCENE_PATH := "res://scenes/ui/DefeatOverlay.tscn"
const NOTICE_FONT_PATH := "res://assets/ui/fonts/IMFellEnglishSC-Regular.ttf"
const NOTICE_TEXT_COLOR := Color(0.8666667, 0.827451, 0.7372549, 1.0)
const NOTICE_TEXT_HOVER_COLOR := Color(0.9411765, 0.90588236, 0.8156863, 1.0)
const NOTICE_TEXT_PRESSED_COLOR := Color(0.7607843, 0.6901961, 0.52156866, 1.0)
const NOTICE_TEXT_DISABLED_COLOR := Color(0.5529412, 0.52156866, 0.46666667, 1.0)
const NOTICE_OUTLINE_COLOR := Color(0.09411765, 0.078431375, 0.07058824, 1.0)
const ACTIVE_CELL_COLOR := Color(0.94, 0.74, 0.28, 0.20)
const ACTIVE_RING_COLOR := Color(1.0, 0.78, 0.28, 0.88)
const PLAYER_PATH_COLOR := Color(0.82, 0.72, 0.52, 0.78)
const ENEMY_PATH_COLOR := Color(0.78, 0.34, 0.28, 0.78)
const MOVE_RANGE_COLOR := Color(0.78, 0.68, 0.44, 0.14)
const MOVE_RANGE_EDGE_COLOR := Color(0.88, 0.76, 0.48, 0.24)
const TARGET_HOVER_COLOR := Color(1.0, 0.75, 0.32, 0.86)
const ENEMY_ACTION_PAUSE := 0.42
const PROJECTILE_DURATION := 0.18

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
var _stat_value_labels: Array[Label] = []
var _end_turn_button: Button
var _end_battle_button: Button

var _battle_log: Array[String] = []
var _log_panel: PanelContainer
var _log_scroll: ScrollContainer
var _log_container: VBoxContainer
var _log_visible: bool = false
var _floating_text_root: Control
var _victory_summary_layer: CanvasLayer
var _victory_pending_scene_path: String = ""
var _combat_visual_time: float = 0.0
var _defeat_overlay: DefeatOverlay
var _enemy_action_delay: float = 0.0

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
	GameState.player_team.add_money(BATTLE_GOLD_REWARD)
	MapState.complete_selected_map_node()
	_reparent_players_to_game_state()
	_show_victory_summary(_get_victory_scene_path(), BATTLE_GOLD_REWARD)


func _on_party_wiped() -> void:
	_enemy_acting = false
	_targeting_mode = false
	_pending_action = null
	set_process(false)
	if _end_turn_button != null:
		_end_turn_button.disabled = true
	if _end_battle_button != null:
		_end_battle_button.disabled = true
	_show_defeat_overlay()


func _show_victory_summary(scene_path: String, gold_reward: int) -> void:
	if _victory_summary_layer != null:
		return

	_victory_pending_scene_path = scene_path
	_enemy_acting = false
	_targeting_mode = false
	_pending_action = null
	set_process(false)

	if _end_turn_button != null:
		_end_turn_button.disabled = true
	if _end_battle_button != null:
		_end_battle_button.disabled = true

	_victory_summary_layer = CanvasLayer.new()
	_victory_summary_layer.name = "VictorySummaryLayer"
	_victory_summary_layer.layer = 50
	add_child(_victory_summary_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_victory_summary_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victory_summary_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520.0, 320.0)
	panel.add_theme_stylebox_override("panel", _create_summary_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Zwycięstwo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(title, 30, NOTICE_TEXT_COLOR)
	box.add_child(title)

	var reward := Label.new()
	reward.text = "Zdobyto %d złota." % gold_reward
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(reward, 22, Color(0.94, 0.82, 0.48, 1.0))
	box.add_child(reward)

	var summary := Label.new()
	summary.text = _build_party_summary_text()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_label_style(summary, 17, Color(0.78, 0.70, 0.58, 1.0))
	box.add_child(summary)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var continue_button := Button.new()
	continue_button.text = "Dalej"
	continue_button.custom_minimum_size = Vector2(180.0, 48.0)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.pressed.connect(_on_victory_summary_continue)
	_apply_button_style(continue_button)
	box.add_child(continue_button)


func _build_party_summary_text() -> String:
	var lines: Array[String] = []

	if GameState.player_team != null:
		if not GameState.player_team.characters.is_empty():
			lines.append("Ocalała drużyna:")
			for hero: Player in GameState.player_team.characters:
				if hero != null:
					lines.append("%s: %d/%d HP" % [hero.character_name, hero.current_life, hero.max_life])

		if GameState.player_team.has_fallen_characters():
			lines.append("")
			lines.append("Polegli:")
			for hero: Player in GameState.player_team.fallen_characters:
				if hero != null:
					lines.append("%s" % hero.character_name)

	if lines.is_empty():
		return "Drużyna wraca na szlak."

	return "\n".join(lines)


func _create_summary_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.88)
	style.border_color = Color(0.84705883, 0.8, 0.68235296, 0.44)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 12
	return style


func _on_victory_summary_continue() -> void:
	var scene_path := _victory_pending_scene_path
	if scene_path.is_empty():
		scene_path = _get_victory_scene_path()
	_go_to_scene(scene_path)

func _process(delta: float) -> void:
	_combat_visual_time += delta
	queue_redraw()

	if _enemy_acting:
		var current: Player = combatants[current_turn_index]
		if not current.is_moving():
			if _enemy_action_delay > 0.0:
				_enemy_action_delay = maxf(0.0, _enemy_action_delay - delta)
				return
			if not current.has_acted and current is Enemy:
				var attack_result := (current as Enemy).attack(player_characters)
				if not attack_result.is_empty():
					if attack_result["hit"]:
						var intended: Player = attack_result["target_ref"]
						var actual: Player = _find_defender_for(intended)
						actual.current_life = maxi(actual.current_life - attack_result["damage"], 0)
						if actual != intended:
							attack_result["target"] = actual.character_name + " (osłonił " + intended.character_name + ")"
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
		_enemy_action_delay = ENEMY_ACTION_PAUSE
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
		_enemy_action_delay = ENEMY_ACTION_PAUSE
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
	init_panel.add_theme_stylebox_override("panel", _create_bar_style())
	canvas.add_child(init_panel)
	_add_bar_background(init_panel)

	var init_scroll := ScrollContainer.new()
	init_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	init_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	init_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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
	bottom_panel.add_theme_stylebox_override("panel", _create_bar_style())
	canvas.add_child(bottom_panel)
	_add_bar_background(bottom_panel)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_panel.add_child(hbox)

	# Stats section
	var stats_vbox := VBoxContainer.new()
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(stats_vbox)

	_name_label = Label.new()
	_apply_label_style(_name_label, 17, Color(0.9098039, 0.8509804, 0.74509805, 1.0))
	stats_vbox.add_child(_name_label)

	var stat_chips_hbox := HBoxContainer.new()
	stat_chips_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_chips_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stat_chips_hbox.add_theme_constant_override("separation", 8)
	stats_vbox.add_child(stat_chips_hbox)

	_stat_value_labels.clear()
	for stat_name: String in ["Szybkość", "Inicjatywa", "Zręczność", "Siła", "Pancerz"]:
		var chip := VBoxContainer.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.alignment = BoxContainer.ALIGNMENT_CENTER
		chip.add_theme_constant_override("separation", 0)
		stat_chips_hbox.add_child(chip)

		var abbr_lbl := Label.new()
		abbr_lbl.text = stat_name
		abbr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_label_style(abbr_lbl, 13, Color(0.65, 0.58, 0.48, 1.0))
		chip.add_child(abbr_lbl)

		var val_lbl := Label.new()
		val_lbl.text = "-"
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_label_style(val_lbl, 22, Color(0.9411765, 0.8666667, 0.54509804, 1.0))
		chip.add_child(val_lbl)
		_stat_value_labels.append(val_lbl)

	# Actions panel — transparent so the bar background shows through
	var actions_panel := PanelContainer.new()
	actions_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var transparent_style := StyleBoxFlat.new()
	transparent_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	actions_panel.add_theme_stylebox_override("panel", transparent_style)
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
	_end_turn_button.text = "Koniec tury"
	_end_turn_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_turn_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	_apply_button_style(_end_turn_button)
	btn_hbox.add_child(_end_turn_button)

	_end_battle_button = Button.new()
	_end_battle_button.text = "Zakończ bitwę"
	_end_battle_button.visible = _should_show_end_battle_button()
	_end_battle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_battle_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_end_battle_button.pressed.connect(_on_end_battle_button_pressed)
	_apply_button_style(_end_battle_button)
	btn_hbox.add_child(_end_battle_button)

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

	_setup_defeat_overlay()


func _setup_defeat_overlay() -> void:
	var defeat_scene: PackedScene = load(DEFEAT_OVERLAY_SCENE_PATH) as PackedScene
	if defeat_scene == null:
		return

	_defeat_overlay = defeat_scene.instantiate() as DefeatOverlay
	if _defeat_overlay == null:
		return

	var defeat_canvas := CanvasLayer.new()
	defeat_canvas.name = "DefeatLayer"
	defeat_canvas.layer = 50
	add_child(defeat_canvas)
	defeat_canvas.add_child(_defeat_overlay)


func _show_defeat_overlay() -> void:
	if _defeat_overlay != null:
		_defeat_overlay.show_overlay()


func _get_notice_font() -> Font:
	if ResourceLoader.exists(NOTICE_FONT_PATH):
		return load(NOTICE_FONT_PATH) as Font
	return null

func _create_bar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 1.0)
	return style

func _add_bar_background(panel: Control) -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/map/topbar.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.modulate = Color(0.686, 0.686, 0.686, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

func _apply_label_style(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.07, 0.05, 0.035, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	var notice_font := _get_notice_font()
	if notice_font != null:
		label.add_theme_font_override("font", notice_font)

func _apply_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_content_margin(SIDE_LEFT, 12.0)
	normal.set_content_margin(SIDE_TOP, 6.0)
	normal.set_content_margin(SIDE_RIGHT, 12.0)
	normal.set_content_margin(SIDE_BOTTOM, 6.0)
	normal.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.58)
	normal.border_color = Color(0.84705883, 0.8, 0.68235296, 0.32)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 5
	normal.corner_radius_top_right = 5
	normal.corner_radius_bottom_right = 5
	normal.corner_radius_bottom_left = 5

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.085, 0.045, 0.72)
	hover.border_color = Color(0.9019608, 0.8666667, 0.78431374, 0.55)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.28)
	disabled.border_color = Color(0.84705883, 0.8, 0.68235296, 0.16)

	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", NOTICE_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", NOTICE_TEXT_HOVER_COLOR)
	button.add_theme_color_override("font_pressed_color", NOTICE_TEXT_PRESSED_COLOR)
	button.add_theme_color_override("font_disabled_color", NOTICE_TEXT_DISABLED_COLOR)
	button.add_theme_color_override("font_outline_color", NOTICE_OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_font_size_override("font_size", 16)
	var notice_font := _get_notice_font()
	if notice_font != null:
		button.add_theme_font_override("font", notice_font)


func _apply_active_action_button_style(button: Button) -> void:
	_apply_button_style(button)

	var active := StyleBoxFlat.new()
	active.set_content_margin(SIDE_LEFT, 12.0)
	active.set_content_margin(SIDE_TOP, 6.0)
	active.set_content_margin(SIDE_RIGHT, 12.0)
	active.set_content_margin(SIDE_BOTTOM, 6.0)
	active.bg_color = Color(0.16, 0.10, 0.035, 0.84)
	active.border_color = Color(1.0, 0.74, 0.30, 0.76)
	active.border_width_left = 2
	active.border_width_top = 2
	active.border_width_right = 2
	active.border_width_bottom = 2
	active.corner_radius_top_left = 5
	active.corner_radius_top_right = 5
	active.corner_radius_bottom_right = 5
	active.corner_radius_bottom_left = 5

	button.add_theme_stylebox_override("normal", active)
	button.add_theme_stylebox_override("hover", active)
	button.add_theme_stylebox_override("pressed", active)
	button.add_theme_stylebox_override("focus", active)
	button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.58, 1.0))


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
		if _targeting_mode and _pending_action == action:
			_apply_active_action_button_style(btn)
		else:
			_apply_button_style(btn)
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


func _show_projectile_feedback(info: Dictionary) -> void:
	var attacker := info.get("attacker_ref") as Player
	var target := info.get("target_ref") as Player
	if attacker == null or target == null:
		return

	var action_name := str(info.get("action", ""))
	var projectile_color := Color(0.0, 0.0, 0.0, 0.0)
	var projectile_length := 24.0
	var projectile_width := 3.0

	if action_name.begins_with("Strzał"):
		projectile_color = Color(0.86, 0.74, 0.46, 0.96)
		projectile_length = 30.0
		projectile_width = 2.4
	elif action_name == "Rzut nożem":
		projectile_color = Color(0.82, 0.84, 0.80, 0.96)
		projectile_length = 18.0
		projectile_width = 3.0
	else:
		return

	var start := attacker.global_position
	var end := target.global_position
	var delta := end - start
	if delta.length_squared() <= 1.0:
		return

	var projectile := Line2D.new()
	projectile.name = "ProjectileFeedback"
	projectile.width = projectile_width
	projectile.default_color = projectile_color
	projectile.points = PackedVector2Array([
		Vector2(-projectile_length * 0.5, 0.0),
		Vector2(projectile_length * 0.5, 0.0),
	])
	projectile.global_position = start
	projectile.rotation = delta.angle()
	projectile.z_index = 80
	add_child(projectile)

	var tween := create_tween()
	tween.tween_property(projectile, "global_position", end, PROJECTILE_DURATION)
	tween.parallel().tween_property(projectile, "modulate:a", 0.0, PROJECTILE_DURATION)
	tween.tween_callback(projectile.queue_free)


func _log_attack(info: Dictionary) -> void:
	_show_projectile_feedback(info)
	_show_floating_feedback(info)
	var target_ref := info.get("target_ref") as Player
	if target_ref != null and info.get("hit", false) == true and int(info.get("damage", 0)) > 0:
		target_ref.flash_hit()
	var msg: String
	if info["hit"]:
		msg = "%s wykonuje %s na %s — rzut %d (unik %d%%) → TRAFIENIE za %d pkt" % [
			info["attacker"], info["action"], info["target"],
			info["roll"], info["miss_chance"], info["damage"]
		]
		if int(info.get("life_drain", 0)) > 0:
			msg += " (+%d HP)" % int(info["life_drain"])
	else:
		msg = "%s wykonuje %s na %s — rzut %d (unik %d%%) → PUDŁO" % [
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
		_refresh_action_buttons()
		queue_redraw()
		return

	match action.action_type:
		"aoe_adjacent":
			_execute_wide_slash(action)
			return
		"self_defend":
			current.defending = true
			current.has_acted = true
			_log_attack({"attacker": current.character_name, "action": "Obrona",
				"target": "siebie", "hit": true, "roll": 0, "miss_chance": 0, "damage": 0})
			_refresh_action_buttons()
			_update_stats_panel()
			return
		"self_hide":
			current.stealthed = true
			action.cooldown_remaining = action.cooldown_max
			current.has_acted = true
			_log_attack({"attacker": current.character_name, "action": "Ukrycie",
				"target": "siebie", "hit": true, "roll": 0, "miss_chance": 0, "damage": 0})
			_refresh_action_buttons()
			return

	_pending_action = action
	_targeting_mode = true
	_refresh_action_buttons()
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
			"target": "brak wrogów w zasięgu", "hit": false, "roll": 0, "miss_chance": 0, "damage": 0})
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
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.0, 0.0, 0.0, 0.40)
		slot_style.border_width_left = 1
		slot_style.border_width_top = 1
		slot_style.border_width_right = 1
		slot_style.border_width_bottom = 1
		slot_style.corner_radius_top_left = 4
		slot_style.corner_radius_top_right = 4
		slot_style.corner_radius_bottom_right = 4
		slot_style.corner_radius_bottom_left = 4
		if i == 0:
			slot_style.border_color = Color(0.9411765, 0.8666667, 0.54509804, 0.9)
			slot_style.bg_color = Color(0.06, 0.045, 0.02, 0.75)
		elif c is Enemy:
			slot_style.border_color = Color(0.85, 0.45, 0.4, 0.6)
		else:
			slot_style.border_color = Color(0.5, 0.72, 0.85, 0.6)
		slot.add_theme_stylebox_override("panel", slot_style)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_child(vbox)

		var name_lbl := Label.new()
		var hp_lbl := Label.new()
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.text = "%d/%d" % [c.current_life, c.max_life]

		if i == 0:
			name_lbl.text = "▶ " + c.character_name
			_apply_label_style(name_lbl, 13, Color(0.9411765, 0.8666667, 0.54509804, 1.0))
			_apply_label_style(hp_lbl, 11, Color(0.84705883, 0.69411767, 0.35686275, 1.0))
		else:
			name_lbl.text = c.character_name
			if c is Enemy:
				_apply_label_style(name_lbl, 11, Color(0.95, 0.72, 0.68, 1.0))
				_apply_label_style(hp_lbl, 10, Color(0.85, 0.55, 0.5, 1.0))
			else:
				_apply_label_style(name_lbl, 11, Color(0.72, 0.88, 0.96, 1.0))
				_apply_label_style(hp_lbl, 10, Color(0.55, 0.75, 0.88, 1.0))

		vbox.add_child(name_lbl)
		vbox.add_child(hp_lbl)
		_initiative_container.add_child(slot)

func _update_stats_panel() -> void:
	if last_player_character == null:
		return
	var c := last_player_character
	_name_label.text = "%s   HP: %d / %d" % [c.character_name, c.current_life, c.max_life]
	var stat_values := [c.speed, c.initiative, c.agility, c.strength, c.armour]
	for i in range(_stat_value_labels.size()):
		_stat_value_labels[i].text = str(stat_values[i])

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
				_refresh_action_buttons()
				return
			var cell: CellData = cells[clicked_cell]
			if cell.occupant == null or not (cell.occupant is Enemy):
				_pending_action = null
				_refresh_action_buttons()
				return
			var target := cell.occupant as Player
			if target.current_life <= 0:
				_pending_action = null
				_refresh_action_buttons()
				return
			var dist: int = abs(current.grid_pos.x - target.grid_pos.x) \
						  + abs(current.grid_pos.y - target.grid_pos.y)
			if dist > _pending_action.range:
				_pending_action = null
				_refresh_action_buttons()
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
				"attacker_ref": current,
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
	var was_player_character := player_characters.has(character)
	if was_player_character and GameState.player_team != null:
		GameState.player_team.mark_character_fallen(character)
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
	_draw_move_range()
	draw_grid_lines()
	_draw_active_turn_indicator()
	_draw_movement_path_preview()
	_draw_action_range()
	_draw_target_hover()

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
		draw_line(Vector2(px, TOP_BAR_HEIGHT), Vector2(px, total_height + TOP_BAR_HEIGHT), COLOR_GRID, 1.0)
	for y in range(GRID_HEIGHT + 1):
		var py := y * CELL_SIZE + TOP_BAR_HEIGHT
		draw_line(Vector2(0, py), Vector2(total_width, py), COLOR_GRID, 1.0)

func _draw_move_range() -> void:
	var current := _get_current_combatant()
	if current == null or current is Enemy:
		return
	if current.is_moving() or _targeting_mode or current.move_points_left <= 0:
		return

	var blocked_coords := _set_other_combatants_solid(current)

	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var coord := Vector2i(x, y)
			if coord == current.grid_pos:
				continue
			if not cells.has(coord):
				continue
			var cell: CellData = cells[coord]
			if not cell.walkable or cell.occupant != null:
				continue
			var path: Array[Vector2i] = astar.get_id_path(current.grid_pos, coord)
			if path.is_empty() or path.size() - 1 > current.move_points_left:
				continue
			var rect := Rect2(
				Vector2(coord.x * CELL_SIZE, coord.y * CELL_SIZE + TOP_BAR_HEIGHT),
				Vector2(CELL_SIZE, CELL_SIZE)
			)
			draw_rect(rect.grow(-8.0), MOVE_RANGE_COLOR, true)
			draw_rect(rect.grow(-8.0), MOVE_RANGE_EDGE_COLOR, false, 1.0)

	_restore_solid_points(blocked_coords)

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
			var inner := rect.grow(-8.0)
			draw_rect(inner, COLOR_RANGE, true)
			draw_rect(inner, Color(0.9, 0.50, 0.34, 0.28), false, 1.0)


func _draw_target_hover() -> void:
	if not _targeting_mode or _pending_action == null or combatants.is_empty():
		return

	var current := _get_current_combatant()
	if current == null or current is Enemy:
		return

	var hover_cell := world_to_grid(get_global_mouse_position())
	if not is_in_bounds(hover_cell) or not cells.has(hover_cell):
		return

	var cell: CellData = cells[hover_cell]
	if cell.occupant == null or not (cell.occupant is Enemy):
		return

	var target := cell.occupant as Player
	var dist: int = abs(current.grid_pos.x - target.grid_pos.x) + abs(current.grid_pos.y - target.grid_pos.y)
	if dist > _pending_action.range:
		return

	var pulse: float = (sin(_combat_visual_time * 6.0) + 1.0) * 0.5
	var color := TARGET_HOVER_COLOR
	color.a = lerpf(0.58, TARGET_HOVER_COLOR.a, pulse)
	var rect := Rect2(
		Vector2(hover_cell.x * CELL_SIZE, hover_cell.y * CELL_SIZE + TOP_BAR_HEIGHT),
		Vector2(CELL_SIZE, CELL_SIZE)
	)
	draw_rect(rect.grow(-5.0), color, false, 3.0)


func _draw_active_turn_indicator() -> void:
	var current := _get_current_combatant()
	if current == null:
		return

	var cell_rect := Rect2(
		Vector2(current.grid_pos.x * CELL_SIZE, current.grid_pos.y * CELL_SIZE + TOP_BAR_HEIGHT),
		Vector2(CELL_SIZE, CELL_SIZE)
	)
	var pulse: float = (sin(_combat_visual_time * 5.0) + 1.0) * 0.5
	var ring_color := ACTIVE_RING_COLOR
	ring_color.a = lerpf(0.48, 0.92, pulse)

	draw_rect(cell_rect.grow(-4.0), ACTIVE_CELL_COLOR, true)
	draw_rect(cell_rect.grow(-5.0), ring_color, false, 3.0)

	var center := grid_to_world(current.grid_pos)
	var arrow_y := center.y - CELL_SIZE * 0.58 - pulse * 6.0
	var arrow := PackedVector2Array([
		Vector2(center.x, arrow_y + 18.0),
		Vector2(center.x - 11.0, arrow_y),
		Vector2(center.x + 11.0, arrow_y),
	])
	draw_colored_polygon(arrow, ring_color)


func _draw_movement_path_preview() -> void:
	var current := _get_current_combatant()
	if current == null:
		return

	var path: Array[Vector2i] = []
	var path_points: Array[Vector2] = []
	var color := PLAYER_PATH_COLOR

	if current.is_moving():
		path_points = current.get_remaining_path_world_points()
		if current is Enemy:
			color = ENEMY_PATH_COLOR
	elif not (current is Enemy) and not _targeting_mode:
		path = _get_hover_movement_path_for_current(current)

	if path_points.size() >= 2:
		_draw_world_path(path_points, color)
		return

	if path.size() < 2:
		return

	_draw_grid_path(path, color)


func _get_current_combatant() -> Player:
	if combatants.is_empty():
		return null
	if current_turn_index < 0 or current_turn_index >= combatants.size():
		return null
	return combatants[current_turn_index]


func _set_other_combatants_solid(current: Player) -> Array[Vector2i]:
	var blocked_coords: Array[Vector2i] = []
	for combatant: Player in combatants:
		if combatant == current:
			continue
		astar.set_point_solid(combatant.grid_pos, true)
		blocked_coords.append(combatant.grid_pos)
	return blocked_coords


func _restore_solid_points(coords: Array[Vector2i]) -> void:
	for coord: Vector2i in coords:
		astar.set_point_solid(coord, false)


func _get_hover_movement_path_for_current(current: Player) -> Array[Vector2i]:
	if current.move_points_left <= 0:
		return []

	var clicked_cell: Vector2i = world_to_grid(get_global_mouse_position())

	if not is_in_bounds(clicked_cell):
		return []
	if not cells.has(clicked_cell):
		return []

	var target_cell: CellData = cells[clicked_cell]
	if not target_cell.walkable or target_cell.occupant != null:
		return []

	var blocked_coords := _set_other_combatants_solid(current)

	var path: Array[Vector2i] = astar.get_id_path(current.grid_pos, clicked_cell)

	_restore_solid_points(blocked_coords)

	if path.size() > current.move_points_left + 1:
		path = path.slice(0, current.move_points_left + 1)

	return path


func _draw_grid_path(path: Array[Vector2i], color: Color) -> void:
	if path.size() < 2:
		return

	var pulse: float = (sin(_combat_visual_time * 4.0) + 1.0) * 0.5
	var shadow := Color(0.0, 0.0, 0.0, 0.36)
	var path_color := color
	path_color.a = lerpf(0.48, color.a, pulse)

	for i in range(path.size() - 1):
		var from_coord: Vector2i = path[i]
		var to_coord: Vector2i = path[i + 1]
		var from_point := grid_to_world(from_coord)
		var to_point := grid_to_world(to_coord)

		if from_coord.x != to_coord.x and from_coord.y != to_coord.y:
			var elbow := Vector2(to_point.x, from_point.y)
			_draw_path_segment(from_point, elbow, shadow, path_color)
			_draw_path_segment(elbow, to_point, shadow, path_color)
		else:
			_draw_path_segment(from_point, to_point, shadow, path_color)

	for i in range(1, path.size()):
		var point := grid_to_world(path[i])
		var marker_rect := Rect2(point - Vector2(6.0, 6.0), Vector2(12.0, 12.0))
		var marker_color := path_color
		marker_color.a = lerpf(0.34, 0.68, pulse)
		draw_rect(marker_rect, marker_color, false, 2.0)

	var end_point := grid_to_world(path[path.size() - 1])
	var end_rect := Rect2(end_point - Vector2(15.0, 15.0), Vector2(30.0, 30.0))
	var end_color := path_color
	end_color.a = lerpf(0.48, 0.86, pulse)
	draw_rect(end_rect, end_color, false, 3.0)


func _draw_world_path(points: Array[Vector2], color: Color) -> void:
	if points.size() < 2:
		return

	var pulse: float = (sin(_combat_visual_time * 4.0) + 1.0) * 0.5
	var shadow := Color(0.0, 0.0, 0.0, 0.36)
	var path_color := color
	path_color.a = lerpf(0.48, color.a, pulse)

	for i in range(points.size() - 1):
		_draw_path_segment(points[i], points[i + 1], shadow, path_color)

	for i in range(1, points.size()):
		var marker_rect := Rect2(points[i] - Vector2(6.0, 6.0), Vector2(12.0, 12.0))
		var marker_color := path_color
		marker_color.a = lerpf(0.30, 0.58, pulse)
		draw_rect(marker_rect, marker_color, false, 2.0)

	var end_point := points[points.size() - 1]
	var end_rect := Rect2(end_point - Vector2(15.0, 15.0), Vector2(30.0, 30.0))
	var end_color := path_color
	end_color.a = lerpf(0.48, 0.86, pulse)
	draw_rect(end_rect, end_color, false, 3.0)


func _draw_path_segment(from_point: Vector2, to_point: Vector2, shadow: Color, color: Color) -> void:
	var delta := to_point - from_point
	if delta.length_squared() <= 1.0:
		return

	var direction := delta.normalized()
	var trim := 16.0
	var start := from_point + direction * trim
	var end := to_point - direction * trim

	if start.distance_squared_to(end) <= 1.0:
		return

	draw_line(start + Vector2(0.0, 2.0), end + Vector2(0.0, 2.0), shadow, 5.0)
	draw_line(start, end, color, 2.4)

	var mid := (start + end) * 0.5
	var normal := Vector2(-direction.y, direction.x)
	var notch_color := color
	notch_color.a = min(color.a + 0.12, 1.0)
	draw_line(mid - normal * 5.0, mid + normal * 5.0, notch_color, 1.8)

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
	_on_all_enemies_defeated()
