extends Control
class_name Rest

const MAP_SCENE_PATH := "res://scenes/map/Map.tscn"
const NOTICE_FONT_PATH := "res://assets/ui/fonts/IMFellEnglishSC-Regular.ttf"

const NOTICE_TEXT_COLOR := Color(0.8666667, 0.827451, 0.7372549, 1.0)
const NOTICE_TEXT_HOVER_COLOR := Color(0.9411765, 0.90588236, 0.8156863, 1.0)
const NOTICE_TEXT_PRESSED_COLOR := Color(0.7607843, 0.6901961, 0.52156866, 1.0)
const NOTICE_TEXT_DISABLED_COLOR := Color(0.5529412, 0.52156866, 0.46666667, 1.0)
const NOTICE_OUTLINE_COLOR := Color(0.09411765, 0.078431375, 0.07058824, 1.0)

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
	"UILayer/UIRoot/ActionPanel/MarginContainer/VBoxContainer/MainActionsRow/LeaveButton",
	"UILayer/UIRoot/ActionPanel/MarginContainer/VBoxContainer/LeaveButton",
	"UIRoot/ActionPanel/MarginContainer/VBoxContainer/MainActionsRow/LeaveButton",
	"UIRoot/ActionPanel/MarginContainer/VBoxContainer/LeaveButton",
	"ActionPanel/MarginContainer/VBoxContainer/MainActionsRow/LeaveButton",
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

	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if top_bar.has_method("setup"):
		top_bar.setup(
			"Leśne Obozowisko",
			"Odpocznij przed dalszą wyprawą"
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

	# ActionPanel ma być lustrzanym odpowiednikiem ControlsPanel:
	# ta sama wysokość, szerokość i dolny margines, tylko po prawej stronie.
	var min_size := action_panel.get_combined_minimum_size()
	var panel_width: float = max(ACTION_PANEL_WIDTH, min_size.x)
	var panel_height: float = max(ACTION_PANEL_HEIGHT, min_size.y)

	action_panel.custom_minimum_size = Vector2(panel_width, panel_height)

	action_panel.anchor_left = 1.0
	action_panel.anchor_top = 1.0
	action_panel.anchor_right = 1.0
	action_panel.anchor_bottom = 1.0

	action_panel.offset_left = -panel_width - ACTION_PANEL_SIDE_MARGIN
	action_panel.offset_top = -panel_height - ACTION_PANEL_BOTTOM_MARGIN
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
		_apply_panel_label_style(action_panel)

	if controls_panel != null:
		controls_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_apply_controls_panel_style(controls_panel)
		_apply_panel_label_style(controls_panel)

	if character_panel != null:
		character_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_apply_character_panel_style(character_panel)
		_apply_panel_label_style(character_panel)


func _setup_buttons() -> void:
	if rest_button != null:
		rest_button.pressed.connect(_on_rest_button_pressed)
		rest_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_button_style(rest_button)

	if prepare_button != null:
		prepare_button.visible = false
		prepare_button.disabled = true
		prepare_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_button_style(prepare_button)

	if leave_button != null:
		leave_button.pressed.connect(_on_leave_button_pressed)
		leave_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		title_label.add_theme_color_override("font_color", NOTICE_TEXT_COLOR)

	var hint_label := controls_panel.find_child("HintLabel", true, false) as Label

	if hint_label != null:
		hint_label.text = "Kliknij bohatera przy ognisku, aby zobaczyć jego statystyki."
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.add_theme_color_override("font_color", Color(0.78, 0.69, 0.58, 1.0))


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
	
	GameState.heal_team_missing_percent(0.4)

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
	MapState.complete_selected_map_node()
	
	if ResourceLoader.exists(MAP_SCENE_PATH):
		SceneTransition.change_scene(MAP_SCENE_PATH)
	else:
		print("Brak sceny mapy pod ścieżką: ", MAP_SCENE_PATH)


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
		"Szybkość: %d\nInicjatywa: %d\nZręczność: %d\nSiła: %d\nPancerz: %d" % [
			character.speed,
			character.initiative,
			character.agility,
			character.strength,
			character.armour
		]
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
		"Rycerz":
			return "Wojownik"
		"Łotrzyk":
			return "Łotrzyk"
		"Łucznik":
			return "Łowca"
		_:
			return character.character_name


func _get_character_class_name(character: Player) -> String:
	match character.character_name:
		"Rycerz":
			return "Rycerz"
		"Łotrzyk":
			return "Łotrzyk"
		"Łucznik":
			return "Łucznik"
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

	# Selection / hover ring behind the portrait
	if is_selected:
		canvas.draw_rect(
			rect.grow(-4.0),
			Color(1.0, 0.48, 0.14, 0.18),
			true
		)
		canvas.draw_rect(
			rect.grow(-4.0),
			Color("#D48A32"),
			false,
			3.0
		)
	elif is_hovered:
		canvas.draw_rect(
			rect.grow(-4.0),
			Color(1.0, 0.48, 0.14, 0.10),
			true
		)

	# Portrait image — fills top portion of the slot
	var portrait_height := rect.size.y - 58.0
	var portrait_rect := Rect2(rect.position, Vector2(rect.size.x, portrait_height))
	var portrait := character.get_portrait()
	if portrait != null:
		# Scale to fit while keeping aspect ratio, centered
		var img_size := Vector2(portrait.get_width(), portrait.get_height())
		var scale := minf(portrait_rect.size.x / img_size.x, portrait_rect.size.y / img_size.y)
		var scaled_size := img_size * scale
		var offset := (portrait_rect.size - scaled_size) * 0.5
		canvas.draw_texture_rect(
			portrait,
			Rect2(portrait_rect.position + offset, scaled_size),
			false
		)
	else:
		# Fallback: draw colored body silhouette
		var body_color := character.color.lerp(Color.BLACK, 0.30)
		var light_color := character.color.lerp(Color.WHITE, 0.22)
		var dark_color := character.color.lerp(Color.BLACK, 0.58)
		var pc := center + Vector2(0.0, -20.0)
		canvas.draw_line(pc + Vector2(-16.0, 44.0), pc + Vector2(-27.0, 84.0), dark_color, 8.0)
		canvas.draw_line(pc + Vector2(16.0, 44.0), pc + Vector2(27.0, 84.0), dark_color, 8.0)
		var body_points := PackedVector2Array([
			pc + Vector2(-25.0, -18.0), pc + Vector2(25.0, -18.0),
			pc + Vector2(32.0, 48.0), pc + Vector2(-32.0, 48.0)
		])
		canvas.draw_colored_polygon(body_points, body_color)
		canvas.draw_line(pc + Vector2(-20.0, -5.0), pc + Vector2(-45.0, 31.0), dark_color, 7.0)
		canvas.draw_line(pc + Vector2(20.0, -5.0), pc + Vector2(45.0, 31.0), dark_color, 7.0)
		canvas.draw_circle(pc + Vector2(0.0, -45.0), 19.0, body_color)
		canvas.draw_circle(pc + Vector2(7.0, -49.0), 5.8, light_color)

	# Name + HP bar below the portrait
	canvas.draw_rect(
		Rect2(rect.position.x, rect.position.y + portrait_height, rect.size.x, 58.0),
		Color(0.0, 0.0, 0.0, 0.40),
		true
	)

	var font := canvas.get_theme_default_font()
	var text_y := rect.position.y + portrait_height

	if font != null:
		canvas.draw_string(
			font,
			Vector2(rect.position.x, text_y + 18.0),
			_get_character_display_name(character),
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			17,
			Color("#F2DFC5")
		)

	var hp_bar_rect := Rect2(
		rect.position.x + rect.size.x * 0.10,
		text_y + 28.0,
		rect.size.x * 0.80,
		11.0
	)
	_draw_hp_bar(canvas, hp_bar_rect, character.current_life, character.max_life)

	if font != null:
		canvas.draw_string(
			font,
			Vector2(rect.position.x, text_y + 54.0),
			"%d / %d HP" % [character.current_life, character.max_life],
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			13,
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
	panel.add_theme_stylebox_override("panel", _create_notice_panel_style())


func _apply_controls_panel_style(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _create_notice_panel_style())


func _apply_character_panel_style(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _create_notice_panel_style())


func _create_notice_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	# Ten sam kierunek wizualny co NoticeBoardOverlay: bardzo ciemne,
	# lekko przezroczyste tło i subtelna jasna ramka.
	style.bg_color = Color(0.03529412, 0.02745098, 0.01960784, 0.70)
	style.border_color = Color(0.84705883, 0.8, 0.68235296, 0.32)

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5

	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 8

	return style


func _apply_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()

	normal.set_content_margin(SIDE_LEFT, 18.0)
	normal.set_content_margin(SIDE_TOP, 10.0)
	normal.set_content_margin(SIDE_RIGHT, 18.0)
	normal.set_content_margin(SIDE_BOTTOM, 10.0)
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
	button.add_theme_font_size_override("font_size", 24)

	var notice_font := _get_notice_font()

	if notice_font != null:
		button.add_theme_font_override("font", notice_font)


func _apply_panel_label_style(panel: Control) -> void:
	var notice_font := _get_notice_font()
	var labels := panel.find_children("*", "Label", true, false)

	for node in labels:
		var label := node as Label

		if label == null:
			continue

		var is_title := str(label.name).contains("Title") or str(label.name).contains("Name")
		var label_color := NOTICE_TEXT_COLOR if is_title else Color(0.78, 0.69, 0.58, 1.0)
		var label_size := 24 if is_title else 18

		label.add_theme_color_override("font_color", label_color)
		label.add_theme_color_override("font_outline_color", NOTICE_OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_font_size_override("font_size", label_size)

		if notice_font != null:
			label.add_theme_font_override("font", notice_font)


func _get_notice_font() -> Font:
	if ResourceLoader.exists(NOTICE_FONT_PATH):
		return load(NOTICE_FONT_PATH) as Font

	return null
