class_name FinaleBattleMap
extends BattleMap

const EPILOGUE_SCENE_PATH := "res://scenes/finale/Epilogue.tscn"
const DEFEAT_OVERLAY_SCENE_PATH := "res://scenes/ui/DefeatOverlay.tscn"

var _battle_finished: bool = false

var _dark_tint: ColorRect
var _defeat_overlay: DefeatOverlay
var _finale_music: AudioStreamPlayer


func _configure_presentation() -> void:
	_dark_tint = ColorRect.new()
	_dark_tint.name = "DarkTint"
	_dark_tint.color = Color(0.02, 0.04, 0.06, 0.45)
	_dark_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dark_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var canvas := CanvasLayer.new()
	canvas.name = "FinalePresentationLayer"
	canvas.layer = 5
	add_child(canvas)
	canvas.add_child(_dark_tint)

	_finale_music = AudioStreamPlayer.new()
	_finale_music.name = "FinaleMusic"
	_finale_music.bus = "Music"
	add_child(_finale_music)

	var defeat_scene: PackedScene = load(DEFEAT_OVERLAY_SCENE_PATH) as PackedScene
	if defeat_scene != null:
		_defeat_overlay = defeat_scene.instantiate() as DefeatOverlay
		if _defeat_overlay != null:
			canvas.add_child(_defeat_overlay)


func _setup_battle() -> void:
	spawn_characters()
	_spawn_boss()


func _should_show_end_battle_button() -> bool:
	return false


func _get_victory_scene_path() -> String:
	return EPILOGUE_SCENE_PATH


func _on_all_enemies_defeated() -> void:
	if _battle_finished:
		return
	_complete_finale_victory()


func _on_party_wiped() -> void:
	if _battle_finished:
		return
	_battle_finished = true
	_targeting_mode = false
	_pending_action = null
	set_process(false)
	if _end_turn_button != null:
		_end_turn_button.disabled = true
	if _defeat_overlay != null:
		_defeat_overlay.show_overlay()


func _spawn_boss() -> void:
	var boss: ForestShadowBoss = FinaleEncounterSets.create_boss()
	spawn_enemy(boss, FinaleEncounterSets.BOSS_POSITION)


func _complete_finale_victory() -> void:
	_battle_finished = true
	if has_node("/root/MapState"):
		MapState.clear_finale_battle()
		MapState.mark_run_completed()
	_reparent_players_to_game_state()
	_go_to_scene(EPILOGUE_SCENE_PATH)
