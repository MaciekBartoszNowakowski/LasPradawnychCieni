class_name BattleAction
extends RefCounted

var action_name: String = "Attack"
var damage: int = 1
var range: int = 1

# Returns {hit: bool, roll: int, miss_chance: int, damage: int}
static func resolve(action: BattleAction, target: Player) -> Dictionary:
	var miss_chance := minf(float(target.agility) * 10.0, 90.0)
	var roll := randf() * 100.0
	if roll < miss_chance:
		return {"hit": false, "roll": int(roll), "miss_chance": int(miss_chance), "damage": 0}
	var dmg := float(action.damage) * maxf(1.0 - 0.1 * float(target.armour), 0.1)
	return {"hit": true, "roll": int(roll), "miss_chance": int(miss_chance), "damage": maxi(int(dmg), 1)}
