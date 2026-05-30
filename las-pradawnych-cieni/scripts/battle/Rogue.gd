class_name Rogue
extends Player

func _init() -> void:
	character_name = "Rogue"
	initiative = 3
	speed = 7
	agility = 5
	strength = 3
	armour = 1
	max_life = 8
	current_life = 8
	color = Color.DARK_VIOLET
	var a := BattleAction.new()
	a.action_name = "Throw Knife"
	a.damage = strength
	a.range = 2
	actions.append(a)
