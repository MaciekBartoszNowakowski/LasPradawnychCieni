extends Node2D
class_name BackdropLayer

const BACKDROP_TEXTURE: Texture2D = preload("res://assets/ui/map/map_background.png")
const DRAW_LAYER_GUIDES: bool = false

var map_rect: Rect2 = Rect2()
var map_config: MapGenerationConfig = null
var layer_count: int = 0


func setup(new_map_rect: Rect2, new_map_config: MapGenerationConfig, new_layer_count: int) -> void:
	map_rect = _snap_rect(new_map_rect)
	map_config = new_map_config
	layer_count = new_layer_count
	queue_redraw()


func _draw() -> void:
	if map_rect.size == Vector2.ZERO:
		return

	_draw_backdrop_texture()

	if DRAW_LAYER_GUIDES:
		_draw_layer_guides()


func _draw_backdrop_texture() -> void:
	draw_texture_rect(BACKDROP_TEXTURE, map_rect, false)


func _draw_layer_guides() -> void:
	if map_config == null:
		return

	if layer_count <= 0:
		return

	var top_padding: float = 28.0
	var bottom_padding: float = 28.0

	for layer_index in range(layer_count):
		var x: float = map_config.start_x + float(layer_index) * map_config.segment_spacing

		if x < map_rect.position.x or x > map_rect.position.x + map_rect.size.x:
			continue

		draw_line(
			Vector2(x, map_rect.position.y + top_padding),
			Vector2(x, map_rect.position.y + map_rect.size.y - bottom_padding),
			Color(0.10, 0.08, 0.06, 0.08),
			1.0
		)


func _snap_rect(r: Rect2) -> Rect2:
	return Rect2(
		Vector2(floor(r.position.x), floor(r.position.y)),
		Vector2(ceil(r.size.x), ceil(r.size.y))
	)
