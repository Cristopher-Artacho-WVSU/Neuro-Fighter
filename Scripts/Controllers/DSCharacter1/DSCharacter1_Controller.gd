extends CharacterBody2D

# === STATE VARIABLES ===
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 300
var is_jumping = false
var is_attacking = false
var current_rule_dict: Dictionary = {}
var ruleScript = 4



# === ONREADY VARIABLES ===
@onready var animation = $AnimationPlayer
@onready var enemy = get_parent().get_node("PlayerCharacter1")
@onready var enemyAnimation = enemy.get_node("AnimationPlayer")
@onready var characterSprite = $AnimatedSprite2D
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]

# === RULES ===
var rules = [
	{
		"ruleID": 1, "prioritization": 1,
		"conditions": { "distance": { "op": ">=", "value": 325 } },
		"enemy_action": ["walk_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 2, "prioritization": 11,
		"conditions": { "distance": { "op": "<=", "value": 325 } },
		"enemy_action": ["light_kick"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 3, "prioritization": 12,
		"conditions": { "distance": { "op": "<=", "value": 315 } },
		"enemy_action": ["light_punch"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 4, "prioritization": 21,
		"conditions": { "enemy_anim": "light_kick", "distance": { "op": ">=", "value": 315 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 5, "prioritization": 22,
		"conditions": { "enemy_anim": "light_punch", "distance": { "op": ">=", "value": 325 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 6, "prioritization": 2,
		"conditions": { "distance": { "op": "<=", "value": 315 } },
		"enemy_action": ["walk_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 7, "prioritization": 100,
		"conditions": { "player_anim": "idle" },
		"enemy_action": ["idle"], "weight": 0.5, "wasUsed": false, "inScript": false
	}
]

# === ENGINE CALLBACKS ===
func _ready():
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

func update_facing_direction():
	if enemy.position.x > position.x:
		characterSprite.flip_h = false  # Face right
		for hitbox in hitboxGroup:
			hitbox.scale.x = 1  # Or flip_h if it's a Sprite/AnimatedSprite2D
		for hurtbox in hurtboxGroup:
			hurtbox.scale.x = 1
	else:
		characterSprite.flip_h = true   # Face left
		for hitbox in hitboxGroup:
			hitbox.scale.x = -1
		for hurtbox in hurtboxGroup:
			hurtbox.scale.x = -1

func _physics_process(delta):
	update_facing_direction()
	evaluate_and_execute(rules)
	# Gravity and jump handling
	if not is_on_floor():
		velocity.y += gravity * delta
		if not is_jumping:
			is_jumping = true
	else:
		velocity.y = 0
		if is_jumping:
			is_jumping = false
			if not is_attacking:
				animation.play("idle")

	move_and_slide()


func evaluate_and_execute(rules: Array):
	var enemy_anim = enemyAnimation.current_animation
	var distance = global_position.distance_to(enemy.global_position)
	var matched_rules = []

	for i in range(rules.size()):
		var rule = rules[i]
		var conditions = rule["conditions"]
		var match_all = true
		
		if match_all and "distance" in conditions:
			var cond = conditions["distance"]
			if not _compare_numeric(cond["op"], distance, cond["value"]):
				match_all = false
				continue
				
		if "player_anim" in conditions and conditions["player_anim"] != enemyAnimation.current_animation:
			match_all = false
			continue
		if match_all:
				matched_rules.append(i)  # Store the index
	#print(matched_rules)

	# Do something with matched_rules


	# Sort matched rules by prioritization (highest first)
	#matched_rules.sort_custom(Callable(self, "_sort_by_priority_desc"))

		# In DS_script.gd's evaluate_and_execute function:
	if matched_rules.size() > 0:
		var rule_index = matched_rules[0]  # matched_rules now stores indices
		var rule = rules[rule_index]
		var actions = rule.get("enemy_actions", [])

		if actions.size() == 0:
			var raw_action = rule.get("enemy_action", "idle")
			actions = [raw_action] if typeof(raw_action) == TYPE_STRING else raw_action

		var valid_actions = []
		for action in actions:
			if typeof(action) == TYPE_STRING:
				valid_actions.append(action)
			else:
				print("Invalid action type in rule %d: %s" % [rule.get("ruleID", -1), str(action)])

		if valid_actions.size() > 0:
			_execute_actions(valid_actions)
			var updated_rule = rule.duplicate()
			updated_rule["wasUsed"] = true
			rules[rule_index] = updated_rule

# Custom sort function
func _sort_by_priority_desc(a, b):
	#print(a["prioritization"], b["prioritization"])
	return int(b["prioritization"]) - int(a["prioritization"])


func _compare_numeric(op: String, current_value: int, rule_value: int) -> bool:
	match op:
		">=":
			return current_value >= rule_value
		"<=":
			return current_value <= rule_value
		">":
			return current_value > rule_value
		"<":
			return current_value < rule_value
		"==":
			return current_value == rule_value # Simple comparison for now
		_:
			print("Unknown comparison operator: ", op)
			return false


# This should already exist — ensure it’s accessible
func _execute_actions(actions: Array):
	if actions.is_empty():
		current_rule_dict = {}
		return
	
	for action in actions:
		_execute_single_action(action)


func get_rule_by_action(action) -> Dictionary:
	for rule in rules:
		var enemy_action = rule.get("enemy_action")
		
		# Handle array-based enemy_actions
		if enemy_action is Array:
			if action in enemy_action:
				return rule
		# Handle single string actions
		elif enemy_action == action:
			return rule
			
	return {}


func _execute_single_action(action):
	if typeof(action) == TYPE_DICTIONARY:
		action = action.get("action", "")
	
	match action:
		"idle":
			# e.g., set velocity to zero
			velocity.x = 0
			animation.play("idle")
			print("in idle state")
		"walk_forward":
			if enemy.global_position.x > global_position.x:
				velocity.x = speed
			else:
				velocity.x = -speed
			print("in walk_forward state")
		"walk_backward":
			if enemy.global_position.x > global_position.x:
				velocity.x = -speed
			else:
				velocity.x = speed
			print("in walk_backward state")
		"light_punch":
			animation.play("light_punch")
			_connect_animation_finished()
			is_attacking = true
			velocity.x = 0
			velocity.y = 0
			print("in light_punch state")
		"light_kick":
			animation.play("light_kick")
			_connect_animation_finished()
			is_attacking = true
			velocity.x = 0
			velocity.y = 0
			print("in light_kick state")
		_:
			print("Unknown action: %s" % str(action))

func generate_script(rules):
	var active = 0
	var inactive = 0
	var compensation = 0
	var remainder = 0
	var minweight = 0.1
	var maxweight = 1.0
	var weightAdjustment = 0
	
	
	for i in range(ruleScript):
		if rules[i].get("wasUsed", false):
			active += 1
	
	if active <= 0 or active >= ruleScript:
		return
		
	inactive = ruleScript - active
	#weightAdjustment = calculateAdjustment()
	#compensation = -active *(weightAdjustment/inactive)
	
	for i in range(ruleScript):
		if rules[i].get("wasUsed", false):
			rules[i]["weight"] += weightAdjustment
		else:
			rules[i]["weight"] += compensation
	
		if rules[i]["weight"] < minweight:
			remainder += (rules[i]["weight"]- minweight)
			rules[i]["weight"] = minweight
		elif rules[i]["weight"] > maxweight:
			remainder += (rules[i]["weight"]- maxweight)
			rules[i]["weight"] = maxweight
			
		#DistributeRemainder() #DISTRIBUTE WEIGHT ACROSS ALL RULES
	pass
	
	

func calculateAdjustment(fitness):
	
	pass


func DistributeRemainder():
	pass

func _connect_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

# Callback function to reset attack state when animation finishes
func _on_attack_finished(anim_name):
	if anim_name == "light_punch" or anim_name == "light_kick":
		is_attacking = false
		print("Attack animation finished:", anim_name)
