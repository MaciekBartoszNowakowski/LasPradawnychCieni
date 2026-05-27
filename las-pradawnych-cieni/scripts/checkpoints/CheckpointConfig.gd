class_name CheckpointConfig
extends Resource

@export var checkpoint_id: StringName
@export var title: String = ""
@export_multiline var description: String = ""
@export var lore_tag: StringName
@export var background: Texture2D = null
@export var choices: Array[Resource] = []


func get_choices() -> Array[CheckpointChoiceConfig]:
	var result: Array[CheckpointChoiceConfig] = []

	for raw_choice in choices:
		var choice := raw_choice as CheckpointChoiceConfig
		if choice != null:
			result.append(choice)

	return result
