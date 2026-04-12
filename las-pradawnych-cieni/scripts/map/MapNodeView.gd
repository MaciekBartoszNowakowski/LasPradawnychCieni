extends Node2D
class_name MapNodeView

@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var base_sprite: Sprite2D = $BaseSprite

var node_data: MapNode = null
var hovered: bool = false
var base_texture: Texture2D = null
var visual_textures: Dictionary = {}


func setup(node: MapNode, is_hovered: bool, textures: Dictionary) -> void:
	node_data = node
	hovered = is_hovered
	visual_textures = textures.duplicate()
	position = node.position

	_apply_visual_state()


func set_hovered(is_hovered: bool) -> void:
	hovered = is_hovered
	_apply_visual_state()


func refresh() -> void:
	_apply_visual_state()


func _apply_visual_state() -> void:
	if node_data == null:
		return

	base_texture = _get_texture_for_current_state()
	if base_texture == null:
		return

	base_sprite.texture = base_texture
	shadow_sprite.texture = base_texture

	var scale_value: float = _get_base_scale()
	base_sprite.scale = Vector2.ONE * scale_value
	shadow_sprite.scale = Vector2.ONE * scale_value

	base_sprite.position = Vector2.ZERO
	shadow_sprite.position = Vector2(0.0, 4.0)

	shadow_sprite.modulate = Color(0.0, 0.0, 0.0, 0.18)
	base_sprite.modulate = Color.WHITE

	if node_data.visited:
		base_sprite.modulate = Color(0.92, 1.0, 0.94, 1.0)


func _get_texture_for_current_state() -> Texture2D:
	if hovered and node_data.available and visual_textures.has("hover"):
		return visual_textures["hover"]

	if (node_data.available or node_data.visited) and visual_textures.has("available"):
		return visual_textures["available"]

	if visual_textures.has("locked"):
		return visual_textures["locked"]

	return null


func _get_base_scale() -> float:
	if base_texture == null:
		return 1.0

	var texture_width: float = float(base_texture.get_width())
	if texture_width <= 0.0:
		return 1.0

	var target_diameter: float = _get_target_diameter()
	return target_diameter / texture_width


func _get_target_diameter() -> float:
	match node_data.type:
		MapEnums.NodeType.BOSS:
			return 80.0

		MapEnums.NodeType.ELITE:
			return 70.0

		MapEnums.NodeType.CHECKPOINT:
			return 70.0

		_:
			return 70.0
