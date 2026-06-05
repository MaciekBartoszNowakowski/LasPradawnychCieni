class_name Bear
extends Enemy

func _init() -> void:
	character_name = "Bear"
	initiative = 1
	speed = 2
	agility = 1
	strength = 7
	armour = 4
	max_life = 22
	current_life = 22
	color = Color(0.35, 0.2, 0.05)
	var a := BattleAction.new()
	a.action_name = "Maul"
	a.damage = strength
	a.range = 1
	actions.append(a)
