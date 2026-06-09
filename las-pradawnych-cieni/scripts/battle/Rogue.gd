class_name Rogue
extends Player

func _init() -> void:
	character_name = "Łotrzyk"
	initiative = 3
	speed = 7
	agility = 5
	strength = 3
	armour = 1
	max_life = 8
	current_life = 8
	color = Color.DARK_VIOLET
	portrait_path = "res://assets/ui/heroes/rogue.png"
	var a := BattleAction.new()
	a.action_name = "Rzut nożem"
	a.damage = strength
	a.range = 2
	actions.append(a)

	var b := BattleAction.new()
	b.action_name = "Pchnięcie"
	b.action_type = "armor_pierce"
	b.damage = strength
	b.range = 1
	b.armor_piercing = true
	actions.append(b)

	var c := BattleAction.new()
	c.action_name = "Ukrycie"
	c.action_type = "self_hide"
	c.damage = 0
	c.range = 0
	c.cooldown_max = 2
	actions.append(c)
