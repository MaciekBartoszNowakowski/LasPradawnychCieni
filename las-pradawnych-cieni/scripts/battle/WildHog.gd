class_name WildHog
extends Enemy

func _init() -> void:
	character_name = "Wild Hog"
	initiative = 3
	speed = 3
	agility = 2
	strength = 4
	armour = 1
	max_life = 10
	current_life = 10
	color = Color(0.7, 0.35, 0.05)
	portrait_path = "res://assets/ui/enemies/boar.png"
	var a := BattleAction.new()
	a.action_name = "Charge"
	a.damage = strength
	a.range = 1
	actions.append(a)
