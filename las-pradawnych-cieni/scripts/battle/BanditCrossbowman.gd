class_name BanditCrossbowman
extends Enemy

const PREFERRED_RANGE: int = 5

func _init() -> void:
	character_name = "Kusznik"
	initiative = 3
	speed = 2
	agility = 4
	strength = 5
	armour = 1
	max_life = 9
	current_life = 9
	color = Color(0.4, 0.2, 0.5)
	portrait_path = "res://assets/ui/enemies/bandit_crossbow.png"
	var a := BattleAction.new()
	a.action_name = "Strzał"
	a.damage = strength
	a.range = PREFERRED_RANGE
	actions.append(a)

# Stay at range: don't move if player is already within shooting range.
# Only advance if all players are out of range.
func move(astar: AStarGrid2D, cells: Dictionary, player_characters: Array[Player], all_combatants: Array[Player]) -> void:
	var closest := _find_closest_player(player_characters)
	if closest == null:
		return

	var dist: int = abs(grid_pos.x - closest.grid_pos.x) + abs(grid_pos.y - closest.grid_pos.y)
	if dist <= PREFERRED_RANGE:
		return

	super.move(astar, cells, player_characters, all_combatants)
