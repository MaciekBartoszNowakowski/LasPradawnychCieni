extends CanvasLayer

signal finished

@onready var background: TextureRect = $Root/Background
@onready var dark_overlay: ColorRect = $Root/DarkOverlay
@onready var go_to_mayor_button: Button = $Root/GoToMayorButton

func _ready() -> void:
	hide()
	go_to_mayor_button.pressed.connect(_on_go_to_mayor_pressed)

	background.modulate.a = 0.0
	dark_overlay.modulate.a = 0.0
	go_to_mayor_button.modulate.a = 0.0
	go_to_mayor_button.disabled = true

func play() -> void:
	show()

	background.modulate.a = 0.0
	dark_overlay.modulate.a = 0.0
	go_to_mayor_button.modulate.a = 0.0
	go_to_mayor_button.disabled = true

	var tween := create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(dark_overlay, "modulate:a", 1.0, 1.0)

	await tween.finished
	await get_tree().create_timer(0.25).timeout

	go_to_mayor_button.disabled = false

	var button_tween := create_tween()
	button_tween.tween_property(go_to_mayor_button, "modulate:a", 1.0, 0.35)

func _on_go_to_mayor_pressed() -> void:
	UiAudio.play_click()
	go_to_mayor_button.disabled = true

	var tween := create_tween()
	tween.tween_property(go_to_mayor_button, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(background, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(dark_overlay, "modulate:a", 0.0, 0.5)

	await tween.finished

	hide()
	finished.emit()
