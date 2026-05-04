extends CanvasLayer

signal finished

@onready var background: TextureRect = $Root/Background
@onready var dark_overlay: ColorRect = $Root/DarkOverlay
@onready var narration_box: PanelContainer = $Root/NarrationBox
@onready var narration_text: RichTextLabel = $Root/NarrationBox/TextWrap/NarrationText
@onready var knock_button: Button = $Root/KnockButton

var can_continue := false

var text_to_show := """
Dom sołtysa stoi na uboczu, większy i solidniejszy od pozostałych chat.

Za okiennicami drga słabe światło.
Po drugiej stronie drzwi słychać ciche, urywane głosy.
"""


func _ready() -> void:
	hide()
	knock_button.pressed.connect(_on_knock_button_pressed)
	_reset_visuals()


func play() -> void:
	show()
	_reset_visuals()

	narration_text.text = text_to_show.strip_edges()
	narration_text.visible_ratio = 0.0
	narration_text.modulate.a = 1.0

	var intro_tween := create_tween()
	intro_tween.tween_property(background, "modulate:a", 1.0, 1.0)
	intro_tween.parallel().tween_property(dark_overlay, "modulate:a", 1.0, 1.0)

	await intro_tween.finished
	await get_tree().create_timer(0.25).timeout

	var box_tween := create_tween()
	box_tween.tween_property(narration_box, "modulate:a", 1.0, 0.45)

	await box_tween.finished
	await get_tree().create_timer(0.15).timeout

	var text_tween := create_tween()
	text_tween.tween_property(narration_text, "visible_ratio", 1.0, 1.45)

	await text_tween.finished
	await get_tree().create_timer(0.25).timeout

	can_continue = true
	knock_button.disabled = false

	var button_tween := create_tween()
	button_tween.tween_property(knock_button, "modulate:a", 1.0, 0.35)


func _reset_visuals() -> void:
	can_continue = false

	background.modulate.a = 0.0
	dark_overlay.modulate.a = 0.0

	narration_box.modulate.a = 0.0
	narration_text.modulate.a = 1.0
	narration_text.visible_ratio = 0.0
	narration_text.text = ""

	knock_button.modulate.a = 0.0
	knock_button.disabled = true


func _on_knock_button_pressed() -> void:
	if not can_continue:
		return

	can_continue = false
	knock_button.disabled = true

	_play_click_sound()

	var button_tween := create_tween()
	button_tween.tween_property(knock_button, "modulate:a", 0.0, 0.25)
	await button_tween.finished

	await get_tree().create_timer(0.15).timeout

	await _fade_replace_text("""
Ktoś milknie po drugiej stronie drzwi.
Po chwili słychać odsuwany rygiel.
""", 1.35)

	await get_tree().create_timer(1.3).timeout

	await _fade_replace_text("""
— Kto tam...?
""", 0.85)

	await get_tree().create_timer(1.0).timeout

	await _fade_replace_text("""
Drużyna pokazuje ogłoszenie zabrane z tablicy.
""", 1.05)

	await get_tree().create_timer(1.15).timeout

	await _fade_replace_text("""
— Więc jednak ktoś przyszedł.

Wejdźcie. I zamknijcie za sobą drzwi.
""", 1.45)

	await get_tree().create_timer(2.1).timeout

	var out_tween := create_tween()
	out_tween.tween_property(narration_box, "modulate:a", 0.0, 0.5)
	out_tween.parallel().tween_property(background, "modulate:a", 0.0, 0.85)
	out_tween.parallel().tween_property(dark_overlay, "modulate:a", 0.0, 0.85)

	await out_tween.finished

	hide()
	finished.emit()


func _fade_replace_text(new_text: String, reveal_time: float = 1.0) -> void:
	var fade_out := create_tween()
	fade_out.tween_property(narration_text, "modulate:a", 0.0, 0.35)

	await fade_out.finished

	narration_text.text = new_text.strip_edges()
	narration_text.visible_ratio = 0.0

	var fade_in := create_tween()
	fade_in.tween_property(narration_text, "modulate:a", 1.0, 0.25)
	fade_in.parallel().tween_property(narration_text, "visible_ratio", 1.0, reveal_time)

	await fade_in.finished


func _play_click_sound() -> void:
	if has_node("/root/UiAudio"):
		UiAudio.play_click()
