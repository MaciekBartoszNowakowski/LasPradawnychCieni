class_name Team

var money: int = 0
var characters: Array[Player] = []

func _init() -> void:
	characters = [Knight.new(), Rogue.new(), Archer.new()]
	characters.sort_custom(func(a: Player, b: Player) -> bool: return a.initiative > b.initiative)
