class_name Knight
extends Player

func _init() -> void:
	character_name = "Rycerz"
	initiative = 1
	speed = 4
	agility = 2
	strength = 5
	armour = 4
	max_life = 12
	current_life = 12
	color = Color.STEEL_BLUE
	portrait_path = "res://assets/ui/heroes/knight.png"
	var a := BattleAction.new()
	a.action_name = "Atak"
	a.damage = strength
	a.range = 1
	actions.append(a)

	var b := BattleAction.new()
	b.action_name = "Szeroki zamach"
	b.action_type = "aoe_adjacent"
	b.damage = strength
	b.damage_multiplier = 0.5
	b.range = 1
	actions.append(b)

	var c := BattleAction.new()
	c.action_name = "Obrona"
	c.action_type = "self_defend"
	c.damage = 0
	c.range = 0
	actions.append(c)
