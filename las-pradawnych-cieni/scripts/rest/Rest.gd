extends Control
class_name Rest

const MAP_SCENE_PATH := "res://scenes/map/Map.tscn"

const ACTION_PANEL_WIDTH: float = 420.0
const ACTION_PANEL_HEIGHT: float = 112.0
const ACTION_PANEL_BOTTOM_MARGIN: float = 28.0
const ACTION_PANEL_SIDE_MARGIN: float = 32.0

const CONTROL_PANEL_WIDTH: float = 420.0
const CONTROL_PANEL_HEIGHT: float = 112.0
const CONTROL_PANEL_BOTTOM_MARGIN: float = 28.0
const CONTROL_PANEL_SIDE_MARGIN: float = 32.0

const CHARACTER_PANEL_WIDTH: float = 300.0
const CHARACTER_PANEL_HEIGHT: float = 300.0
const CHARACTER_PANEL_TOP_MARGIN: float = 15.0
const CHARACTER_PANEL_SIDE_MARGIN: float = 15.0

const HERO_SLOT_SIZE := Vector2(160.0, 230.0)

const APPLY_ENTRY_BONUS := true
const ENTRY_HEAL_AMOUNT := 2

var party: Array[Player] = []

var selected_hero_index: int = -1
var hovered_hero_index: int = -1
var rest_used: bool = false

var hero_slots: Array[Control] = []


@onready var ui_root: Control = _get_first_control([
	"UILayer/UIRoot",
	"UIRoot"
])

@onready var background_layer: Control = _get_first_control([
	"BackgroundLayer"
])

@onready var top_bar: Control = _get_first_control([
	"UILayer/UIRoot/TopBar",
	"UIRoot/TopBar",
	"TopBar"
])

@onready var camp_layer: Control = _get_first_control([
	"CampLayer"
])

@onready var party_slots: Control = _get_first_control([
	"CampLayer/PartySlots"
])

@onready var campfire: Control = _get_first_control([
	"CampLayer/Campfire",
	"CampLayer/CampfireMarker"
])

@onready var action_panel: PanelContainer = _get_first_panel([
	"UILayer/UIRoot/ActionPanel",
	"UIRoot/ActionPanel",
	"ActionPanel"
])

@onready var controls_panel: PanelContainer = _get_first_panel([
	"UILayer/UIRoot/ControlsPanel",
	"UIRoot/ControlsPanel",
	"ControlsPanel"
])

@onready var character_panel: PanelContainer = _get_first_panel([
	"UILayer/UIRoot/CharacterPanel",
	"UIRoot/CharacterPanel",
	"CharacterPanel"
])

@onready var rest_button: Button = _get_first_button([
	"UILayer/UIRoot/ActionPanel/MarginContainer/VBoxContainer/MainActionsRow/RestButton",
	"UILayer/UIRoot/ActionPanel/MarginContainer/VBoxContainer/RestButton",
	"UIRoot/ActionPanel/MarginContainer/VBoxContainer/MainActionsRow/RestButton",
	"UIRoot/ActionPanel/MarginContainer/VBoxContainer/RestButton",
	"ActionPanel/MarginContainer/VBoxContainer/MainActionsRow/RestButton",
	"ActionPanel/MarginContainer/VBoxContainer/RestButton"
])

@onready var prepare_button: Button = _get_first_button([
	"UILayer/UIRoot/ActionPanel/MarginContainer/VBoxContainer/MainActionsRow/PrepareButton",
	"UILayer/UIRoot/ActionPanel/MarginContainer/VBoxContainer/PrepareButton",
	"UIRoot/ActionPanel/MarginContainer/VBoxContainer/MainActionsRow/PrepareButton",
	"UIRoot/ActionPanel/MarginContainer/VBoxContainer/PrepareButton",
	"ActionPanel/MarginContainer/VBoxContainer/MainActionsRow/PrepareButton",
	"ActionPanel/MarginContainer/VBoxContainer/PrepareButton"
])

@onready var leave_button: Button = _get_first_button([
	"UILayer/UIRoot/ActionPanel/MarginContainer/VBoxContainer/LeaveButton",
	"UIRoot/ActionPanel/MarginContainer/VBoxContainer/LeaveButton",
	"ActionPanel/MarginContainer/VBoxContainer/LeaveButton"
])

@onready var close_button: Button = _get_first_button([
	"UILayer/UIRoot/CharacterPanel/MarginContainer/CharacterPanelContent/HeaderRow/CloseButton",
	"UIRoot/CharacterPanel/MarginContainer/CharacterPanelContent/HeaderRow/CloseButton",
	"CharacterPanel/MarginContainer/CharacterPanelContent/HeaderRow/CloseButton",

	"UILayer/UIRoot/CharacterPanel/MarginContainer/CharacterPanelContent/CloseButton",
	"UIRoot/CharacterPanel/MarginContainer/CharacterPanelContent/CloseButton",
	"CharacterPanel/MarginContainer/CharacterPanelContent/CloseButton"
])


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	_load_party_from_game_state()
	_setup_top_bar()

	_layout_scene()
	call_deferred("_layout_scene")

	_setup_panels()
	_setup_buttons()
	_setup_hero_slots()
	_setup_controls_panel_text()

	if character_panel != null:
		character_panel.visible = false

	if APPLY_ENTRY_BONUS:
		_apply_entry_bonus()

	_queue_redraw_hero_slots()


func _on_viewport_size_changed() -> void:
	_layout_scene()
	_queue_redraw_hero_slots()


func _load_party_from_game_state() -> void:
	if GameState.player_team == null:
		GameState.player_team = Team.new()

	party = GameState.player_team.characters


func _get_first_control(paths: Array) -> Control:
	for path in paths:
		var node := get_node_or_null(str(path))

		if node != null and node is Control:
			return node as Control

	return null


func _get_first_panel(paths: Array) -> PanelContainer:
	for path in paths:
		var node := get_node_or_null(str(path))

		if node != null and node is PanelContainer:
			return node as PanelContainer

	return null


func _get_first_button(paths: Array) -> Button:
	for path in paths:
		var node := get_node_or_null(str(path))

		if node != null and node is Button:
			return node as Button

	return null


func _setup_top_bar() -> void:
	if top_bar == null:
		return

	var gold: int = 0

	if GameState.player_team != null:
		gold = GameState.player_team.money

	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if top_bar.has_method("setup"):
		top_bar.setup(
			"Leśne Obozowisko",
			"Odpocznij przed dalszą wyprawą",
			gold
		)


func _layout_scene() -> void:
	_layout_ui_root()

	var top_y: float = _get_content_top_y()

	_layout_background_layer(top_y)
	_layout_camp_layer(top_y)
	_layout_controls_panel()
	_layout_action_panel()
	_layout_character_panel(top_y)

	call_deferred("_layout_hero_slots_around_campfire")


func _layout_ui_root() -> void:
	if ui_root == null:
		return

	ui_root.anchor_left = 0.0
	ui_root.anchor_top = 0.0
	ui_root.anchor_right = 1.0
	ui_root.anchor_bottom = 1.0

	ui_root.offset_left = 0.0
	ui_root.offset_top = 0.0
	ui_root.offset_right = 0.0
	ui_root.offset_bottom = 0.0

	# UIRoot przykrywa całą scenę, więc nie może przechwytywać kliknięć w bohaterów.
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_content_top_y() -> float:
	if top_bar == null:
		return 0.0

	var top_bar_rect: Rect2 = top_bar.get_global_rect()
	var root_rect: Rect2 = get_global_rect()

	return max(0.0, top_bar_rect.position.y + top_bar_rect.size.y - root_rect.position.y)


func _layout_background_layer(top_y: float) -> void:
	if background_layer == null:
		return

	background_layer.anchor_left = 0.0
	background_layer.anchor_top = 0.0
	background_layer.anchor_right = 1.0
	background_layer.anchor_bottom = 1.0

	background_layer.offset_left = 0.0
	background_layer.offset_top = top_y
	background_layer.offset_right = 0.0
	background_layer.offset_bottom = 0.0

	background_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _layout_camp_layer(top_y: float) -> void:
	if camp_layer == null:
		return

	camp_layer.anchor_left = 0.0
	camp_layer.anchor_top = 0.0
	camp_layer.anchor_right = 1.0
	camp_layer.anchor_bottom = 1.0

	camp_layer.offset_left = 0.0
	camp_layer.offset_top = top_y
	camp_layer.offset_right = 0.0
	camp_layer.offset_bottom = 0.0

	camp_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if party_slots != null:
		party_slots.anchor_left = 0.0
		party_slots.anchor_top = 0.0
		party_slots.anchor_right = 1.0
		party_slots.anchor_bottom = 1.0

		party_slots.offset_left = 0.0
		party_slots.offset_top = 0.0
		party_slots.offset_right = 0.0
		party_slots.offset_bottom = 0.0

		party_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
		party_slots.z_index = 20

	if campfire != null:
		campfire.anchor_left = 0.5
		campfire.anchor_top = 0.68
		campfire.anchor_right = 0.5
		campfire.anchor_bottom = 0.68

		# Ten Control może być tylko niewidzialnym markerem środka ogniska.
		campfire.offset_left = -12.0
		campfire.offset_top = -12.0
		campfire.offset_right = 12.0
		campfire.offset_bottom = 12.0

		campfire.mouse_filter = Control.MOUSE_FILTER_IGNORE
		campfire.z_index = 10


func _layout_controls_panel() -> void:
	if controls_panel == null:
		return

	controls_panel.anchor_left = 0.0
	controls_panel.anchor_top = 1.0
	controls_panel.anchor_right = 0.0
	controls_panel.anchor_bottom = 1.0

	controls_panel.offset_left = CONTROL_PANEL_SIDE_MARGIN
	controls_panel.offset_top = -CONTROL_PANEL_HEIGHT - CONTROL_PANEL_BOTTOM_MARGIN
	controls_panel.offset_right = CONTROL_PANEL_SIDE_MARGIN + CONTROL_PANEL_WIDTH
	controls_panel.offset_bottom = -CONTROL_PANEL_BOTTOM_MARGIN


func _layout_action_panel() -> void:
	if action_panel == null:
		return

	action_panel.anchor_left = 1.0
	action_panel.anchor_top = 1.0
	action_panel.anchor_right = 1.0
	action_panel.anchor_bottom = 1.0

	action_panel.offset_left = -ACTION_PANEL_WIDTH - ACTION_PANEL_SIDE_MARGIN
	action_panel.offset_top = -ACTION_PANEL_HEIGHT - ACTION_PANEL_BOTTOM_MARGIN
	action_panel.offset_right = -ACTION_PANEL_SIDE_MARGIN
	action_panel.offset_bottom = -ACTION_PANEL_BOTTOM_MARGIN


func _layout_character_panel(top_y: float) -> void:
	if character_panel == null:
		return

	var show_on_left := false

	if selected_hero_index >= 0:
		show_on_left = _is_left_side_hero(selected_hero_index)

	character_panel.anchor_top = 0.0
	character_panel.anchor_bottom = 0.0
	character_panel.offset_top = top_y + CHARACTER_PANEL_TOP_MARGIN
	character_panel.offset_bottom = top_y + CHARACTER_PANEL_TOP_MARGIN + CHARACTER_PANEL_HEIGHT

	if show_on_left:
		character_panel.anchor_left = 0.0
		character_panel.anchor_right = 0.0
		character_panel.offset_left = CHARACTER_PANEL_SIDE_MARGIN
		character_panel.offset_right = CHARACTER_PANEL_SIDE_MARGIN + CHARACTER_PANEL_WIDTH
	else:
		character_panel.anchor_left = 1.0
		character_panel.anchor_right = 1.0
		character_panel.offset_left = -CHARACTER_PANEL_SIDE_MARGIN - CHARACTER_PANEL_WIDTH
		character_panel.offset_right = -CHARACTER_PANEL_SIDE_MARGIN

	character_panel.z_index = 80


func _setup_panels() -> void:
	if action_panel != null:
		action_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_apply_action_panel_style(action_panel)

	if controls_panel != null:
		controls_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_apply_controls_panel_style(controls_panel)

	if character_panel != null:
		character_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_apply_character_panel_style(character_panel)


func _setup_buttons() -> void:
	if rest_button != null:
		rest_button.pressed.connect(_on_rest_button_pressed)
		_apply_button_style(rest_button)

	if prepare_button != null:
		prepare_button.visible = false
		prepare_button.disabled = true

	if leave_button != null:
		leave_button.pressed.connect(_on_leave_button_pressed)
		_apply_button_style(leave_button)

	if close_button != null:
		close_button.pressed.connect(_close_character_panel)
		close_button.mouse_filter = Control.MOUSE_FILTER_STOP
		_apply_button_style(close_button)
	else:
		push_warning("Rest: nie znaleziono CloseButton")


func _setup_controls_panel_text() -> void:
	if controls_panel == null:
		return

	var title_label := controls_panel.find_child("TitleLabel", true, false) as Label

	if title_label != null:
		title_label.text = "Drużyna"
		title_label.add_theme_color_override("font_color", Color("#F2DFC5"))

	var hint_label := controls_panel.find_child("HintLabel", true, false) as Label

	if hint_label != null:
		hint_label.text = "Kliknij bohatera przy ognisku, aby zobaczyć jego statystyki."
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.add_theme_color_override("font_color", Color("#BDA58A"))


func _setup_hero_slots() -> void:
	hero_slots.clear()

	for i in range(4):
		var slot := get_node_or_null("CampLayer/PartySlots/HeroSlot%d" % (i + 1)) as Control

		if slot == null:
			continue

		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot.clip_contents = false
		slot.z_index = 30

		hero_slots.append(slot)

		_bind_hero_slot(slot, i)

		slot.draw.connect(func() -> void:
			_on_hero_slot_draw(slot, i)
		)

	_layout_hero_slots_around_campfire()


func _layout_hero_slots_around_campfire() -> void:
	if party_slots == null:
		return

	var visible_count: int = min(party.size(), hero_slots.size(), 4)
	var fire_center := _get_campfire_center_in_party_slots()
	var positions := _get_party_positions_around_fire(fire_center, visible_count)

	for i in range(hero_slots.size()):
		var slot := hero_slots[i]

		if slot == null:
			continue

		slot.visible = i < visible_count

		if i >= visible_count:
			continue

		slot.anchor_left = 0.0
		slot.anchor_top = 0.0
		slot.anchor_right = 0.0
		slot.anchor_bottom = 0.0

		slot.custom_minimum_size = HERO_SLOT_SIZE
		slot.size = HERO_SLOT_SIZE

		var target_center: Vector2 = positions[i]
		slot.position = target_center - HERO_SLOT_SIZE * 0.5
		slot.queue_redraw()


func _get_campfire_center_in_party_slots() -> Vector2:
	if party_slots == null:
		return Vector2.ZERO

	if campfire == null:
		return Vector2(party_slots.size.x * 0.5, party_slots.size.y * 0.68)

	var fire_rect: Rect2 = campfire.get_global_rect()
	var slots_rect: Rect2 = party_slots.get_global_rect()

	return fire_rect.get_center() - slots_rect.position


func _get_party_positions_around_fire(fire_center: Vector2, count: int) -> Array[Vector2]:
	# Pozycje są dobrane do obecnego tła: 2 bohaterów po lewej stronie ogniska
	# i 2 po prawej, w wolnych miejscach zaznaczonych na screenie.
	# Kolejność indeksów:
	# 0 - lewy zewnętrzny / niżej
	# 1 - lewy wewnętrzny / wyżej
	# 2 - prawy wewnętrzny / wyżejs
	# 3 - prawy zewnętrzny / niżej
	# Minimalnie bliżej ogniska niż poprzednio, nadal w czerwonych strefach.
	var left_outer := fire_center + Vector2(-250.0, -50.0)
	var left_inner := fire_center + Vector2(-120.0, -120.0)
	var right_inner := fire_center + Vector2(120.0, -120.0)
	var right_outer := fire_center + Vector2(250.0, -50.0)

	match count:
		1:
			return [
				right_inner
			]

		2:
			return [
				left_inner,
				right_inner
			]

		3:
			return [
				left_outer,
				left_inner,
				right_inner
			]

		_:
			return [
				left_outer,
				left_inner,
				right_inner,
				right_outer
			]


func _is_left_side_hero(index: int) -> bool:
	if index < 0 or index >= hero_slots.size():
		return false

	var slot := hero_slots[index]

	if slot == null or party_slots == null:
		return index <= 1

	var slot_center_x := slot.position.x + slot.size.x * 0.5
	return slot_center_x < party_slots.size.x * 0.5


func _bind_hero_slot(slot: Control, index: int) -> void:
	slot.gui_input.connect(func(event: InputEvent) -> void:
		_on_hero_slot_gui_input(event, index)
	)

	slot.mouse_entered.connect(func() -> void:
		if index >= party.size():
			return

		hovered_hero_index = index
		_queue_redraw_hero_slots()
	)

	slot.mouse_exited.connect(func() -> void:
		if hovered_hero_index == index:
			hovered_hero_index = -1
			_queue_redraw_hero_slots()
	)


func _on_hero_slot_gui_input(event: InputEvent, index: int) -> void:
	if index >= party.size():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
			
			UiAudio.play_click()
			
			selected_hero_index = index
			_show_character_panel(index)
			_queue_redraw_hero_slots()


func _on_rest_button_pressed() -> void:
	if rest_used:
		return
	
	UiAudio.play_click()
	
	for character: Player in party:
		var missing_hp: int = character.max_life - character.current_life

		if missing_hp <= 0:
			continue

		var heal_amount: int = max(1, int(ceil(float(missing_hp) * 0.4)))

		character.current_life = min(
			character.max_life,
			character.current_life + heal_amount
		)

		character.queue_redraw()

	rest_used = true

	if rest_button != null:
		rest_button.disabled = true
		rest_button.text = "Odpoczęto"

	if selected_hero_index != -1:
		_show_character_panel(selected_hero_index)

	_queue_redraw_hero_slots()


func _on_prepare_button_pressed() -> void:
	pass


func _on_leave_button_pressed() -> void:
	UiAudio.play_click()
	
	if ResourceLoader.exists(MAP_SCENE_PATH):
		get_tree().change_scene_to_file(MAP_SCENE_PATH)
	else:
		print("Brak sceny mapy pod ścieżką: ", MAP_SCENE_PATH)


func _apply_entry_bonus() -> void:
	for character: Player in party:
		character.current_life = min(
			character.max_life,
			character.current_life + ENTRY_HEAL_AMOUNT
		)

		character.queue_redraw()

	_queue_redraw_hero_slots()


func _show_character_panel(index: int) -> void:
	if character_panel == null:
		return

	if index < 0 or index >= party.size():
		return

	var character: Player = party[index]

	character_panel.visible = true
	_layout_character_panel(_get_content_top_y())

	_set_character_label("CharacterNameLabel", _get_character_display_name(character))
	#_set_character_label("CharacterClassLabel", _get_character_class_name(character))

	_set_character_label(
		"HPLabel",
		"HP: %d / %d" % [character.current_life, character.max_life]
	)

	_set_character_label(
		"StatusListLabel",
		"SPD: %d\nINI: %d\nAGI: %d\nSTR: %d\nARM: %d" % [
			character.speed,
			character.initiative,
			character.agility,
			character.strength,
			character.armour
		]
	)

	_set_character_label(
		"InventoryListLabel",
		"Ekwipunek zostanie dodany później."
	)

	var hp_bar := character_panel.find_child("HPBar", true, false) as ProgressBar

	if hp_bar != null:
		hp_bar.max_value = character.max_life
		hp_bar.value = character.current_life


func _close_character_panel() -> void:
	UiAudio.play_click()
	selected_hero_index = -1

	if character_panel != null:
		character_panel.visible = false

	_queue_redraw_hero_slots()


func _set_character_label(label_name: String, value: String) -> void:
	if character_panel == null:
		return

	var label := character_panel.find_child(label_name, true, false) as Label

	if label != null:
		label.text = value


func _get_character_display_name(character: Player) -> String:
	match character.character_name:
		"Knight":
			return "Wojownik"
		"Rogue":
			return "Łotrzyk"
		"Archer":
			return "Łowca"
		_:
			return character.character_name


func _get_character_class_name(character: Player) -> String:
	match character.character_name:
		"Knight":
			return "Rycerz"
		"Rogue":
			return "Łotrzyk"
		"Archer":
			return "Łowca"
		_:
			return "Postać"


func _queue_redraw_hero_slots() -> void:
	for slot in hero_slots:
		if slot != null:
			slot.queue_redraw()


func _on_hero_slot_draw(slot: Control, index: int) -> void:
	if index >= party.size():
		return

	var rect := Rect2(Vector2.ZERO, slot.size)
	_draw_hero_slot(slot, rect, index)


func _draw_hero_slot(canvas: Control, rect: Rect2, index: int) -> void:
	var character: Player = party[index]
	var center := rect.get_center()

	var is_selected := selected_hero_index == index
	var is_hovered := hovered_hero_index == index

	if is_selected:
		canvas.draw_circle(
			center + Vector2(0.0, 56.0),
			58.0,
			Color(1.0, 0.48, 0.14, 0.20)
		)

		canvas.draw_arc(
			center + Vector2(0.0, 56.0),
			58.0,
			0.0,
			TAU,
			64,
			Color("#D48A32"),
			3.0
		)

	elif is_hovered:
		canvas.draw_circle(
			center + Vector2(0.0, 56.0),
			52.0,
			Color(1.0, 0.48, 0.14, 0.12)
		)

	canvas.draw_rect(
		Rect2(center + Vector2(-46.0, 78.0), Vector2(92.0, 22.0)),
		Color(0.0, 0.0, 0.0, 0.22),
		true
	)

	var body_color := character.color.lerp(Color.BLACK, 0.30)
	var light_color := character.color.lerp(Color.WHITE, 0.22)
	var dark_color := character.color.lerp(Color.BLACK, 0.58)

	canvas.draw_line(center + Vector2(-16.0, 44.0), center + Vector2(-27.0, 84.0), dark_color, 8.0)
	canvas.draw_line(center + Vector2(16.0, 44.0), center + Vector2(27.0, 84.0), dark_color, 8.0)

	var body_points := PackedVector2Array([
		center + Vector2(-25.0, -18.0),
		center + Vector2(25.0, -18.0),
		center + Vector2(32.0, 48.0),
		center + Vector2(-32.0, 48.0)
	])

	canvas.draw_colored_polygon(body_points, body_color)

	canvas.draw_line(center + Vector2(-20.0, -5.0), center + Vector2(-45.0, 31.0), dark_color, 7.0)
	canvas.draw_line(center + Vector2(20.0, -5.0), center + Vector2(45.0, 31.0), dark_color, 7.0)

	canvas.draw_circle(center + Vector2(0.0, -45.0), 19.0, body_color)
	canvas.draw_circle(center + Vector2(7.0, -49.0), 5.8, light_color)

	var font := canvas.get_theme_default_font()

	if font != null:
		canvas.draw_string(
			font,
			Vector2(rect.position.x, rect.position.y + rect.size.y - 54.0),
			_get_character_display_name(character),
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			17,
			Color("#F2DFC5")
		)

	var hp_bar_rect := Rect2(
		rect.position.x + rect.size.x * 0.16,
		rect.position.y + rect.size.y - 38.0,
		rect.size.x * 0.68,
		11.0
	)

	_draw_hp_bar(canvas, hp_bar_rect, character.current_life, character.max_life)

	if font != null:
		canvas.draw_string(
			font,
			Vector2(rect.position.x, rect.position.y + rect.size.y - 13.0),
			"%d / %d HP" % [character.current_life, character.max_life],
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			14,
			Color("#D9C7AE")
		)


func _draw_hp_bar(canvas: Control, rect: Rect2, hp: int, max_hp: int) -> void:
	var ratio := 0.0

	if max_hp > 0:
		ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)

	canvas.draw_rect(rect, Color("#1C1510"))
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), Color("#4F9A45"))
	canvas.draw_rect(rect, Color("#7A5A35"), false, 1.0)


func _apply_action_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()

	style.bg_color = Color(0.09, 0.06, 0.04, 0.88)
	style.border_color = Color("#8B5E34")

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14

	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 10

	panel.add_theme_stylebox_override("panel", style)


func _apply_controls_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()

	style.bg_color = Color(0.08, 0.055, 0.035, 0.82)
	style.border_color = Color("#755331")

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12

	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 8

	panel.add_theme_stylebox_override("panel", style)


func _apply_character_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()

	style.bg_color = Color(0.08, 0.055, 0.035, 0.88)
	style.border_color = Color("#8B5E34")

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14

	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 10

	panel.add_theme_stylebox_override("panel", style)


func _apply_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()

	normal.bg_color = Color(0.18, 0.13, 0.09, 0.92)
	normal.border_color = Color("#8A5E31")

	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1

	normal.corner_radius_top_left = 7
	normal.corner_radius_top_right = 7
	normal.corner_radius_bottom_left = 7
	normal.corner_radius_bottom_right = 7

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.24, 0.17, 0.11, 0.96)
	hover.border_color = Color("#D39A4A")

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.13, 0.09, 0.06, 0.96)
	pressed.border_color = Color("#B76F2B")

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.14, 0.12, 0.10, 0.55)
	disabled.border_color = Color(0.35, 0.30, 0.24, 0.45)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color("#F2DFC5"))
	button.add_theme_color_override("font_hover_color", Color("#FFE2AB"))
	button.add_theme_color_override("font_pressed_color", Color("#F8D18E"))
	button.add_theme_color_override("font_disabled_color", Color("#7E6B59"))
