class_name Team

signal money_changed(new_money: int)

var _money: int = 0

var money: int:
	get:
		return _money
	set(value):
		_money = max(value, 0)
		money_changed.emit(_money)

var characters: Array[Player] = []


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
