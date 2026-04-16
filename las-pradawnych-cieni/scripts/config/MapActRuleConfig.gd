class_name MapActRuleConfig
extends Resource

@export_group("Identity")
@export var act_id: int = 0
#@export var display_name: String = "Act"

@export_group("Structure")
@export var preferred_path_count: int = 2

@export_group("Densities")
@export_range(0.0, 3.0, 0.05) var combat_density: float = 1.0
@export_range(0.0, 3.0, 0.05) var rest_density: float = 1.0
@export_range(0.0, 3.0, 0.05) var shop_density: float = 1.0
@export_range(0.0, 3.0, 0.05) var optional_event_density: float = 1.0

@export_group("Special Content")
@export_range(0.0, 1.0, 0.01) var miniboss_chance: float = 0.0

@export_group("Topology")
#@export_range(0.0, 3.0, 0.05) var branching_intensity: float = 1.0
#@export_range(0.0, 3.0, 0.05) var merge_intensity: float = 1.0
