extends CharacterBody2D

# HYPERPARAMETERS FOR CHARACTER LOGIC
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 300

#SCRIPT VALUES
var current_rule_dict: Dictionary = {}
var ruleScript = 4
var weightRemainder = 0
var DSscript = []

#BOOL VALUES
var is_jumping = false
var is_attacking = false
var is_hurt = false

# PLAYER DETAILS
var upper_attacks_taken: int = 0
var lower_attacks_taken: int = 0
var upper_attacks_landed: int = 0
var lower_attacks_landed: int = 0

# WEIGHT ADJUSTMENT CONFIGURATIONS
var baseline = 0.5
var maxPenalty = 0.4
var maxReward = 0.4
var minWeight = 0.1
var maxWeight = 1.0
#var sumWeight = len(rules)/2

#ONREADY VARIABLES FOR OTHER PLAYER
@onready var animation = $AnimationPlayer
@onready var enemy = get_parent().get_node("PlayerCharacter1")
@onready var enemyAnimation = enemy.get_node("AnimationPlayer")
@onready var enemy_UpperHurtbox = enemy.get_node("Hurtbox_UpperBody")
@onready var enemy_LowerHurtbox = enemy.get_node("Hurtbox_LowerBody")
#ONREADY VARIABLES FOR THIS PLAYER
@onready var characterSprite = $AnimatedSprite2D
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var playerDetails = get_parent().get_node("PlayerDetailsUI/Player2Details")
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

# LOGGING SYSTEM
var log_file_path = "res://training.txt"
var cycle_used_rules = []

# === ENGINE CALLBACKS ===
func _ready():
#	MAKE AN INITIAL SCRIPT
	DSscript.clear()
	var initRules = rules.duplicate()
	initRules.shuffle()
	for i in range(ruleScript):
		initRules[i]["inScript"] = true
		DSscript.append(initRules[i])
	#
	#print("Rules in Script", DSscript)
	#print("Rulebase", rules)
	

	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

	# Start with an initial script generation
	generate_script()
	initialize_log_file()
	
func initialize_log_file():
	var file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if file:
		file.store_string("=== DS Character Log ===\n")
		file.close()

func log_script_generation():
	var timestamp = Time.get_datetime_string_from_system()
	var file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		
		# Header with timestamp
		file.store_string("\n--- Script Generated (Timer Update) | Timestamp: %s ---\n" % timestamp)
		
		# Generated Script section
		file.store_string("Generated Script:\n")
		file.store_string(JSON.stringify(DSscript, "  "))
		
		# Rules used in this cycle
		file.store_string("\nRules Executed in Last Cycle:\n")
		file.store_string(JSON.stringify(cycle_used_rules))
		
		# Parameters section
		file.store_string("\n--- End Log Entry ---")
		file.store_string("\n--- Parameters: %s ---\n" % JSON.stringify({
			"upper_attacks_taken": upper_attacks_taken,
			"lower_attacks_taken": lower_attacks_taken,
			"upper_attacks_landed": upper_attacks_landed,
			"lower_attacks_landed": lower_attacks_landed
		}))
		
		file.close()
		

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
	
	DamagedSystem()
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

	# Sort matched rules by prioritization (highest first)
	#matched_rules.sort_custom(Callable(self, "_sort_by_priority_desc"))

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
			# Record used rule for this cycle
			if not rule["ruleID"] in cycle_used_rules:
				cycle_used_rules.append(rule["ruleID"])
			
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
			#print("in idle state")
		"walk_forward":
			if enemy.global_position.x > global_position.x:
				velocity.x = speed
			else:
				velocity.x = -speed
			#print("in walk_forward state")
		"walk_backward":
			if enemy.global_position.x > global_position.x:
				velocity.x = -speed
			else:
				velocity.x = speed
			#print("in walk_backward state")
		"light_punch":
			animation.play("light_punch")
			upper_attacks_landed += 1
			updateDetails()
			_connect_attack_animation_finished()
			is_attacking = true
			velocity.x = 0
			velocity.y = 0
			#print("in light_punch state")
		"light_kick":
			animation.play("light_kick")
			upper_attacks_landed += 1
			updateDetails()
			_connect_attack_animation_finished()
			is_attacking = true
			velocity.x = 0
			velocity.y = 0
			#print("in light_kick state")
		_:
			print("Unknown action: %s" % str(action))



func generate_script():
	# Reset counters for new evaluation period
	var active = 0
	var inactive = 0
	
	# Count active rules in current script
	for rule in DSscript:
		if rule.get("wasUsed", false):
			active += 1
			
	# Skip adjustment if no meaningful data
	if active == ruleScript:
		_reset_rule_usage()
		return
		
	inactive = ruleScript - active
	var fitness = calculateFitness()
	
	# Calculate weight adjustment
	var weightAdjustment = calculateAdjustment(fitness)
	var compensation = -active * (weightAdjustment / inactive)
	
	# Apply weight adjustments with clamping
	for rule in rules:
		if rule.get("inScript", false):
			if rule.get("wasUsed", false):
				rule["weight"] += weightAdjustment
			else:
				rule["weight"] += compensation
			
			# Clamp weights and handle remainder
			if rule["weight"] < minWeight:
				weightRemainder += (rule["weight"] - minWeight)
				rule["weight"] = minWeight
			elif rule["weight"] > maxWeight:
				weightRemainder += (rule["weight"] - maxWeight)
				rule["weight"] = maxWeight
	
	# Distribute remainder to non-script rules
	DistributeRemainder()
	
	# Create new script based on updated weights
	_create_new_script()
	_reset_rule_usage()
	print("New script generated with weights: ", DSscript)
	
	log_script_generation()
	cycle_used_rules.clear()
	
	
func calculateFitness():
	var baseline = 0.5
	var offensivenessVal = (0.002 * upper_attacks_landed + 0.002 * lower_attacks_landed)
	#var defensivess = 0
	var penaltyVal = (-0.005 * lower_attacks_taken + -0.005 * upper_attacks_taken)
	
#	ADD DEFENSIVENESS LATER ON
	var raw_fitness = baseline + offensivenessVal + penaltyVal
	var fitness = clampf(raw_fitness, 0.0, 1.0)
	#print("fitness: ",fitness)
	return fitness

func calculateAdjustment(fitness: float) -> float:
	# Calculate performance delta
	var raw_delta = 0.0
	if fitness < baseline:
		raw_delta = (maxPenalty * (baseline - fitness)) / baseline
	else:
		raw_delta = (maxReward * (fitness - baseline)) / (1 - baseline)
	
	# Return the adjustment value
	if fitness < baseline:
		return -min(maxPenalty, raw_delta)
	return min(maxReward, raw_delta)
	
func _create_new_script():
	# First reset all inScript flags
	for rule in rules:
		rule["inScript"] = false
	
	DSscript.clear()
	
	# Create candidate list with weights
	var candidates = []
	for rule in rules:
		candidates.append({
			"rule": rule,
			"weight": rule["weight"],
			"random_tie": randf()  # Add randomness for tie-breaking
		})
	
	# Sort by weight descending, then random tie-breaker
	candidates.sort_custom(func(a, b):
		if a.weight != b.weight:
			return a.weight > b.weight
		return a.random_tie > b.random_tie
	)
	
	# Select top rules for new script
	for i in range(min(ruleScript, candidates.size())):
		var rule = candidates[i].rule
		rule["inScript"] = true
		DSscript.append(rule)
			
func _reset_rule_usage():
	for rule in rules:
		rule["wasUsed"] = false
		
	# Reset attack counters
	upper_attacks_taken = 0
	lower_attacks_taken = 0
	upper_attacks_landed = 0
	lower_attacks_landed = 0


func DistributeRemainder():
	if weightRemainder == 0:
		return
	
	var non_script_rules = []
	for rule in rules:
		if not rule.get("inScript", false):
			non_script_rules.append(rule)
	
	if non_script_rules.size() > 0:
		var per_rule_adjust = weightRemainder / non_script_rules.size()
		for rule in non_script_rules:
			rule["weight"] += per_rule_adjust
	
	weightRemainder = 0


func _connect_attack_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

# Callback function to reset attack state when animation finishes
func _on_attack_finished(anim_name):
	if anim_name == "light_punch" or anim_name == "light_kick":
		is_attacking = false
		#print("Attack animation finished:", anim_name)

func DamagedSystem():
	if $Hurtbox_LowerBody and $Hurtbox_LowerBody.has_signal("area_entered"):
		if not $Hurtbox_LowerBody.is_connected("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered")):
			$Hurtbox_LowerBody.connect("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered"))
	
	if $Hurtbox_UpperBody and $Hurtbox_UpperBody.has_signal("area_entered"):
		if not $Hurtbox_UpperBody.is_connected("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered")):
			$Hurtbox_UpperBody.connect("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered"))

func _on_hurtbox_upper_body_area_entered(area: Area2D):
	print("Upper body hit taken")
	is_hurt = true
	animation.play("light_hurt")
	lower_attacks_taken += 1
	updateDetails()
	_connect_hurt_animation_finished()


func _on_hurtbox_lower_body_area_entered(area: Area2D):
	print("Lower body hit taken")
	is_hurt = true
	animation.play("light_hurt")
	upper_attacks_taken += 1
	updateDetails()
	_connect_hurt_animation_finished()

func updateDetails():
	playerDetails.text = "Lower Attacks Taken: %d\nUpper Attacks Taken: %d\nLower Attacks Landed: %d\nUpper Attacks Landed: %d" % [
		lower_attacks_taken, upper_attacks_taken, 
		lower_attacks_landed, upper_attacks_landed	]
	
func _connect_hurt_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_hurt_finished")):
		animation.connect("animation_finished", Callable(self, "_on_hurt_finished"))

func _on_hurt_finished(anim_name):
	if anim_name == "light_hurt" or anim_name == "heavy_hurt":
		is_hurt = false
		print("Attack animation finished:", anim_name)
	pass
