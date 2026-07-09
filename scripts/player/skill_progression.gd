extends RefCounted
## Level-up rewards: unlocks + permanent upgrades applied to the player.
## Use via preload("res://scripts/player/skill_progression.gd").

## Ordered rewards. Index = level - 2 (first unlock at level 2).
const REWARDS: Array[Dictionary] = [
	{
		"id": "vitality",
		"title": "Vitality",
		"desc": "+25 Max Life",
		"type": "stat",
	},
	{
		"id": "embers",
		"title": "Embers",
		"desc": "Fireball +35% damage, +1 pierce",
		"type": "fireball",
	},
	{
		"id": "arc",
		"title": "Lightning Arc",
		"desc": "Unlocked! Press E to arc nearby foes",
		"type": "unlock_arc",
	},
	{
		"id": "swift",
		"title": "Swift Exile",
		"desc": "+10% move speed, dash recharges faster",
		"type": "mobility",
	},
	{
		"id": "cold_snap",
		"title": "Cold Snap",
		"desc": "Frost Nova +40% damage & wider radius",
		"type": "nova",
	},
	{
		"id": "blade",
		"title": "Sharp Edge",
		"desc": "Basic attack +25% damage, faster swings",
		"type": "basic",
	},
	{
		"id": "power",
		"title": "Power",
		"desc": "+10% all damage, +15 Max Life",
		"type": "power",
	},
]


static func reward_for_level(level: int) -> Dictionary:
	var idx := level - 2
	if idx < 0:
		return {}
	if idx < REWARDS.size():
		return REWARDS[idx]
	# Endless soft power after the scripted tree
	return {
		"id": "ascend_%d" % level,
		"title": "Ascendancy",
		"desc": "+8% damage, +10 Max Life",
		"type": "ascend",
	}


static func apply(player: Node, level: int) -> Dictionary:
	var reward := reward_for_level(level)
	if reward.is_empty() or player == null:
		return reward
	if not player.has_method("apply_skill_reward"):
		return reward
	player.apply_skill_reward(reward)
	return reward
