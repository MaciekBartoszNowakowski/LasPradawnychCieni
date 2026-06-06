class_name FinaleEncounterSets

const WAVE_ENEMY_POSITIONS: Array[Vector2i] = [
	Vector2i(12, 1),
	Vector2i(15, 5),
	Vector2i(17, 7),
	Vector2i(13, 2),
	Vector2i(16, 6),
	Vector2i(18, 2),
	Vector2i(14, 6),
]

const BOSS_POSITION := Vector2i(16, 4)


static func get_wave_enemies(wave_index: int) -> Array[Enemy]:
	match wave_index:
		1:
			return [
				_boost_enemy(Bear.new(), 1.2, 1),
				_boost_enemy(WildHog.new(), 1.2, 1),
				_boost_enemy(Wolf.new(), 1.15, 0),
			]
		2:
			return [
				_boost_enemy(Bandit.new(), 1.2, 1),
				_boost_enemy(Bandit.new(), 1.2, 1),
				_boost_enemy(BanditCrossbowman.new(), 1.15, 1),
				_boost_enemy(Bear.new(), 1.25, 2),
			]
		_:
			return []


static func create_boss() -> ForestShadowBoss:
	return ForestShadowBoss.new()


static func get_spawn_positions(enemy_count: int) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for i in range(mini(enemy_count, WAVE_ENEMY_POSITIONS.size())):
		positions.append(WAVE_ENEMY_POSITIONS[i])
	return positions


static func _boost_enemy(enemy: Enemy, hp_multiplier: float, damage_bonus: int) -> Enemy:
	enemy.max_life = maxi(1, int(round(float(enemy.max_life) * hp_multiplier)))
	enemy.current_life = enemy.max_life
	if not enemy.actions.is_empty():
		enemy.actions[0].damage += damage_bonus
	return enemy
