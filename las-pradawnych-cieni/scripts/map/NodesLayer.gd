extends Node2D
class_name NodesLayer

const NODE_VIEW_SCENE: PackedScene = preload("res://scenes/map/MapNodeView.tscn")

const BATTLE_AVAILABLE_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/battle_base_256.png")
const BATTLE_HOVER_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/battle_hover_256.png")
const BATTLE_LOCKED_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/battle_locked_256.png")

const EVENT_AVAILABLE_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/event_base_256.png")
const EVENT_HOVER_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/event_hover_256.png")
const EVENT_LOCKED_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/event_locked_256.png")

const SHOP_AVAILABLE_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/shop_base_256.png")
const SHOP_HOVER_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/shop_hover_256.png")
const SHOP_LOCKED_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/shop_locked_256.png")

const REST_AVAILABLE_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/rest_base_256.png")
const REST_HOVER_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/rest_hover_256.png")
const REST_LOCKED_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/rest_locked_256.png")

const ELITE_AVAILABLE_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/elite_base_256.png")
const ELITE_HOVER_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/elite_hover_256.png")
const ELITE_LOCKED_TEXTURE: Texture2D = preload("res://assets/ui/map/nodes/elite_locked_256.png")

var map_nodes: Array[MapNode] = []
var hovered_node_id: int = -1
var node_views: Dictionary = {}


func setup(new_map_nodes: Array[MapNode], new_hovered_node_id: int) -> void:
	map_nodes = new_map_nodes
	hovered_node_id = new_hovered_node_id
	_rebuild_views()


func set_hovered_node(new_hovered_node_id: int) -> void:
	var previous_hovered: int = hovered_node_id
	hovered_node_id = new_hovered_node_id

	if previous_hovered != -1 and node_views.has(previous_hovered):
		var previous_view: MapNodeView = node_views[previous_hovered]
		previous_view.set_hovered(false)

	if hovered_node_id != -1 and node_views.has(hovered_node_id):
		var current_view: MapNodeView = node_views[hovered_node_id]
		current_view.set_hovered(true)


func _rebuild_views() -> void:
	for child in get_children():
		child.queue_free()

	node_views.clear()

	for node in map_nodes:
		var node_view: MapNodeView = NODE_VIEW_SCENE.instantiate() as MapNodeView
		var textures: Dictionary = _get_textures_for_node(node)

		add_child(node_view)
		node_view.setup(node, node.id == hovered_node_id, textures)

		node_views[node.id] = node_view


func _get_textures_for_node(node: MapNode) -> Dictionary:
	match node.type:
		MapEnums.NodeType.BATTLE:
			return _make_state_set(
				BATTLE_AVAILABLE_TEXTURE,
				BATTLE_HOVER_TEXTURE,
				BATTLE_LOCKED_TEXTURE
			)

		MapEnums.NodeType.EVENT:
			return _make_state_set(
				EVENT_AVAILABLE_TEXTURE,
				EVENT_HOVER_TEXTURE,
				EVENT_LOCKED_TEXTURE
			)

		MapEnums.NodeType.SHOP:
			return _make_state_set(
				SHOP_AVAILABLE_TEXTURE,
				SHOP_HOVER_TEXTURE,
				SHOP_LOCKED_TEXTURE
			)

		MapEnums.NodeType.REST:
			return _make_state_set(
				REST_AVAILABLE_TEXTURE,
				REST_HOVER_TEXTURE,
				REST_LOCKED_TEXTURE
			)

		MapEnums.NodeType.ELITE:
			return _make_state_set(
				ELITE_AVAILABLE_TEXTURE,
				ELITE_HOVER_TEXTURE,
				ELITE_LOCKED_TEXTURE
			)

		MapEnums.NodeType.CHECKPOINT:
			return _make_state_set(
				EVENT_AVAILABLE_TEXTURE,
				EVENT_HOVER_TEXTURE,
				EVENT_LOCKED_TEXTURE
			)

		MapEnums.NodeType.BOSS:
			return _make_state_set(
				ELITE_AVAILABLE_TEXTURE,
				ELITE_HOVER_TEXTURE,
				ELITE_LOCKED_TEXTURE
			)

		_:
			return _make_state_set(
				BATTLE_AVAILABLE_TEXTURE,
				BATTLE_HOVER_TEXTURE,
				BATTLE_LOCKED_TEXTURE
			)


func _make_state_set(available: Texture2D, hover: Texture2D, locked: Texture2D) -> Dictionary:
	return {
		"available": available,
		"hover": hover,
		"locked": locked
	}
