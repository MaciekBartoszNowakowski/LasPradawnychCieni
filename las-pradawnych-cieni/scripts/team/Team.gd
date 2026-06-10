class_name Team

signal money_changed(new_money: int)
signal inventory_changed(items: Array[String])

var _money: int = 0

var money: int:
	get:
		return _money
	set(value):
		_money = max(value, 0)
		money_changed.emit(_money)

var characters: Array[Player] = []
var fallen_characters: Array[Player] = []
var inventory_item_ids: Array[String] = []


func _init() -> void:
	characters = [Knight.new(), Rogue.new(), Archer.new()]
	characters.sort_custom(func(a: Player, b: Player) -> bool: return a.initiative > b.initiative)


func add_money(amount: int) -> void:
	money += amount


func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	
	money -= amount
	return true
	
func apply_life_delta_to_all(amount: int) -> int:
	var total_delta: int = 0

	for character: Player in characters:
		if character == null:
			continue

		total_delta += character.apply_life_delta(amount)

	return total_delta


func heal_all(amount: int) -> int:
	if amount <= 0:
		return 0

	return apply_life_delta_to_all(amount)


func damage_all(amount: int) -> int:
	if amount <= 0:
		return 0

	return apply_life_delta_to_all(-amount)


func heal_all_missing_percent(percent: float) -> int:
	var total_healed: int = 0

	for character: Player in characters:
		if character == null:
			continue

		total_healed += character.heal_missing_percent(percent)

	return total_healed


func heal_character(hero_index: int, amount: int) -> int:
	if amount <= 0:
		return 0

	if hero_index < 0 or hero_index >= characters.size():
		return 0

	var hero: Player = characters[hero_index]
	if hero == null:
		return 0

	return hero.heal(amount)


func add_item_to_inventory(item_id: String) -> void:
	if item_id.is_empty():
		return

	inventory_item_ids.append(item_id)
	inventory_changed.emit(inventory_item_ids.duplicate())


func add_equipment_to_character(hero_index: int, item: ItemConfig) -> bool:
	if item == null:
		return false

	if hero_index < 0 or hero_index >= characters.size():
		return false

	var hero: Player = characters[hero_index]
	if hero == null:
		return false

	hero.add_equipment_item(item.item_id)
	_apply_item_effect_to_hero(hero, item)
	add_item_to_inventory(item.item_id)
	return true


func mark_character_fallen(character: Player) -> void:
	if character == null:
		return

	var fallen := create_hero(get_class_id_for_hero(character))
	_copy_hero_state(character, fallen)
	fallen.current_life = 0
	fallen_characters.append(fallen)


func has_fallen_characters() -> bool:
	return not fallen_characters.is_empty()


func revive_first_fallen(percent: float) -> Player:
	if fallen_characters.is_empty():
		return null

	var hero: Player = fallen_characters.pop_front() as Player
	if hero == null:
		return null

	var revive_life: int = max(1, int(ceil(float(hero.max_life) * clampf(percent, 0.0, 1.0))))
	hero.current_life = min(revive_life, hero.max_life)
	characters.append(hero)
	characters.sort_custom(func(a: Player, b: Player) -> bool: return a.initiative > b.initiative)
	return hero


static func create_hero(class_id: String) -> Player:
	match class_id:
		"Knight", "Rycerz":
			return Knight.new()
		"Rogue", "Łotrzyk":
			return Rogue.new()
		"Archer", "Łucznik":
			return Archer.new()
		_:
			return Knight.new()


static func get_class_id_for_hero(hero: Player) -> String:
	if hero is Knight:
		return "Knight"
	if hero is Rogue:
		return "Rogue"
	if hero is Archer:
		return "Archer"

	match hero.character_name:
		"Rycerz", "Knight":
			return "Knight"
		"Łotrzyk", "Rogue":
			return "Rogue"
		"Łucznik", "Archer":
			return "Archer"
		_:
			return "Knight"


static func _copy_hero_state(source: Player, target: Player) -> void:
	target.current_life = source.current_life
	target.equipped_item_ids = source.equipped_item_ids.duplicate()
	_apply_equipment_effects(target)


static func _apply_equipment_effects(hero: Player) -> void:
	for item_id in hero.equipped_item_ids:
		match item_id:
			"rusty_sword":
				_apply_strength_bonus(hero, 1)
			"hunter_shield":
				hero.armour += 1


static func _apply_item_effect_to_hero(hero: Player, item: ItemConfig) -> void:
	match item.item_kind:
		ItemConfig.ItemKind.STRENGTH_EQUIPMENT:
			_apply_strength_bonus(hero, item.effect_value)
		ItemConfig.ItemKind.ARMOUR_EQUIPMENT:
			hero.armour += item.effect_value


static func _apply_strength_bonus(hero: Player, amount: int) -> void:
	hero.strength += amount
	for action: BattleAction in hero.actions:
		if action == null:
			continue
		if action.damage > 0:
			action.damage += amount


func to_dict() -> Dictionary:
	var heroes: Array = []
	for character: Player in characters:
		if character == null:
			continue
		heroes.append({
			"class_id": get_class_id_for_hero(character),
			"current_life": character.current_life,
			"equipped_item_ids": character.equipped_item_ids.duplicate(),
		})

	var fallen: Array = []
	for character: Player in fallen_characters:
		if character == null:
			continue
		fallen.append({
			"class_id": get_class_id_for_hero(character),
			"current_life": character.current_life,
			"equipped_item_ids": character.equipped_item_ids.duplicate(),
		})

	return {
		"money": money,
		"inventory_item_ids": inventory_item_ids.duplicate(),
		"heroes": heroes,
		"fallen_heroes": fallen,
	}


static func from_dict(data: Dictionary) -> Team:
	var team := Team.new()
	team._money = int(data.get("money", 20))
	team.inventory_item_ids = []
	for raw_id in data.get("inventory_item_ids", []) as Array:
		team.inventory_item_ids.append(str(raw_id))

	team.characters.clear()
	var raw_heroes: Array = data.get("heroes", []) as Array
	var raw_fallen_heroes: Array = data.get("fallen_heroes", []) as Array

	for raw_hero in raw_heroes:
		var hero_data: Dictionary = raw_hero as Dictionary
		var hero: Player = create_hero(str(hero_data.get("class_id", "Knight")))
		hero.current_life = int(hero_data.get("current_life", hero.max_life))
		hero.equipped_item_ids = []
		for raw_equip in hero_data.get("equipped_item_ids", []) as Array:
			hero.equipped_item_ids.append(str(raw_equip))
		_apply_equipment_effects(hero)
		team.characters.append(hero)

	team.fallen_characters.clear()
	for raw_hero in raw_fallen_heroes:
		var hero_data: Dictionary = raw_hero as Dictionary
		var hero: Player = create_hero(str(hero_data.get("class_id", "Knight")))
		hero.current_life = int(hero_data.get("current_life", 0))
		hero.equipped_item_ids = []
		for raw_equip in hero_data.get("equipped_item_ids", []) as Array:
			hero.equipped_item_ids.append(str(raw_equip))
		_apply_equipment_effects(hero)
		team.fallen_characters.append(hero)

	if team.characters.is_empty() and team.fallen_characters.is_empty():
		team.characters = [Knight.new(), Rogue.new(), Archer.new()]
		team.characters.sort_custom(func(a: Player, b: Player) -> bool: return a.initiative > b.initiative)

	return team
