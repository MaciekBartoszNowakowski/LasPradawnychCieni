extends Control

@onready var room_label: Label = $CenterContainer/VBoxContainer/Label

func _ready() -> void:
	room_label.text = "Typ pokoju: " + _type_to_string(MapState.selected_node_type)

func _type_to_string(type: int) -> String:
	match type:
		MapEnums.NodeType.BATTLE:
			return "BATTLE"
		MapEnums.NodeType.EVENT:
			return "EVENT"
		MapEnums.NodeType.SHOP:
			return "SHOP"
		MapEnums.NodeType.REST:
			return "REST"
		MapEnums.NodeType.ELITE:
			return "ELITE"
		MapEnums.NodeType.BOSS:
			return "BOSS"
		MapEnums.NodeType.CHECKPOINT:
			return "CHECKPOINT"
		_:
			return "UNKNOWN"


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Map.tscn")
