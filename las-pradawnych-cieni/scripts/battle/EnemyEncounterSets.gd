class_name EnemyEncounterSets

# Tracks which set indices have already been used per act this session.
# Resets when all sets for that act have been played.
static var _used_indices: Dictionary = {}

static func get_random_set_for_act(act: int) -> Array[Enemy]:
	var sets: Array = _get_sets_for_act(act)

	if not _used_indices.has(act):
		_used_indices[act] = []

	var used: Array = _used_indices[act]

	var available: Array[int] = []
	for i in range(sets.size()):
		if not used.has(i):
			available.append(i)

	if available.is_empty():
		_used_indices[act] = []
		available.clear()
		for i in range(sets.size()):
			available.append(i)

	var chosen_idx: int = available[randi() % available.size()]
	_used_indices[act].append(chosen_idx)
	return sets[chosen_idx]

static func _get_sets_for_act(act: int) -> Array:
	match act:
		0: return _act_0_sets()
		1: return _act_1_sets()
		2: return _act_2_sets()
		_: return _act_0_sets()

static func _act_0_sets() -> Array:
	return [
		([Wolf.new(), Wolf.new()] as Array[Enemy]),
		([Wolf.new(), WildHog.new()] as Array[Enemy]),
		([WildHog.new()] as Array[Enemy]),
		([Bandit.new()] as Array[Enemy]),
		([Bandit.new(), Bandit.new()] as Array[Enemy]),
	]

static func _act_1_sets() -> Array:
	return [
		([WildHog.new(), WildHog.new()] as Array[Enemy]),
		([Wolf.new(), Wolf.new(), WildHog.new()] as Array[Enemy]),
		([Bear.new()] as Array[Enemy]),
		([Bandit.new(), Bandit.new(), Bandit.new()] as Array[Enemy]),
		([Bandit.new(), BanditCrossbowman.new()] as Array[Enemy]),
	]

static func _act_2_sets() -> Array:
	return [
		([Bear.new(), WildHog.new()] as Array[Enemy]),
		([Bear.new(), Wolf.new(), Wolf.new()] as Array[Enemy]),
		([Bear.new(), WildHog.new(), Wolf.new()] as Array[Enemy]),
		([Bandit.new(), Bandit.new(), BanditCrossbowman.new()] as Array[Enemy]),
		([BanditCrossbowman.new(), BanditCrossbowman.new(), Bandit.new()] as Array[Enemy]),
	]
