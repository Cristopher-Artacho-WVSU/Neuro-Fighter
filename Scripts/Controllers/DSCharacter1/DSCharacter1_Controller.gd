extends CharacterBody2D

# HYPERPARAMETERS FOR CHARACTER LOGIC
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# MOVEMENT VARIABLES
var base_speed: float = 300.0
var dash_speed: float = 1000.0
var dash_duration: float = 0.3
var dash_cooldown: float = 0.4
var current_dash_timer: float = 0.0
var dash_direction: int = 0
var is_dashing: bool = false
var dash_cooldown_timer: float = 0.0
var dash_velocity = Vector2.ZERO
var movement_smoothing: float = 8.0

#SCRIPT VALUES
var current_rule_dict: Dictionary = {}
var ruleScript = 5
var weightRemainder = 0
var DSscript = []

#BOOL VALUES
var is_jumping = false
var is_attacking = false
var is_hurt = false
var is_defended = false
var is_defending = false

# DEFENSE TIMERS
var idle_timer = 0.0
var backward_timer = 0.0
const DEFENSE_TRIGGER_TIME = 1.0  # 2 seconds

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
		"enemy_action": ["dash_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
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
		"conditions": { "enemy_anim": "light_kick", "distance": { "op": ">=", "value": 315 }, "upper_attacks_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 5, "prioritization": 22,
		"conditions": { "enemy_anim": "light_punch", "distance": { "op": ">=", "value": 325 }, "upper_attacks_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 6, "prioritization": 2,
		"conditions": { "distance": { "op": "<=", "value": 315 } },
		"enemy_action": ["dash_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 7, "prioritization": 100,
		"conditions": { "player_anim": "idle" },
		"enemy_action": ["idle"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 8, "prioritization": 21,
		"conditions": { "player_anim": "light_kick", "distance": { "op": ">=", "value": 325 }, "upper_attacks_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 9, "prioritization": 22,
		"conditions": { "player_anim": "light_punch", "distance": { "op": ">=", "value": 315 }, "upper_attacks_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["standing_defense"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 10, "prioritization": 30,
		"conditions": { "distance": { "op": ">=", "value": 400 } },
		"enemy_action": ["dash_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 11, "prioritization": 31,
		"conditions": { "distance": { "op": "<=", "value": 200 } },
		"enemy_action": ["dash_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 12, "prioritization": 40,
		"conditions": { "distance": { "op": "<=", "value": 250 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		"enemy_action": ["jump"], "weight": 0.5, "wasUsed": false, "inScript": false
	}
]

# LOGGING SYSTEM
var log_file_path = "res://training.txt"
var cycle_used_rules = []

# === ENGINE CALLBACKS ===
func _ready():
	# MAKE AN INITIAL SCRIPT
	print("DS PLAYER")
	DSscript.clear()
	for i in range(min(ruleScript, rules.size())):
		rules[i]["inScript"] = true
		DSscript.append(rules[i])
	
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

	# Start with an initial script generation
	generate_script()
	initialize_log_file()

func _physics_process(delta):
	if is_hurt:
		return
		
	update_facing_direction()
	handle_defense_triggers(delta)
	
	# Gravity and jump handling
	if not is_on_floor():
		velocity.y += gravity * delta
		if not is_jumping:
			is_jumping = true
		
		# Prevent horizontal movement while jumping (unless dashing)
		if not is_dashing:
			velocity.x = 0
	else:
		velocity.y = 0
		if is_jumping:
			is_jumping = false
			if not is_attacking:
				animation.play("idle")
	
	# Handle dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		
	# Handle active dash
	if is_dashing:
		current_dash_timer -= delta
		if current_dash_timer <= 0:
			end_dash()
		else:
			# Apply dash velocity
			velocity.x = dash_velocity.x
			# Smoothly end velocity at the end of dash
			if current_dash_timer < dash_duration * 0.3:
				velocity.x = lerp(0.0, float(dash_velocity.x), float(current_dash_timer) / (float(dash_duration) * 0.3))

	# Evaluate rules if not in a locked state
	if !is_attacking && !is_defending && !is_hurt && !is_dashing:
		evaluate_and_execute(rules)
	
	move_and_slide()

func handle_defense_triggers(delta):
	if is_attacking || is_jumping || is_hurt || is_dashing:
		idle_timer = 0.0
		backward_timer = 0.0
		is_defending = false
		return
	
	# If not moving, plus idle timer
	if velocity.x == 0 && is_on_floor():
		idle_timer += delta
		backward_timer = 0.0
	else:
		idle_timer = 0.0
		
		# Check moving backward
		var is_moving_backward = false
		if enemy.position.x > position.x:  # Enemy to the right
			is_moving_backward = velocity.x < 0
		else:  # Enemy to the left
			is_moving_backward = velocity.x > 0
		
		# Add timer if moving backward
		if is_moving_backward:
			backward_timer += delta
		else:
			backward_timer = 0.0
	
	# Trigger defense if conditions met
	if idle_timer >= DEFENSE_TRIGGER_TIME || backward_timer >= DEFENSE_TRIGGER_TIME:
		start_defense()

func start_defense():
	is_defending = true
	velocity.x = 0
	animation.play("standing_block")

func end_defense():
	is_defending = false
	animation.play("idle")

func start_dash(direction):
	# Only dash if on the ground
	if not is_on_floor():
		return
		
	# Set dash state
	is_dashing = true
	current_dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_velocity = Vector2(direction * dash_speed, 0)
	
	# Play dash animation
	if (enemy.position.x > position.x and direction > 0) or (enemy.position.x < position.x and direction < 0):
		animation.play("dash_forward")
	else:
		animation.play("dash_backward")

func end_dash():
	is_dashing = false
	velocity.x = 0
	animation.play("idle")

func update_facing_direction():
	if enemy.position.x > position.x:
		characterSprite.flip_h = false  # Face right
		for hitbox in hitboxGroup:
			hitbox.scale.x = 1
		for hurtbox in hurtboxGroup:
			hurtbox.scale.x = 1
	else:
		characterSprite.flip_h = true   # Face left
		for hitbox in hitboxGroup:
			hitbox.scale.x = -1
		for hurtbox in hurtboxGroup:
			hurtbox.scale.x = -1
	
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
				
		if match_all and "upper_attacks_taken" in conditions:
			var cond = conditions["upper_attacks_taken"]
			if not _compare_numeric(cond["op"], upper_attacks_taken, cond["value"]):
				match_all = false
				continue
				
		if "player_anim" in conditions and conditions["player_anim"] != enemyAnimation.current_animation:
			match_all = false
			continue
			
		if "rand_chance" in conditions:
			if randf() < conditions["rand_chance"]["value"]:
				match_all = false
				continue

		if match_all:
				matched_rules.append(i)  # Store the index

	# Sort matched rules by prioritization (highest first)
	matched_rules.sort_custom(Callable(self, "_sort_by_priority_desc"))

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
				
			# Update wasUsed in both arrays
			rules[rule_index]["wasUsed"] = true
			# Find and update the same rule in DSscript
			for script_rule in DSscript:
				if script_rule["ruleID"] == rule["ruleID"]:
					script_rule["wasUsed"] = true
					break

# Custom sort function
func _sort_by_priority_desc(a_index, b_index):
	var a_priority = rules[a_index]["prioritization"]
	var b_priority = rules[b_index]["prioritization"]
	return b_priority - a_priority

func _compare_numeric(op: String, current_value: float, rule_value: float) -> bool:
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
			return current_value == rule_value
		_:
			print("Unknown comparison operator: ", op)
			return false

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
			velocity.x = 0
			animation.play("idle")
		"light_punch":
			animation.play("light_punch")
			is_attacking = true
			velocity.x = 0
			velocity.y = 0
		"light_kick":
			animation.play("light_kick")
			is_attacking = true
			velocity.x = 0
			velocity.y = 0
		"standing_defense":
			animation.play("standing_block")
			is_defending = true
		"dash_forward":
			var direction = 1 if enemy.global_position.x > global_position.x else -1
			start_dash(direction)
		"dash_backward":
			var direction = -1 if enemy.global_position.x > global_position.x else 1
			start_dash(direction)
		"jump":
			if is_on_floor():
				velocity.y = -1200.0
				is_jumping = true
				animation.play("jump")
		_:
			print("Unknown action: %s" % str(action))

func generate_script():
	# Reset counters for new evaluation period
	var active = 0
	var inactive = 0
	
	log_script_generation()
	cycle_used_rules.clear()
	
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
	#print("New script generated with weights: ", DSscript)
	print(rules)
	printSumWeights()
	
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

# Callback function to reset attack state when animation finishes
func _on_attack_finished(anim_name):
	print("Callback from function _on_attack_finished")
	match anim_name:
		"light_punch", "light_kick":
			is_attacking = false
			for hitbox in get_tree().get_nodes_in_group("Player2_Hitboxes"):
				if hitbox.overlaps_area(enemy_UpperHurtbox):
					upper_attacks_landed += 1
					updateDetails()
				elif hitbox.overlaps_area(enemy_LowerHurtbox):
					lower_attacks_landed += 1
					updateDetails()
		"standing_block":
			end_defense()
		"dash_forward", "dash_backward":
			end_dash()


func DamagedSystem():
	if $Hurtbox_LowerBody and $Hurtbox_LowerBody.has_signal("area_entered"):
		if not $Hurtbox_LowerBody.is_connected("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered")):
			$Hurtbox_LowerBody.connect("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered"))
	
	if $Hurtbox_UpperBody and $Hurtbox_UpperBody.has_signal("area_entered"):
		if not $Hurtbox_UpperBody.is_connected("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered")):
			$Hurtbox_UpperBody.connect("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered"))

func _on_hurtbox_upper_body_area_entered(area: Area2D):
	#	MADE GROUP FOR ENEMY NODES "Player1_Hitboxes" 
	if area.is_in_group("Player1_Hitboxes"):
		print("Player 2Upper body hit taken")
		is_hurt = true
		animation.play("light_hurt")
		lower_attacks_taken += 1
		updateDetails()
		_connect_hurt_animation_finished()


func _on_hurtbox_lower_body_area_entered(area: Area2D):
	
	#	MADE GROUP FOR ENEMY NODES "Player1_Hitboxes" 
	if area.is_in_group("Player1_Hitboxes"):
		print("Player 2 Lower body hit taken")
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
		if get_parent().has_method("apply_damage_to_player2"):
			if is_defended:
				get_parent().apply_damage_to_player2(7)
			else:
				get_parent().apply_damage_to_player2(10)
		is_hurt = false
		print("Attack animation finished:", anim_name)

func printSumWeights():
	var totalWeight = 0.0
	for rule in rules:
		totalWeight += rule.get("weight", 0.0)
	print("Total Rule Weight:", totalWeight)
	
func KO():
	animation.play("knocked_down")
	_connect_hurt_animation_finished()
