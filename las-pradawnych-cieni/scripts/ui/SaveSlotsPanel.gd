class_name SaveSlotsPanel
extends Control

signal slot_selected(slot_index: int)
signal slot_deleted(slot_index: int)
signal panel_closed()

const MODE_LOAD := &"load"
const MODE_SAVE := &"save"

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel
@onready var slots_container: VBoxContainer = $Panel/MarginContainer/VBox/SlotsContainer
@onready var close_button: Button = $Panel/MarginContainer/VBox/CloseButton
@onready var status_label: Label = $Panel/MarginContainer/VBox/StatusLabel

var _mode: StringName = MODE_LOAD
var _slot_buttons: Array[Button] = []
var _slot_subtitles: Array[Label] = []
var _delete_buttons: Array[Button] = []
var _awaiting_overwrite_slot: int = -1
var _awaiting_delete_slot: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_setup_style()
	close_button.pressed.connect(_on_close_pressed)


func is_open() -> bool:
	return visible


func open(mode: StringName) -> void:
	_mode = mode
	_reset_pending_actions()
	status_label.text = ""

	if _mode == MODE_LOAD:
		title_label.text = "Wczytaj grę"
	else:
		title_label.text = "Zapisz grę"

	_refresh_slots()
	_fade_in()


func close_panel() -> void:
	hide()
	panel_closed.emit()


func refresh_slot_row(slot_index: int) -> void:
	_update_slot_row(slot_index)
	status_label.text = "Zapisano w slocie %d." % (slot_index + 1)
	_reset_pending_actions()


func _refresh_slots() -> void:
	for button in _slot_buttons:
		button.queue_free()
	_slot_buttons.clear()
	_slot_subtitles.clear()
	_delete_buttons.clear()

	for child in slots_container.get_children():
		child.queue_free()

	for slot_index in range(SaveGame.SLOT_COUNT):
		_add_slot_row(slot_index)


func _add_slot_row(slot_index: int) -> void:
	var summary: Dictionary = SaveGame.get_slot_summary(slot_index)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	slots_container.add_child(row)

	var info_column := VBoxContainer.new()
	info_column.add_theme_constant_override("separation", 4)
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_column)

	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, 52.0)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = str(summary.get("title", "Slot %d" % (slot_index + 1)))
	MenuPanelStyle.apply_button_style(button)
	button.pressed.connect(_on_slot_pressed.bind(slot_index))
	info_column.add_child(button)
	_slot_buttons.append(button)

	var subtitle := Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", MenuPanelStyle.TEXT_MUTED_COLOR)
	subtitle.add_theme_font_size_override("font_size", 16)
	var font := MenuPanelStyle.get_font()
	if font != null:
		subtitle.add_theme_font_override("font", font)
	info_column.add_child(subtitle)
	_slot_subtitles.append(subtitle)

	var delete_button := Button.new()
	delete_button.custom_minimum_size = Vector2(72.0, 0.0)
	delete_button.size_flags_vertical = Control.SIZE_FILL
	delete_button.focus_mode = Control.FOCUS_NONE
	delete_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	delete_button.text = "Usuń"
	MenuPanelStyle.apply_button_style(delete_button, 18)
	delete_button.pressed.connect(_on_delete_pressed.bind(slot_index))
	row.add_child(delete_button)
	_delete_buttons.append(delete_button)

	_update_slot_row(slot_index)


func _update_slot_row(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slot_buttons.size():
		return

	var summary: Dictionary = SaveGame.get_slot_summary(slot_index)
	var occupied: bool = bool(summary.get("occupied", false))

	_slot_buttons[slot_index].text = str(summary.get("title", "Slot %d" % (slot_index + 1)))
	_slot_subtitles[slot_index].text = str(summary.get("subtitle", "Pusty"))

	if _mode == MODE_LOAD:
		_slot_buttons[slot_index].disabled = not occupied
	else:
		_slot_buttons[slot_index].disabled = false

	_delete_buttons[slot_index].disabled = not occupied
	_delete_buttons[slot_index].visible = occupied


func _on_slot_pressed(slot_index: int) -> void:
	MenuPanelStyle.play_click()
	_reset_pending_actions(false)

	if _mode == MODE_LOAD:
		if not SaveGame.has_slot(slot_index):
			return
		slot_selected.emit(slot_index)
		close_panel()
		return

	if SaveGame.has_slot(slot_index) and _awaiting_overwrite_slot != slot_index:
		_awaiting_overwrite_slot = slot_index
		status_label.text = "Kliknij ponownie slot %d, aby nadpisać zapis." % (slot_index + 1)
		return

	_awaiting_overwrite_slot = -1
	slot_selected.emit(slot_index)


func _on_delete_pressed(slot_index: int) -> void:
	MenuPanelStyle.play_click()

	if not SaveGame.has_slot(slot_index):
		return

	_awaiting_overwrite_slot = -1

	if _awaiting_delete_slot == slot_index:
		_awaiting_delete_slot = -1
		if not SaveGame.delete_slot(slot_index):
			status_label.text = "Nie udało się usunąć zapisu ze slotu %d." % (slot_index + 1)
			return
		_update_slot_row(slot_index)
		status_label.text = "Usunięto zapis ze slotu %d." % (slot_index + 1)
		slot_deleted.emit(slot_index)
		return

	_awaiting_delete_slot = slot_index
	status_label.text = "Kliknij ponownie Usuń przy slocie %d, aby potwierdzić." % (slot_index + 1)


func _on_close_pressed() -> void:
	MenuPanelStyle.play_click()
	close_panel()


func _reset_pending_actions(clear_status := true) -> void:
	_awaiting_overwrite_slot = -1
	_awaiting_delete_slot = -1
	if clear_status:
		status_label.text = ""


func _setup_style() -> void:
	panel.add_theme_stylebox_override("panel", MenuPanelStyle.create_panel_style())
	MenuPanelStyle.apply_button_style(close_button)
	close_button.text = "Anuluj"
	MenuPanelStyle.apply_title_label(title_label)
	MenuPanelStyle.apply_muted_label(status_label)


func _fade_in() -> void:
	show()
	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.25)
