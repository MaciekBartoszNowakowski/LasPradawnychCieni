extends Control
class_name Shop

const MAP_SCENE_PATH := "res://scenes/map/Map.tscn"
const NOTICE_FONT_PATH := "res://assets/ui/fonts/IMFellEnglishSC-Regular.ttf"
const FALLBACK_ICON_PATH := "res://assets/ui/map/nodes/shop_base_256.png"
const SLOT_COUNT := 12

const NOTICE_TEXT_COLOR := Color(0.8666667, 0.827451, 0.7372549, 1.0)
const NOTICE_TEXT_HOVER_COLOR := Color(0.9411765, 0.90588236, 0.8156863, 1.0)
const NOTICE_TEXT_PRESSED_COLOR := Color(0.7607843, 0.6901961, 0.52156866, 1.0)
const NOTICE_TEXT_DISABLED_COLOR := Color(0.5529412, 0.52156866, 0.46666667, 1.0)
const NOTICE_OUTLINE_COLOR := Color(0.09411765, 0.078431375, 0.07058824, 1.0)
const SLOT_SOLD_OUT_TWEEN_DURATION := 0.12

@onready var top_bar: Control = $UILayer/UIRoot/TopBar
@onready var merchant_panel: PanelContainer = $UILayer/UIRoot/ContentMargin/MainRoot/LeftPanelRoot/MerchantPanel
@onready var status_panel: PanelContainer = $UILayer/UIRoot/ContentMargin/MainRoot/LeftPanelRoot/StatusPanel
@onready var party_panel: PanelContainer = $UILayer/UIRoot/ContentMargin/MainRoot/LeftPanelRoot/PartyPanel
@onready var bottom_action_root: PanelContainer = $UILayer/UIRoot/ContentMargin/MainRoot/BottomActionRoot
@onready var overlay_panel: PanelContainer = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel
@onready var slots_grid_panel: PanelContainer = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/SlotsGridPanel
@onready var details_panel: PanelContainer = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/DetailsPanel

@onready var open_slots_button: Button = $UILayer/UIRoot/ContentMargin/MainRoot/BottomActionRoot/MarginContainer/ActionsRow/OpenSlotsButton
@onready var leave_button: Button = $UILayer/UIRoot/ContentMargin/MainRoot/BottomActionRoot/MarginContainer/ActionsRow/LeaveButton
@onready var status_label: Label = $UILayer/UIRoot/ContentMargin/MainRoot/LeftPanelRoot/StatusPanel/MarginContainer/StatusVBox/StatusLabel
@onready var party_info_label: Label = $UILayer/UIRoot/ContentMargin/MainRoot/LeftPanelRoot/PartyPanel/MarginContainer/PartyVBox/PartyInfoLabel
@onready var slots_overlay_root: Control = $OverlayLayer/SlotsOverlayRoot
@onready var close_slots_button: Button = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/HeaderRow/CloseSlotsButton
@onready var slots_grid: GridContainer = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/SlotsGridPanel/MarginContainer/SlotsGrid
@onready var detail_item_icon: TextureRect = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/DetailsPanel/MarginContainer/DetailsVBox/DetailItemIcon
@onready var detail_item_name_label: Label = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/DetailsPanel/MarginContainer/DetailsVBox/DetailItemNameLabel
@onready var detail_item_type_label: Label = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/DetailsPanel/MarginContainer/DetailsVBox/DetailItemTypeLabel
@onready var detail_item_price_label: Label = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/DetailsPanel/MarginContainer/DetailsVBox/DetailItemPriceLabel
@onready var detail_item_description_label: Label = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/DetailsPanel/MarginContainer/DetailsVBox/DetailItemDescriptionLabel
@onready var target_label: Label = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/DetailsPanel/MarginContainer/DetailsVBox/TargetLabel
@onready var hero_target_buttons: HBoxContainer = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/DetailsPanel/MarginContainer/DetailsVBox/HeroTargetButtons
@onready var buy_button: Button = $OverlayLayer/SlotsOverlayRoot/OverlayCenter/OverlayPanel/MarginContainer/OverlayVBox/OverlayBody/DetailsPanel/MarginContainer/DetailsVBox/BuyButton

var stock_entries: Array[ShopStockEntry] = []
var selected_item_index: int = -1
var selected_hero_target_index: int = -1
var slot_buttons: Array[Button] = []
var hero_target_select_buttons: Array[Button] = []
var slot_normal_styles: Dictionary = {}
var slot_hover_styles: Dictionary = {}


func _ready() -> void:
	GameState.ensure_team_exists()

	_setup_top_bar()
	_setup_visual_style()
	_setup_buttons()
	_create_slot_buttons()
	_load_catalog()
	_refresh_party_info()
	_refresh_selection_ui()


func _setup_top_bar() -> void:
	if top_bar == null:
		return

	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if top_bar.has_method("setup"):
		top_bar.setup(
			"Leśny Sklep",
			"Przygotuj drużynę na dalszą drogę"
		)


func _setup_visual_style() -> void:
	for panel in [merchant_panel, status_panel, party_panel, bottom_action_root, overlay_panel, slots_grid_panel, details_panel]:
		if panel == null:
			continue

		panel.add_theme_stylebox_override("panel", _create_notice_panel_style())
		_apply_panel_label_style(panel)

	if open_slots_button != null:
		_apply_button_style(open_slots_button)
	if buy_button != null:
		_apply_button_style(buy_button)
	if leave_button != null:
		_apply_button_style(leave_button)
	if close_slots_button != null:
		_apply_button_style(close_slots_button)
		close_slots_button.custom_minimum_size = Vector2(44.0, 42.0)


func _setup_buttons() -> void:
	if open_slots_button != null and not open_slots_button.pressed.is_connected(_on_open_slots_pressed):
		open_slots_button.pressed.connect(_on_open_slots_pressed)

	if close_slots_button != null and not close_slots_button.pressed.is_connected(_on_close_slots_pressed):
		close_slots_button.pressed.connect(_on_close_slots_pressed)

	if buy_button != null and not buy_button.pressed.is_connected(_on_buy_button_pressed):
		buy_button.pressed.connect(_on_buy_button_pressed)

	if leave_button != null and not leave_button.pressed.is_connected(_on_leave_button_pressed):
		leave_button.pressed.connect(_on_leave_button_pressed)


func _create_slot_buttons() -> void:
	slot_buttons.clear()

	for i in range(SLOT_COUNT):
		var slot_button := Button.new()
		slot_button.custom_minimum_size = Vector2(132.0, 132.0)
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot_button.text = "Pusty slot"
		slot_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_button.expand_icon = true
		slot_button.clip_text = true
		slot_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		slot_button.focus_mode = Control.FOCUS_NONE
		slot_button.pressed.connect(_on_slot_button_pressed.bind(i))
		_apply_slot_button_style(slot_button)
		slot_buttons.append(slot_button)
		slots_grid.add_child(slot_button)


func _load_catalog() -> void:
	stock_entries = ShopCatalog.get_stock_entries()
	_refresh_all_slots()
	_select_first_available_slot()


func _refresh_all_slots() -> void:
	for i in range(slot_buttons.size()):
		var slot_button: Button = slot_buttons[i]
		_apply_slot_visual(slot_button, i)


func _apply_slot_visual(slot_button: Button, index: int) -> void:
	if index >= stock_entries.size():
		_set_empty_slot(slot_button)
		return

	var entry: ShopStockEntry = stock_entries[index]
	if entry == null or entry.item == null or entry.quantity <= 0:
		_set_empty_slot(slot_button)
		return

	var item: ItemConfig = entry.item
	slot_button.disabled = false
	slot_button.text = "%s\n%d zł\nx%d" % [_get_short_name(item), item.price, entry.quantity]
	slot_button.icon = _load_icon(item)
	slot_button.tooltip_text = "%s\nNa stanie: %d szt." % [item.description, entry.quantity]
	slot_button.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _set_empty_slot(slot_button: Button) -> void:
	slot_button.text = "Pusty slot"
	slot_button.icon = null
	slot_button.tooltip_text = ""
	slot_button.disabled = true
	slot_button.modulate = Color(1.0, 1.0, 1.0, 0.58)


func _get_stock_entry(index: int) -> ShopStockEntry:
	if index < 0 or index >= stock_entries.size():
		return null
	return stock_entries[index]


func _slot_has_stock(index: int) -> bool:
	var entry := _get_stock_entry(index)
	return entry != null and entry.item != null and entry.quantity > 0


func _select_first_available_slot() -> void:
	selected_item_index = -1
	for i in range(stock_entries.size()):
		if _slot_has_stock(i):
			selected_item_index = i
			return


func _select_next_available_slot() -> void:
	if _slot_has_stock(selected_item_index):
		return

	for i in range(selected_item_index + 1, stock_entries.size()):
		if _slot_has_stock(i):
			selected_item_index = i
			return

	for i in range(selected_item_index):
		if _slot_has_stock(i):
			selected_item_index = i
			return

	selected_item_index = -1


func _on_slot_button_pressed(index: int) -> void:
	if not _slot_has_stock(index):
		return

	UiAudio.play_click()
	selected_item_index = index
	_refresh_selection_ui()


func _on_open_slots_pressed() -> void:
	UiAudio.play_click()
	slots_overlay_root.visible = true
	_refresh_selection_ui()


func _on_close_slots_pressed() -> void:
	UiAudio.play_click()
	slots_overlay_root.visible = false


func _on_buy_button_pressed() -> void:
	UiAudio.play_click()

	if not _slot_has_stock(selected_item_index):
		_set_status("Wybierz przedmiot.")
		return

	var entry: ShopStockEntry = _get_stock_entry(selected_item_index)
	var selected_item: ItemConfig = entry.item
	var target_index: int = -1

	if selected_item.item_kind == ItemConfig.ItemKind.HEAL_SINGLE:
		target_index = selected_hero_target_index

	var result: Dictionary = GameState.buy_shop_item(selected_item, target_index)
	_set_status(str(result.get("message", "Brak informacji o zakupie.")))

	if not bool(result.get("success", false)):
		_refresh_selection_ui()
		return

	var purchased_slot_index := selected_item_index
	var was_last_piece := entry.quantity == 1
	entry.quantity -= 1

	if was_last_piece:
		_play_slot_sold_out_tween(purchased_slot_index, func() -> void:
			_finish_purchase_refresh()
		)
	else:
		_finish_purchase_refresh()


func _finish_purchase_refresh() -> void:
	_refresh_all_slots()
	_select_next_available_slot()
	_refresh_party_info()
	_refresh_selection_ui()


func _play_slot_sold_out_tween(slot_index: int, on_finished: Callable) -> void:
	if slot_index < 0 or slot_index >= slot_buttons.size():
		on_finished.call()
		return

	var slot_button: Button = slot_buttons[slot_index]
	slot_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var tween := create_tween()
	tween.tween_property(
		slot_button,
		"modulate",
		Color(0.45, 0.4, 0.35, 0.35),
		SLOT_SOLD_OUT_TWEEN_DURATION
	)
	tween.tween_callback(on_finished)


func _on_leave_button_pressed() -> void:
	UiAudio.play_click()

	if ResourceLoader.exists(MAP_SCENE_PATH):
		SceneTransition.change_scene(MAP_SCENE_PATH)


func _refresh_selection_ui() -> void:
	if not _slot_has_stock(selected_item_index):
		detail_item_icon.texture = null
		detail_item_name_label.text = "Wybierz przedmiot"
		detail_item_type_label.text = "-"
		detail_item_price_label.text = "Cena: -"
		detail_item_description_label.text = "Brak przedmiotów na stanie."
		_set_target_section_enabled(false)
		buy_button.text = "Kup za - zł"
		buy_button.disabled = true
		_refresh_slot_highlight()
		return

	var entry: ShopStockEntry = _get_stock_entry(selected_item_index)
	var item: ItemConfig = entry.item
	detail_item_icon.texture = _load_icon(item)
	detail_item_name_label.text = item.display_name
	detail_item_type_label.text = _get_item_kind_label(item.item_kind)
	detail_item_price_label.text = "Cena: %d zł · Na stanie: %d szt." % [item.price, entry.quantity]
	detail_item_description_label.text = item.description
	buy_button.text = "Kup za %d zł" % item.price

	_refresh_hero_target(item)
	_refresh_buy_availability(item, entry.quantity)
	_refresh_slot_highlight()


func _refresh_hero_target(item: ItemConfig) -> void:
	var team: Team = GameState.player_team
	var needs_target: bool = item.item_kind == ItemConfig.ItemKind.HEAL_SINGLE

	_set_target_section_enabled(needs_target)

	if not needs_target:
		selected_hero_target_index = -1
		for child in hero_target_buttons.get_children():
			child.queue_free()
		hero_target_select_buttons.clear()
		return

	selected_hero_target_index = -1
	for child in hero_target_buttons.get_children():
		child.queue_free()
	hero_target_select_buttons.clear()

	if team == null:
		return

	for i in range(team.characters.size()):
		var hero: Player = team.characters[i]
		if hero == null:
			continue
		var hero_button := _create_hero_target_button(hero, i)
		hero_target_select_buttons.append(hero_button)
		hero_target_buttons.add_child(hero_button)

	if not hero_target_select_buttons.is_empty():
		selected_hero_target_index = 0
		_update_hero_target_button_styles()


func _refresh_buy_availability(item: ItemConfig, stock_quantity: int = 1) -> void:
	var team: Team = GameState.player_team
	var can_buy := true
	var reason := ""

	if stock_quantity <= 0:
		can_buy = false
		reason = "Wyprzedane."
	elif team == null:
		can_buy = false
		reason = "Brak drużyny."
	elif team.money < item.price:
		can_buy = false
		reason = "Brak wystarczającej ilości złota."
	elif item.item_kind == ItemConfig.ItemKind.HEAL_TEAM:
		var missing_total := 0
		for hero: Player in team.characters:
			if hero != null:
				missing_total += max(hero.max_life - hero.current_life, 0)
		if missing_total <= 0:
			can_buy = false
			reason = "Drużyna ma pełne HP."
	elif item.item_kind == ItemConfig.ItemKind.HEAL_SINGLE:
		if hero_target_select_buttons.is_empty():
			can_buy = false
			reason = "Wybierz bohatera do leczenia."
		else:
			var hero_index: int = selected_hero_target_index
			if hero_index < 0 or hero_index >= team.characters.size():
				can_buy = false
				reason = "Wybierz bohatera do leczenia."
			else:
				var target_hero: Player = team.characters[hero_index]
				if target_hero == null or target_hero.current_life >= target_hero.max_life:
					can_buy = false
					reason = "Bohater ma pełne HP."

	buy_button.disabled = not can_buy
	if not can_buy and not reason.is_empty():
		_set_status(reason)


func _create_hero_target_button(hero: Player, index: int) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 34)
	button.focus_mode = Control.FOCUS_NONE
	button.text = _get_short_polish_hero_label(hero)
	button.clip_text = true
	button.tooltip_text = "%s (%d/%d HP)" % [_display_name(hero), hero.current_life, hero.max_life]
	_apply_button_style(button)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(func() -> void:
		selected_hero_target_index = index
		_update_hero_target_button_styles()
		if _slot_has_stock(selected_item_index):
			var entry := _get_stock_entry(selected_item_index)
			_refresh_buy_availability(entry.item, entry.quantity)
	)
	return button


func _update_hero_target_button_styles() -> void:
	for i in range(hero_target_select_buttons.size()):
		var button: Button = hero_target_select_buttons[i]
		var is_selected := i == selected_hero_target_index
		button.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_selected else Color(1.0, 1.0, 1.0, 0.62)


func _set_target_section_enabled(enabled: bool) -> void:
	target_label.modulate = Color(1.0, 1.0, 1.0, 1.0) if enabled else Color(1.0, 1.0, 1.0, 0.35)
	hero_target_buttons.modulate = Color(1.0, 1.0, 1.0, 1.0) if enabled else Color(1.0, 1.0, 1.0, 0.35)
	hero_target_buttons.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE


func _get_hero_symbol(hero: Player) -> String:
	match hero.character_name:
		"Knight":
			return "[K]"
		"Rogue":
			return "[R]"
		"Archer":
			return "[A]"
		_:
			return "[?]"


func _get_short_polish_hero_label(hero: Player) -> String:
	match hero.character_name:
		"Knight":
			return "Wojownik"
		"Rogue":
			return "Łotrzyk"
		"Archer":
			return "Łowca"
		_:
			return _display_name(hero)


func _refresh_slot_highlight() -> void:
	for i in range(slot_buttons.size()):
		var slot_button: Button = slot_buttons[i]
		var has_stock := _slot_has_stock(i)
		var is_selected := has_stock and i == selected_item_index
		var style_key := slot_button.get_instance_id()
		var selected_style: StyleBox = slot_hover_styles.get(style_key, null)
		var default_style: StyleBox = slot_normal_styles.get(style_key, null)
		if not has_stock:
			if default_style != null:
				slot_button.add_theme_stylebox_override("normal", default_style)
			slot_button.modulate = Color(1.0, 1.0, 1.0, 0.58)
		elif is_selected and selected_style != null:
			slot_button.add_theme_stylebox_override("normal", selected_style)
			slot_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		elif default_style != null:
			slot_button.add_theme_stylebox_override("normal", default_style)
			slot_button.modulate = Color(1.0, 1.0, 1.0, 0.58)


func _refresh_party_info() -> void:
	var team: Team = GameState.player_team
	if team == null:
		party_info_label.text = "Brak drużyny."
		return

	var lines: Array[String] = []
	for hero: Player in team.characters:
		if hero == null:
			continue
		lines.append("%s: %d / %d HP" % [_display_name(hero), hero.current_life, hero.max_life])

	lines.append("")
	lines.append("Przedmioty kupione: %d" % team.inventory_item_ids.size())

	party_info_label.text = "\n".join(lines)


func _set_status(text: String) -> void:
	status_label.text = text


func _get_short_name(item: ItemConfig) -> String:
	if not item.short_name.is_empty():
		return item.short_name
	return item.display_name


func _get_item_kind_label(item_kind: ItemConfig.ItemKind) -> String:
	match item_kind:
		ItemConfig.ItemKind.HEAL_SINGLE:
			return "Typ: Leczenie bohatera"
		ItemConfig.ItemKind.HEAL_TEAM:
			return "Typ: Leczenie drużyny"
		ItemConfig.ItemKind.FUTURE_EQUIPMENT:
			return "Typ: Przedmiot przyszły"
		_:
			return "Typ: Nieznany"


func _load_icon(item: ItemConfig) -> Texture2D:
	var icon_path := item.icon_path
	if icon_path.is_empty():
		icon_path = FALLBACK_ICON_PATH

	if ResourceLoader.exists(icon_path):
		return load(icon_path) as Texture2D

	if ResourceLoader.exists(FALLBACK_ICON_PATH):
		return load(FALLBACK_ICON_PATH) as Texture2D

	return null


func _display_name(character: Player) -> String:
	match character.character_name:
		"Knight":
			return "Wojownik"
		"Rogue":
			return "Łotrzyk"
		"Archer":
			return "Łowca"
		_:
			return character.character_name


func _create_notice_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
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
	button.add_theme_font_size_override("font_size", 22)

	var notice_font := _get_notice_font()
	if notice_font != null:
		button.add_theme_font_override("font", notice_font)


func _apply_slot_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_content_margin(SIDE_LEFT, 10.0)
	normal.set_content_margin(SIDE_TOP, 10.0)
	normal.set_content_margin(SIDE_RIGHT, 10.0)
	normal.set_content_margin(SIDE_BOTTOM, 10.0)
	normal.bg_color = Color(0.04, 0.03, 0.02, 0.72)
	normal.border_color = Color(0.82, 0.74, 0.60, 0.26)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.13, 0.09, 0.05, 0.80)
	hover.border_color = Color(0.92, 0.86, 0.72, 0.60)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("disabled", normal)
	slot_normal_styles[button.get_instance_id()] = normal
	slot_hover_styles[button.get_instance_id()] = hover
	button.add_theme_color_override("font_color", NOTICE_TEXT_COLOR)
	button.add_theme_color_override("font_outline_color", NOTICE_OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_font_size_override("font_size", 16)

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
