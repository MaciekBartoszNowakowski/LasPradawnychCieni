class_name ForestShadowBoss
extends Enemy


func _init() -> void:
	character_name = "Cień Pradawnego Lasu"
	initiative = 5
	speed = 3
	agility = 2
	strength = 8
	armour = 3
	max_life = 40
	current_life = 40
	color = Color(0.12, 0.28, 0.18, 1.0)

	var attack := BattleAction.new()
	attack.action_name = "Atak"
	attack.damage = strength
	attack.range = 1
	actions.append(attack)


func _ready() -> void:
	scale = Vector2(1.35, 1.35)
	queue_redraw()
