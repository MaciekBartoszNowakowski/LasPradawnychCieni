class_name MapNode
extends RefCounted

var id: int
var type: int
var position: Vector2
var layer_index: int

var connections: Array[int] = []

var available: bool = false
var visited: bool = false

func _init(_id: int, _type: int, _position: Vector2, _layer_index: int) -> void:
	id = _id
	type = _type
	position = _position
	layer_index = _layer_index
