extends CanvasLayer

var fade_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	layer = 100
	
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	add_child(fade_rect)
	
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.offset_left = 0
	fade_rect.offset_top = 0
	fade_rect.offset_right = 0
	fade_rect.offset_bottom = 0
	
	fade_rect.hide()


func change_scene(scene_path: String, fade_out_time: float = 0.45, fade_in_time: float = 0.45) -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.show()
	
	var fade_out := create_tween()
	fade_out.tween_property(fade_rect, "color:a", 1.0, fade_out_time)
	await fade_out.finished
	
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneTransition: nie udało się zmienić sceny na: " + scene_path)
		_finish_failed_transition(fade_in_time)
		return
	
	await get_tree().process_frame
	
	var fade_in := create_tween()
	fade_in.tween_property(fade_rect, "color:a", 0.0, fade_in_time)
	await fade_in.finished
	
	fade_rect.hide()
	_is_transitioning = false


func _finish_failed_transition(fade_in_time: float) -> void:
	var fade_in := create_tween()
	fade_in.tween_property(fade_rect, "color:a", 0.0, fade_in_time)
	await fade_in.finished
	
	fade_rect.hide()
	_is_transitioning = false
