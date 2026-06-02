extends Resource
class_name ItemConfig

enum ItemKind {
	HEAL_SINGLE,
	HEAL_TEAM,
	FUTURE_EQUIPMENT
}

@export var item_id: String = ""
@export var display_name: String = ""
@export var short_name: String = ""
@export_multiline var description: String = ""
@export var item_kind: ItemKind = ItemKind.FUTURE_EQUIPMENT
@export var price: int = 0
@export var effect_value: int = 0
@export var icon_path: String = ""
