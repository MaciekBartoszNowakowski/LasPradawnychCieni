extends Resource
class_name ItemConfig

enum ItemKind {
	HEAL_SINGLE,
	HEAL_TEAM,
	STRENGTH_EQUIPMENT,
	ARMOUR_EQUIPMENT,
	REVIVE
}

@export var item_id: String = ""
@export var display_name: String = ""
@export var short_name: String = ""
@export_multiline var description: String = ""
@export var item_kind: ItemKind = ItemKind.HEAL_SINGLE
@export var price: int = 0
@export var effect_value: int = 0
@export var icon_path: String = ""
