extends CanvasLayer

signal finished

@onready var root: Control = $Root
@onready var background: TextureRect = $Root/Background
@onready var dark_overlay: ColorRect = $Root/DarkOverlay
@onready var dialogue_panel: Panel = $Root/DialoguePanel
@onready var speaker_label: Label = $Root/DialoguePanel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $Root/DialoguePanel/MarginContainer/VBoxContainer/DialogueText
@onready var continue_button: Button = $Root/DialoguePanel/MarginContainer/VBoxContainer/ContinueButton

const CHAR_DELAY := 0.026
const PANEL_FADE_TIME := 0.45
const BACKGROUND_FADE_TIME := 0.9

var _step_index := -1
var _is_typing := false
var _can_continue := false
var _current_full_text := ""
var _current_button_text := "Dalej"

var dialogue_steps := [
	{
		"speaker": "Narrator",
		"text": "Drzwi zamykają się za drużyną ciężkim stuknięciem.\nW izbie pachnie dymem, wilgotnym drewnem i gorzkimi ziołami."
	},
	{
		"speaker": "Sołtys",
		"text": "Dobrze, że przyszliście.\nNie zostało nam wielu ludzi, którzy mieliby odwagę odpowiedzieć na ogłoszenie."
	},
	{
		"speaker": "Sołtys",
		"text": "Od tygodni coś dzieje się w lesie.\nZwierzęta uciekają, ludzie znikają, a nocą słychać głosy między drzewami."
	},
	{
		"speaker": "Sołtys",
		"text": "Dam wam mapę, na której znajdziecie kilka ścieżek.\nNie każda walka będzie konieczna, ale każda decyzja może was kosztować."
	},
	{
		"speaker": "Drużyna",
		"text": "Co dokładnie mamy zrobić?"
	},
	{
		"speaker": "Sołtys",
		"text": "Waszym zadaniem jest odkrycie źródła zła i zniszczenie go.\nA jeśli usłyszycie w lesie głos kogoś, kogo znacie… nie odpowiadajcie."
	},
	{
		"speaker": "Narrator",
		"text": "Sołtys przesuwa mapę w waszą stronę.\nZa oknem las milczy, jakby czekał.",
		"button_text": "Wyrusz"
	}
]


func _ready() -> void:
	hide()

	background.modulate.a = 0.0
	dark_overlay.modulate.a = 0.0
	dialogue_panel.modulate.a = 0.0

	dialogue_text.text = ""
	dialogue_text.visible_characters = 0

	continue_button.visible = true
	continue_button.disabled = true
	continue_button.modulate.a = 0.0
	continue_button.pressed.connect(_on_continue_pressed)


func play() -> void:
	show()

	_step_index = -1
	_is_typing = false
	_can_continue = false
	_current_full_text = ""
	_current_button_text = "Dalej"

	background.modulate.a = 0.0
	dark_overlay.modulate.a = 0.0
	dialogue_panel.modulate.a = 0.0

	speaker_label.text = ""
	dialogue_text.text = ""
	dialogue_text.visible_characters = 0

	_hide_continue_button()

	var intro_tween := create_tween()
	intro_tween.tween_property(background, "modulate:a", 1.0, BACKGROUND_FADE_TIME)
	intro_tween.parallel().tween_property(dark_overlay, "modulate:a", 1.0, BACKGROUND_FADE_TIME)

	await intro_tween.finished

	var panel_tween := create_tween()
	panel_tween.tween_property(dialogue_panel, "modulate:a", 1.0, PANEL_FADE_TIME)

	await panel_tween.finished

	_next_step()


func _next_step() -> void:
	_step_index += 1

	if _step_index >= dialogue_steps.size():
		_finish_dialogue()
		return

	await _show_step(dialogue_steps[_step_index])


func _show_step(step: Dictionary) -> void:
	_can_continue = false
	_hide_continue_button()

	_current_button_text = str(step.get("button_text", "Dalej"))

	speaker_label.text = str(step.get("speaker", ""))
	await _type_text(str(step.get("text", "")))

	_show_continue_button()


func _type_text(text: String) -> void:
	_is_typing = true
	_current_full_text = text

	dialogue_text.text = text
	dialogue_text.visible_characters = 0

	var total_chars := dialogue_text.get_total_character_count()

	for i in range(total_chars + 1):
		if not _is_typing:
			dialogue_text.visible_characters = -1
			return

		dialogue_text.visible_characters = i
		await get_tree().create_timer(CHAR_DELAY).timeout

	_is_typing = false
	dialogue_text.visible_characters = -1


func _show_continue_button() -> void:
	_can_continue = true

	continue_button.text = _current_button_text
	continue_button.visible = true
	continue_button.disabled = false

	var tween := create_tween()
	tween.tween_property(continue_button, "modulate:a", 1.0, 0.2)


func _hide_continue_button() -> void:
	continue_button.visible = true
	continue_button.disabled = true
	continue_button.modulate.a = 0.0


func _on_continue_pressed() -> void:
	if _is_typing:
		_is_typing = false
		dialogue_text.visible_characters = -1
		return

	if not _can_continue:
		return

	_can_continue = false
	UiAudio.play_click()

	_next_step()


func _finish_dialogue() -> void:
	_can_continue = false
	_hide_continue_button()

	var out_tween := create_tween()
	out_tween.tween_property(dialogue_panel, "modulate:a", 0.0, 0.45)
	out_tween.parallel().tween_property(background, "modulate:a", 0.0, 0.75)
	out_tween.parallel().tween_property(dark_overlay, "modulate:a", 0.0, 0.75)

	await out_tween.finished

	hide()
	finished.emit()
