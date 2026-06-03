extends CanvasLayer

signal finished

@onready var background: TextureRect = $Root/Background
@onready var dark_overlay: ColorRect = $Root/DarkOverlay
@onready var narration_box: PanelContainer = $Root/NarrationBox
@onready var narration_text: RichTextLabel = $Root/NarrationBox/ContentRow/TextWrap/NarrationText
@onready var continue_button: Button = $Root/NarrationBox/ContentRow/ContinueButton

var can_continue := false

var text_to_show := """
Brama wsi stoi otworem, lecz nikt nie wychodzi na powitanie.\nNa tablicy kołysze się świeżo przybite ogłoszenie.
"""

func _ready() -> void:
	hide()

	continue_button.pressed.connect(_on_continue_pressed)

	background.modulate.a = 0.0
	dark_overlay.modulate.a = 0.0
	narration_box.modulate.a = 0.0
	narration_text.modulate.a = 0.0
	continue_button.modulate.a = 0.0
	continue_button.disabled = true


func play() -> void:
	show()
	can_continue = false

	narration_text.text = text_to_show.strip_edges()
	narration_text.modulate.a = 0.0

	background.modulate.a = 0.0
	dark_overlay.modulate.a = 0.0
	narration_box.modulate.a = 0.0
	continue_button.modulate.a = 0.0
	continue_button.disabled = true

	var intro_tween := create_tween()
	intro_tween.tween_property(background, "modulate:a", 1.0, 1.2)
	intro_tween.parallel().tween_property(dark_overlay, "modulate:a", 1.0, 1.2)

	await intro_tween.finished
	await get_tree().create_timer(0.25).timeout

	var box_tween := create_tween()
	box_tween.tween_property(narration_box, "modulate:a", 1.0, 0.55)

	await box_tween.finished
	await get_tree().create_timer(0.15).timeout

	var text_tween := create_tween()
	text_tween.tween_property(narration_text, "modulate:a", 1.0, 1.1)

	await text_tween.finished
	await get_tree().create_timer(0.25).timeout

	continue_button.disabled = false
	can_continue = true

	var button_tween := create_tween()
	button_tween.tween_property(continue_button, "modulate:a", 1.0, 0.35)


func _on_continue_pressed() -> void:
	if not can_continue:
		return

	can_continue = false
	continue_button.disabled = true

	UiAudio.play_click()

	var out_tween := create_tween()
	out_tween.tween_property(narration_box, "modulate:a", 0.0, 0.35)
	out_tween.parallel().tween_property(background, "modulate:a", 0.0, 0.55)
	out_tween.parallel().tween_property(dark_overlay, "modulate:a", 0.0, 0.55)

	await out_tween.finished

	hide()
	finished.emit()
