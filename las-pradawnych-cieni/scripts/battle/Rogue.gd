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

	var b := BattleAction.new()
	b.action_name = "Stab"
	b.action_type = "armor_pierce"
	b.damage = strength
	b.range = 1
	b.armor_piercing = true
	actions.append(b)

	var c := BattleAction.new()
	c.action_name = "Hide"
	c.action_type = "self_hide"
	c.damage = 0
	c.range = 0
	c.cooldown_max = 2
	actions.append(c)
