class_name Wolf
extends Enemy

func _init() -> void:
	character_name = "Wilk"
	initiative = 2
	speed = 4
	agility = 3
	strength = 3
	armour = 1
	max_life = 8
	current_life = 8
	color = Color(0.9, 0.1, 0.1)
	portrait_path = "res://assets/ui/enemies/wolf.png"
	var a := BattleAction.new()
	a.action_name = "Ugryzienie"
	a.damage = strength
	a.range = 1
	actions.append(a)
