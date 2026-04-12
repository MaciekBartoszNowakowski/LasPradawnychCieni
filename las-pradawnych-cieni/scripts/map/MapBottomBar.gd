extends PanelContainer
class_name MapBottomBar

const BATTLE_ICON: Texture2D = preload("res://assets/ui/map/nodes/battle_base_256.png")
const EVENT_ICON: Texture2D = preload("res://assets/ui/map/nodes/event_base_256.png")
const SHOP_ICON: Texture2D = preload("res://assets/ui/map/nodes/shop_base_256.png")
const REST_ICON: Texture2D = preload("res://assets/ui/map/nodes/rest_base_256.png")
const ELITE_ICON: Texture2D = preload("res://assets/ui/map/nodes/elite_base_256.png")

@onready var left_block: HBoxContainer = $MarginContainer/HBoxContainer/LeftBlock
@onready var icon_box: CenterContainer = $MarginContainer/HBoxContainer/LeftBlock/IconBox
@onready var node_icon: TextureRect = $MarginContainer/HBoxContainer/LeftBlock/IconBox/NodeIcon
@onready var node_type_label: Label = $MarginContainer/HBoxContainer/LeftBlock/InfoBox/NodeTypeLabel
@onready var node_state_label: Label = $MarginContainer/HBoxContainer/LeftBlock/InfoBox/NodeStateLabel
@onready var center_block: VBoxContainer = $MarginContainer/HBoxContainer/CenterBlock
@onready var node_description_label: Label = $MarginContainer/HBoxContainer/CenterBlock/NodeDescriptionLabel
@onready var right_block: VBoxContainer = $MarginContainer/HBoxContainer/RightBlock
@onready var controls_primary_label: Label = $MarginContainer/HBoxContainer/RightBlock/ControlsPrimaryLabel
@onready var controls_secondary_label: Label = $MarginContainer/HBoxContainer/RightBlock/ControlsSecondaryLabel

func _ready() -> void:
	clip_contents = true

	left_block.custom_minimum_size = Vector2(260.0, 0.0)
	right_block.custom_minimum_size = Vector2(280.0, 0.0)
	center_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	icon_box.custom_minimum_size = Vector2(72.0, 72.0)

	node_icon.custom_minimum_size = Vector2(64.0, 64.0)
	node_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	node_description_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	node_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	controls_primary_label.text = "LPM: wybór"
	controls_secondary_label.text = "Kółko myszy: przewijanie"

	controls_primary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	controls_secondary_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	controls_primary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls_secondary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	show_default()

func show_default() -> void:
	icon_box.visible = false
	node_icon.texture = null

	node_type_label.text = "Brak wyboru"
	node_state_label.text = "Najedź na lokację"
	node_state_label.modulate = Color(0.72, 0.69, 0.62, 0.92)

	node_description_label.text = "Wybierz kolejną dostępną lokację."


func show_for_hovered_node(node: MapNode) -> void:
	_apply_node(node, "hovered")


func show_for_selected_node(node: MapNode) -> void:
	_apply_node(node, "selected")


func _apply_node(node: MapNode, mode: String) -> void:
	if node == null:
		show_default()
		return

	icon_box.visible = true
	node_icon.texture = _get_icon_for_node_type(node.type)

	node_type_label.text = _get_type_name(node.type)
	node_state_label.text = _get_state_text(node, mode)
	node_state_label.modulate = _get_state_color(node, mode)
	node_description_label.text = _get_description(node.type)


func _get_type_name(node_type: int) -> String:
	match node_type:
		MapEnums.NodeType.BATTLE:
			return "Walka"
		MapEnums.NodeType.EVENT:
			return "Wydarzenie"
		MapEnums.NodeType.SHOP:
			return "Sklep"
		MapEnums.NodeType.REST:
			return "Odpoczynek"
		MapEnums.NodeType.ELITE:
			return "Elita"
		MapEnums.NodeType.BOSS:
			return "Boss"
		MapEnums.NodeType.CHECKPOINT:
			return "Punkt kontrolny"
		_:
			return "Nieznana lokacja"


func _get_description(node_type: int) -> String:
	match node_type:
		MapEnums.NodeType.BATTLE:
			return "Standardowe starcie. Wygrana otwiera dalszą drogę."
		MapEnums.NodeType.EVENT:
			return "Tajemnicze zdarzenie z możliwymi konsekwencjami."
		MapEnums.NodeType.SHOP:
			return "Wydaj złoto na wsparcie przed kolejnymi starciami."
		MapEnums.NodeType.REST:
			return "Chwila wytchnienia i przygotowanie do dalszej wyprawy."
		MapEnums.NodeType.ELITE:
			return "Trudniejsze starcie, ale większa nagroda."
		MapEnums.NodeType.BOSS:
			return "Główne starcie prowadzące do zakończenia etapu."
		MapEnums.NodeType.CHECKPOINT:
			return "Ważny punkt wyprawy prowadzący dalej."
		_:
			return "Brak opisu."


func _get_state_text(node: MapNode, mode: String) -> String:
	if mode == "selected":
		return "Aktualna pozycja"

	if node.visited:
		return "Ukończone"

	if node.available:
		return "Dostępne"

	return "Zablokowane"


func _get_state_color(node: MapNode, mode: String) -> Color:
	if mode == "selected":
		return Color(0.92, 0.84, 0.62, 0.95)

	if node.visited:
		return Color(0.68, 0.84, 0.70, 0.95)

	if node.available:
		return Color(0.90, 0.84, 0.66, 0.95)

	return Color(0.62, 0.60, 0.58, 0.92)


func _get_icon_for_node_type(node_type: int) -> Texture2D:
	match node_type:
		MapEnums.NodeType.BATTLE:
			return BATTLE_ICON
		MapEnums.NodeType.EVENT:
			return EVENT_ICON
		MapEnums.NodeType.SHOP:
			return SHOP_ICON
		MapEnums.NodeType.REST:
			return REST_ICON
		MapEnums.NodeType.ELITE:
			return ELITE_ICON
		MapEnums.NodeType.BOSS:
			return ELITE_ICON
		MapEnums.NodeType.CHECKPOINT:
			return EVENT_ICON
		_:
			return BATTLE_ICON
