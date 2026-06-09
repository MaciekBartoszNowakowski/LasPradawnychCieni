class_name Archer
extends Player

func _init() -> void:
	character_name = "Archer"
	initiative = 2
	speed = 5
	agility = 4
	strength = 2
	armour = 2
	max_life = 10
	current_life = 10
	color = Color.FOREST_GREEN
	portrait_path = "res://assets/ui/heroes/archer.png"
	var a := BattleAction.new()
	a.action_name = "Shoot"
	a.damage = strength
	a.range = 5
	actions.append(a)

	var b := BattleAction.new()
	b.action_name = "Arrow to the Knee"
	b.action_type = "arrow_knee"
	b.damage = strength
	b.damage_multiplier = 0.5
	b.range = 5
	actions.append(b)
