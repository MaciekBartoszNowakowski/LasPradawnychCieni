class_name Team

signal money_changed(new_money: int)
signal inventory_changed(items: Array[String])

var _money: int = 20

var money: int:
	get:
		return _money
	set(value):
		_money = max(value, 0)
		money_changed.emit(_money)

var characters: Array[Player] = []
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


static func create_hero(class_id: String) -> Player:
	match class_id:
		"Knight":
			return Knight.new()
		"Rogue":
			return Rogue.new()
		"Archer":
			return Archer.new()
		_:
			return Knight.new()


func to_dict() -> Dictionary:
	var heroes: Array = []
	for character: Player in characters:
		if character == null:
			continue
		heroes.append({
			"class_id": character.character_name,
			"current_life": character.current_life,
			"equipped_item_ids": character.equipped_item_ids.duplicate(),
		})

	return {
		"money": money,
		"inventory_item_ids": inventory_item_ids.duplicate(),
		"heroes": heroes,
	}


static func from_dict(data: Dictionary) -> Team:
	var team := Team.new()
	team._money = int(data.get("money", 20))
	team.inventory_item_ids = []
	for raw_id in data.get("inventory_item_ids", []) as Array:
		team.inventory_item_ids.append(str(raw_id))

	team.characters.clear()
	for raw_hero in data.get("heroes", []) as Array:
		var hero_data: Dictionary = raw_hero as Dictionary
		var hero: Player = create_hero(str(hero_data.get("class_id", "Knight")))
		hero.current_life = int(hero_data.get("current_life", hero.max_life))
		hero.equipped_item_ids = []
		for raw_equip in hero_data.get("equipped_item_ids", []) as Array:
			hero.equipped_item_ids.append(str(raw_equip))
		team.characters.append(hero)

	if team.characters.is_empty():
		team.characters = [Knight.new(), Rogue.new(), Archer.new()]
		team.characters.sort_custom(func(a: Player, b: Player) -> bool: return a.initiative > b.initiative)

	return team
