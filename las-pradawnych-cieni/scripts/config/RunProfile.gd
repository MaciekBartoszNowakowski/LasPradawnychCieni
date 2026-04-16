class_name RunProfile
extends Resource

enum SeedMode {
	RANDOM,
	FIXED,
	DEBUG
}

enum DifficultyLevel {
	EASY,
	NORMAL,
	HARD,
	CUSTOM
}

@export_group("Identity")
@export var profile_name: String = "Default Run"
@export_multiline var profile_description: String = ""

@export_group("Core References")
@export var map_generation_config: MapGenerationConfig

@export_group("Seed Settings")
@export var seed_mode: SeedMode = SeedMode.RANDOM
@export var fixed_seed: int = 12345

@export_group("Difficulty Settings")
@export var difficulty_level: DifficultyLevel = DifficultyLevel.NORMAL

@export_range(-10, 10, 1) var decision_length_modifier: int = 0
@export_range(-10, 10, 1) var combat_count_modifier: int = 0
@export_range(-10, 10, 1) var rest_count_modifier: int = 0
@export_range(-10, 10, 1) var shop_count_modifier: int = 0
@export_range(-10, 10, 1) var optional_event_modifier: int = 0

#@export_range(0.0, 2.0, 0.05) var risk_gap_modifier: float = 1.0
#@export_range(0.0, 2.0, 0.05) var recovery_opportunity_modifier: float = 1.0

@export_group("Runtime Overrides")
@export var override_show_full_map: bool = false
@export var override_boss_visible: bool = true
@export var override_force_act_lengths: bool = false
@export var forced_act_lengths: PackedInt32Array = PackedInt32Array()

@export_group("Debug Options")
@export var developer_mode: bool = false
@export var reveal_full_map_in_debug: bool = true
#@export var show_generation_labels: bool = false
#@export var export_generation_report: bool = false


#func has_map_config() -> bool:
	#return map_generation_config != null


func get_effective_seed() -> int:
	match seed_mode:
		SeedMode.FIXED, SeedMode.DEBUG:
			return fixed_seed
		_:
			return 0


func should_use_fixed_seed() -> bool:
	return seed_mode == SeedMode.FIXED or seed_mode == SeedMode.DEBUG


func build_runtime_map_config() -> MapGenerationConfig:
	if map_generation_config == null:
		return null

	var runtime_config: MapGenerationConfig = map_generation_config.duplicate_config()
	_apply_difficulty_to_map_config(runtime_config)
	_apply_runtime_overrides(runtime_config)
	return runtime_config


func _apply_difficulty_to_map_config(config: MapGenerationConfig) -> void:
	if config == null:
		return

	config.base_decision_length = max(1, config.base_decision_length + decision_length_modifier)

	config.combat_target_count = clamp(
		config.combat_target_count + combat_count_modifier,
		max(0, config.combat_min_count),
		max(config.combat_min_count, config.combat_max_count)
	)

	config.rest_target_count = clamp(
		config.rest_target_count + rest_count_modifier,
		max(0, config.rest_min_count),
		max(config.rest_min_count, config.rest_max_count)
	)

	config.shop_target_count = clamp(
		config.shop_target_count + shop_count_modifier,
		max(0, config.shop_min_count),
		max(config.shop_min_count, config.shop_max_count)
	)

	config.optional_event_target_count = clamp(
		config.optional_event_target_count + optional_event_modifier,
		max(0, config.optional_event_min_count),
		max(config.optional_event_min_count, config.optional_event_max_count)
	)

	_apply_difficulty_preset(config)


func _apply_difficulty_preset(config: MapGenerationConfig) -> void:
	match difficulty_level:
		DifficultyLevel.EASY:
			config.rest_target_count = min(config.rest_target_count + 1, max(config.rest_min_count, config.rest_max_count))
			config.shop_target_count = min(config.shop_target_count + 1, max(config.shop_min_count, config.shop_max_count))
			config.combat_target_count = max(config.combat_min_count, config.combat_target_count - 1)
			config.max_consecutive_combats = max(2, config.max_consecutive_combats - 1)

		DifficultyLevel.HARD:
			config.combat_target_count = min(config.combat_target_count + 1, max(config.combat_min_count, config.combat_max_count))
			config.rest_target_count = max(config.rest_min_count, config.rest_target_count - 1)
			config.max_consecutive_combats += 1

		_:
			pass


func _apply_runtime_overrides(config: MapGenerationConfig) -> void:
	if config == null:
		return

	if override_show_full_map:
		config.show_unreachable_future_nodes = true

	config.show_boss_always = override_boss_visible

	if developer_mode and reveal_full_map_in_debug:
		config.developer_reveal_all = true
		config.show_unreachable_future_nodes = true

	if override_force_act_lengths and forced_act_lengths.size() > 0:
		_apply_forced_act_lengths(config)


func _apply_forced_act_lengths(config: MapGenerationConfig) -> void:
	var new_weights := PackedFloat32Array()

	for value in forced_act_lengths:
		new_weights.append(max(1.0, float(value)))

	config.act_length_weights = new_weights
	config.act_count = max(1, forced_act_lengths.size())
