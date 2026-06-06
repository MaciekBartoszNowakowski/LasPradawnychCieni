class_name Bandit
extends Enemy

func _init() -> void:
	character_name = "Bandit"
	initiative = 2
	speed = 3
	agility = 3
	strength = 4
	armour = 2
	max_life = 12
	current_life = 12
	color = Color(0.3, 0.3, 0.4)
	var a := BattleAction.new()
	a.action_name = "Strike"
	a.damage = strength
	a.range = 1
	actions.append(a)
