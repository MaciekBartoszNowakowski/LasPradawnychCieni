extends CanvasLayer

signal finished

@onready var dim: ColorRect = $Dim
@onready var intro_text: RichTextLabel = $CenterContainer/IntroText
@onready var continue_button: Button = $ContinueButton

const FADE_IN_TIME := 1.0
const BUTTON_FADE_TIME := 0.35
const FADE_OUT_TIME := 0.7

var can_continue := false
var is_finishing := false

var text_to_show: String = """
Na skraju pradawnego lasu leży wieś, która od tygodni nie zaznała spokoju.

Zwierzęta uciekają.
Ludzie znikają bez śladu.
A nocą między drzewami słychać głosy, których nikt nie powinien słyszeć.
"""

func _ready() -> void:
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	_reset_visuals()


func play() -> void:
	show()
	_reset_visuals()
	
	intro_text.text = text_to_show.strip_edges()
	intro_text.visible_characters = -1

	var tween := create_tween()
	tween.tween_property(dim, "modulate:a", 0.98, FADE_IN_TIME)
	tween.parallel().tween_property(intro_text, "modulate:a", 1.0, FADE_IN_TIME)

	await tween.finished

	can_continue = true
	continue_button.disabled = false

	var button_tween := create_tween()
	button_tween.tween_property(continue_button, "modulate:a", 1.0, BUTTON_FADE_TIME)


func _reset_visuals() -> void:
	can_continue = false
	is_finishing = false

	dim.modulate.a = 0.0
	intro_text.modulate.a = 0.0
	intro_text.visible_characters = -1
	intro_text.text = ""

	continue_button.modulate.a = 0.0
	continue_button.disabled = true


func _on_continue_pressed() -> void:
	if not can_continue or is_finishing:
		return

	can_continue = false
	is_finishing = true
	continue_button.disabled = true

	if has_node("/root/UiAudio"):
		UiAudio.play_click()

	var fade_out := create_tween()
	fade_out.tween_property(continue_button, "modulate:a", 0.0, 0.2)
	fade_out.parallel().tween_property(intro_text, "modulate:a", 0.0, FADE_OUT_TIME)
	fade_out.parallel().tween_property(dim, "modulate:a", 0.0, FADE_OUT_TIME)

	await fade_out.finished

	hide()
	finished.emit()
