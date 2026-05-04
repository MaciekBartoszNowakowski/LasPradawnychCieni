extends CanvasLayer

signal finished

@onready var dim: ColorRect = $Dim
@onready var intro_text: RichTextLabel = $CenterContainer/IntroText

var text_to_show: String = """
Na skraju pradawnego lasu leży wieś, która od tygodni nie zaznała spokoju.

Zwierzęta uciekają.
Ludzie znikają bez śladu.
A nocą między drzewami słychać głosy, których nikt nie powinien słyszeć.
"""

func _ready() -> void:
	hide()
	dim.modulate.a = 0.0
	intro_text.modulate.a = 0.0
	intro_text.visible_characters = 0

func play() -> void:
	show()
	
	intro_text.text = text_to_show
	intro_text.visible_characters = 0
	dim.modulate.a = 0.0
	intro_text.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(dim, "modulate:a", 0.98, 1.0)
	tween.parallel().tween_property(intro_text, "modulate:a", 1.0, 1.0)

	await tween.finished
	await _type_text()

	await get_tree().create_timer(3).timeout

	var fade_out := create_tween()
	fade_out.tween_property(intro_text, "modulate:a", 0.0, 0.7)

	await fade_out.finished

	finished.emit()

func _type_text() -> void:
	var total_chars := intro_text.text.length()

	for i in range(total_chars + 1):
		intro_text.visible_characters = i
		await get_tree().create_timer(0.045).timeout
