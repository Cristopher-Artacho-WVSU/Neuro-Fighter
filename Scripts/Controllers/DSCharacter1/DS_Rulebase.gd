extends Node

class_name Rules


var rules = [
	{
		"ruleID": 1, "prioritization": 1,
		"conditions": { "distance": { "op": ">=", "value": 325 } },
		"enemy_action": ["walk_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 2, "prioritization": 11,
		"conditions": { "distance": { "op": "<=", "value": 325 }},
		"enemy_action": ["light_kick"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 3, "prioritization": 12,
		"conditions": { "distance": { "op": "<=", "value": 315 } },
		"enemy_action": ["light_punch"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 4, "prioritization": 21,
		"conditions": { "enemy_anim": "light_kick", "distance": { "op": ">=", "value": 315 }, "upper_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 5, "prioritization": 22,
		"conditions": { "enemy_anim": "light_punch", "distance": { "op": ">=", "value": 325 }, "upper_hits_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 6, "prioritization": 2,
		"conditions": { "distance": { "op": "<=", "value": 315 }, "lower_hits_taken": { "op": ">=", "value": 2 } },
		"enemy_action": ["walk_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 7, "prioritization": 100,
		"conditions": { "player_anim": "idle" },
		"enemy_action": ["idle"], "weight": 0.5, "wasUsed": false, "inScript": false
	}
]
