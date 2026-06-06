class_name BattleAction
extends RefCounted

var action_name: String = "Attack"
var damage: int = 1
var range: int = 1
var action_type: String = "normal"
# values: "normal" | "aoe_adjacent" | "self_defend" | "self_hide" | "arrow_knee" | "armor_pierce"
var damage_multiplier: float = 1.0
var armor_piercing: bool = false
var cooldown_max: int = 0
var cooldown_remaining: int = 0

# Returns {hit: bool, roll: int, miss_chance: int, damage: int}
static func resolve(action: BattleAction, target: Player) -> Dictionary:
	var miss_chance := minf(float(target.agility) * 10.0, 90.0)
	var roll := randf() * 100.0
	if roll < miss_chance:
		return {"hit": false, "roll": int(roll), "miss_chance": int(miss_chance), "damage": 0}
	var dmg := float(action.damage)
	if not action.armor_piercing:
		dmg *= maxf(1.0 - 0.1 * float(target.armour), 0.1)
	return {"hit": true, "roll": int(roll), "miss_chance": int(miss_chance), "damage": maxi(int(dmg), 1)}
