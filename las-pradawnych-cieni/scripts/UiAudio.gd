extends Node

const CLICK_SOUND := preload("res://assets/ui/menu/ui_click.wav")

var click_player: AudioStreamPlayer


func _ready() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.stream = CLICK_SOUND
	click_player.bus = "SFX" # opcjonalnie, jeśli masz bus SFX
	add_child(click_player)


func play_click() -> void:
	if click_player == null:
		return

	if click_player.playing:
		click_player.stop()

	click_player.play()
