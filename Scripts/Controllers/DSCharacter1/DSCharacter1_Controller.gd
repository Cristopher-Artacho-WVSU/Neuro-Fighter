extends CharacterBody2D

<<<<<<< HEAD
#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#JUMP
var jump_speed = 3000  # example, tune as needed
var fall_multiplier = 5.0
var jump_multiplier = 1.6

#HITSTOPS
var hitstop_id: int = 0
var is_in_global_hitstop: bool = false
var is_recently_hit: bool = false
=======
# ===== CONSTANTS AND CONFIGURATION =====
var DEFENSE_TRIGGER_TIME = 1.0
var DASH_TIME = 0.5
var DASH_SPEED = 300
var JUMP_FORCE = -1200.0
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")

<<<<<<< HEAD
var jump_speed = 1000  # example, tune as needed
var fall_multiplier = 3.0
var jump_multiplier = 1.2

=======
>>>>>>> c3d067e (save before rebase)
# ===== AI CONFIGURATION =====
var ruleScript = 5
var baseline = 0.5
var maxPenalty = 0.4
var maxReward = 0.4
var minWeight = 0.1
var maxWeight = 1.0
>>>>>>> 483be1a (latest commit)

# ===== NODE REFERENCES =====
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var enemy = get_parent().get_node("PlayerCharacter1")
@onready var enemyAnimation = enemy.get_node("AnimationPlayer")
@onready var enemy_UpperHurtbox = enemy.get_node("Hurtbox_UpperBody")
@onready var enemy_LowerHurtbox = enemy.get_node("Hurtbox_LowerBody")
<<<<<<< HEAD
@onready var prev_distance_to_enemy = abs(enemy.position.x - position.x)

#VALUE VARIABLES
#DASHING MOVEMENT
var dash_speed = 300
var dash_time = 0.5
var dash_timer = 0.0
var dash_direction = 0
=======
@onready var playerDetails = get_parent().get_node("PlayerDetailsUI/Player2Details")
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var generateScript_timer = Timer.new()
>>>>>>> 483be1a (latest commit)

<<<<<<< HEAD
#DEFENSE 
var last_input_time = 0.0
var defense_delay = 0.5

=======
>>>>>>> c3d067e (save before rebase)
# ===== AI STATE MANAGEMENT =====
var ai_state_manager: Node
var current_fitness = 0.5
var current_rule_dict: Dictionary = {}
var weightRemainder = 0
var DSscript = []
var cycle_used_rules = []

# ===== COMBAT STATISTICS =====
var upper_attacks_taken: int = 0
var lower_attacks_taken: int = 0
var upper_attacks_landed: int = 0
var lower_attacks_landed: int = 0
var upper_attacks_blocked: int = 0
var lower_attacks_blocked: int = 0

# ===== MOVEMENT STATE =====
var is_dashing = false
var is_jumping = false
var is_crouching = false
var dash_timer = 0.0
var dash_direction = 0
<<<<<<< HEAD
=======
var prev_distance_to_enemy = 0.0
>>>>>>> c3d067e (save before rebase)

# ===== COMBAT STATE =====
var is_attacking = false
var is_defending = false
var is_hurt = false
var is_defended = false

# ===== DEFENSE TIMERS =====
var idle_timer = 0.0
var backward_timer = 0.0
<<<<<<< HEAD
var prev_distance_to_enemy = 0.0

var log_file_path = "res://training.txt"
=======
var last_input_time = 0.0
>>>>>>> c3d067e (save before rebase)

<<<<<<< HEAD
#CALCULATING THE ACTION 
var last_action: String

=======
# ===== RULE SYSTEM =====
>>>>>>> 483be1a (latest commit)
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
		"ruleID": 4, "prioritization": 13,
		"conditions": { "distance": { "op": "<=", "value": 325 } },
		"enemy_action": ["crouch_lightKick"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 5, "prioritization": 14,
		"conditions": { "distance": { "op": "<=", "value": 315 } },
		"enemy_action": ["crouch_lightPunch"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 6, "prioritization": 41,
		"conditions": { "distance": { "op": ">=", "value": 345 }, "upper_attacks_landed": { "op": ">=", "value": 1 } },
		"enemy_action": ["heavy_kick"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 7, "prioritization": 42,
		"conditions": { "distance": { "op": ">=", "value": 345 }, "upper_attacks_landed": { "op": ">=", "value": 1 } },
		"enemy_action": ["heavy_punch"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 8, "prioritization": 2,
		"conditions": { "distance": { "op": "<=", "value": 315 } },
		"enemy_action": ["dash_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 9, "prioritization": 23,
		"conditions": {  "enemy_anim": "light_kick", "distance": { "op": "<=", "value": 345 },  "upper_attacks_taken": { "op": ">=", "value": 1 } },
		"enemy_action": ["crouch"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 10, "prioritization": 24,
		"conditions": {  "enemy_anim": "light_punch", "distance": { "op": "<=", "value": 315 } },
		"enemy_action": ["crouch"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 11, "prioritization": 100,
		"conditions": { "player_anim": "idle" },
		"enemy_action": ["idle"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 13, "prioritization": 51,
		"conditions": { "distance": { "op": "<=", "value": 250 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		"enemy_action": ["jump"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
		{
		"ruleID": 14, "prioritization": 42,
		"conditions": { "distance": { "op": ">=", "value": 315 }, "lower_attacks_landed": { "op": ">=", "value": 1 } },
		"enemy_action": ["crouch_heavyPunch"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
		{
		"ruleID": 15, "prioritization": 52,
		"conditions": { "distance": { "op": "<=", "value": 350 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		"enemy_action": ["jump_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
		{
		"ruleID": 16, "prioritization": 53,
		"conditions": { "distance": { "op": "<=", "value": 250 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		"enemy_action": ["jump_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
]

# ===== INITIALIZATION =====
func _ready():
<<<<<<< HEAD
	updateDetails()
	if enemy and enemy.has_node("AnimationPlayer"):
		print("AnimationPlayer of Enemy detected")
=======
	initialize_ai_state_manager()
	initialize_character_state()
	setup_connections()
	start_script_generation_timer()

func initialize_ai_state_manager():
	ai_state_manager = get_node("/root/AI_StateManager")
	if not ai_state_manager:
		ai_state_manager = get_node_or_null("/root/AIStateManager")
		if not ai_state_manager:
			print("WARNING: AI_StateManager not found - state saving disabled")
			ai_state_manager = Node.new()
	
	load_saved_states()

func initialize_character_state():
	prev_distance_to_enemy = abs(enemy.position.x - position.x)
	
	# Reset all states
>>>>>>> 483be1a (latest commit)
	is_dashing = false
	is_jumping = false
	is_crouching = false
	is_attacking = false
	is_defending = false
	is_hurt = false
	
	# Create initial script
	DSscript.clear()
	for i in range(min(ruleScript, rules.size())):
		rules[i]["inScript"] = true
		DSscript.append(rules[i])
	
<<<<<<< HEAD
<<<<<<< HEAD
	print("DS PLAYER Initialized with script: ", DSscript.size(), " rules")
=======
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))
	
	DamagedSystem()
>>>>>>> 8b50887 (added temporary damage)
=======
	print("DS PLAYER Initialized with script: ", DSscript.size(), " rules")
>>>>>>> c3d067e (save before rebase)

func setup_connections():
	DamagedSystem()
	
	if not animation.is_connected("animation_finished", _on_animation_finished):
		animation.connect("animation_finished", _on_animation_finished)

func start_script_generation_timer():
	add_child(generateScript_timer)
	generateScript_timer.wait_time = 4.0
	generateScript_timer.one_shot = false
	generateScript_timer.start()
	generateScript_timer.connect("timeout", _on_generateScript_timer_timeout)

# ===== PHYSICS AND MOVEMENT =====
func _physics_process(delta):
	updateDetails()
	update_facing_direction()
	apply_gravity(delta)
	
	if !is_attacking && !is_defending && !is_hurt && !is_dashing:
		evaluate_and_execute(rules)
	
<<<<<<< HEAD
	DamagedSystem(delta)
	debug_states()
=======
>>>>>>> 483be1a (latest commit)
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if not is_jumping:
			is_jumping = true
	else:
		if velocity.y > 0:
			velocity.y = 0
		if is_jumping:
			is_jumping = false

func update_facing_direction():
	if not is_instance_valid(enemy):
		return
		
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

func MovementSystem(ai_move_direction: int, delta := 1.0 / 60.0):
	if is_attacking || is_jumping || is_defending || is_hurt:
		return
		
	var curr_distance_to_enemy = abs(enemy.position.x - position.x)
	
	if not is_dashing:
		if ai_move_direction == 1:
			is_dashing = true
			dash_direction = 1
			dash_timer = DASH_TIME
		elif ai_move_direction == -1:
			is_dashing = true
			dash_direction = -1
			dash_timer = DASH_TIME
		
	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = 0
			
	# Movement animations
	if velocity.x != 0:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("move_forward")
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("move_backward")
	
	prev_distance_to_enemy = curr_distance_to_enemy

# ===== RULE-BASED AI SYSTEM =====
func evaluate_and_execute(rules: Array):
	var enemy_anim = enemyAnimation.current_animation
	var distance = global_position.distance_to(enemy.global_position)
	var matched_rules = []

	for i in range(DSscript.size()):
		var rule = DSscript[i]
		var conditions = rule["conditions"]
		var match_all = true
		
		if match_all and "distance" in conditions:
			var cond = conditions["distance"]
			if not _compare_numeric(cond["op"], distance, cond["value"]):
				match_all = false
				continue
				
		if match_all and "upper_attacks_landed" in conditions:
			var cond = conditions["upper_attacks_landed"]
			if not _compare_numeric(cond["op"], upper_attacks_landed, cond["value"]):
				match_all = false
				continue
				
		if match_all and "lower_attacks_landed" in conditions:
			var cond = conditions["lower_attacks_landed"]
			if not _compare_numeric(cond["op"], lower_attacks_landed, cond["value"]):
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
			matched_rules.append(i)

	# Sort matched rules by prioritization (highest first)
	matched_rules.sort_custom(_sort_by_priority_desc)

	if matched_rules.size() > 0:
		var rule_index = matched_rules[0]
		var rule = rules[rule_index]
		var actions = rule.get("enemy_actions", [])

		if actions.size() == 0:
			var raw_action = rule.get("enemy_action", "idle")
			actions = [raw_action] if typeof(raw_action) == TYPE_STRING else raw_action

		var valid_actions = []
		for action in actions:
			if typeof(action) == TYPE_STRING:
				valid_actions.append(action)

		if valid_actions.size() > 0:
			_execute_actions(valid_actions)
			if not rule["ruleID"] in cycle_used_rules:
				cycle_used_rules.append(rule["ruleID"])
				
			rules[rule_index]["wasUsed"] = true
			for script_rule in DSscript:
				if script_rule["ruleID"] == rule["ruleID"]:
					script_rule["wasUsed"] = true
					break

func _compare_numeric(op: String, current_value: float, rule_value: float) -> bool:
	match op:
		">=": return current_value >= rule_value
		"<=": return current_value <= rule_value
		">": return current_value > rule_value
		"<": return current_value < rule_value
		"==": return current_value == rule_value
		_: 
			print("Unknown comparison operator: ", op)
			return false

func _sort_by_priority_desc(a_index, b_index):
	var a_priority = rules[a_index]["prioritization"]
	var b_priority = rules[b_index]["prioritization"]
	return b_priority - a_priority

func _execute_actions(actions: Array):
	if actions.is_empty():
		current_rule_dict = {}
		return
	
	for action in actions:
		_execute_single_action(action)

func _execute_single_action(action):
	if typeof(action) == TYPE_DICTIONARY:
		action = action.get("action", "")
	
	match action:
		"idle":
<<<<<<< HEAD
			if is_on_floor():
				if not is_jumping:
					velocity.x = 0
					animation.play("idle")
					#_connect_animation_finished()
		"light_punch":
			if is_on_floor():
				if not is_jumping:
					animation.play("light_punch")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					#_connect_animation_finished()
		"light_kick":
			if is_on_floor():
				if not is_jumping:
					animation.play("light_kick")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					_connect_animation_finished()
		"standing_defense":
			if is_on_floor():
				if not is_jumping:
					animation.play("standing_block")
					is_defending = true
					_connect_animation_finished()
		"dash_forward":
			if is_on_floor():
				if not is_jumping:
					var direction = 1 if enemy.global_position.x > global_position.x else -1
					MovementSystem(direction)
					animation.play("move_forward")
					#_connect_animation_finished()
		"dash_backward":
			if is_on_floor():
				if not is_jumping:
					var direction = -1 if enemy.global_position.x > global_position.x else 1
					MovementSystem(direction)
					animation.play("move_backward")
					#print("dash_backward")
					#_connect_animation_finished()
		"jump":
			if is_on_floor():
				if not is_jumping:
					animation.play("jump")
					print("Jumped")
					velocity.y = -1200.0
					is_jumping = true
					_connect_animation_finished()
				
		"jump_forward":
			if is_on_floor():
				if not is_jumping:
					animation.play("jump_forward")
					print("Jumped")
					var direction = 1 if enemy.global_position.x > global_position.x else -1
					MovementSystem(direction)
					velocity.y = -1200.0
					is_jumping = true
					_connect_animation_finished()
				
		"jump_backward":
			if is_on_floor():
				if not is_jumping:
					animation.play("jump_backward")
					print("Jumped")
					var direction = -1 if enemy.global_position.x > global_position.x else 1
					MovementSystem(direction)
					velocity.y = -1200.0
					is_jumping = true
					_connect_animation_finished()
					
		"crouch":
			if is_on_floor():
				if not is_jumping:
					animation.play("crouch")
					velocity.x = 0
					velocity.y = 0
					_connect_animation_finished()
		"crouch_lightKick":
			if is_on_floor():
				if not is_jumping:
					animation.play("crouch_lightKick")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					_connect_animation_finished()
		"crouch_lightPunch":
			if is_on_floor():
				if not is_jumping:
					animation.play("crouch_lightPunch")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					_connect_animation_finished()
					
		"heavy_punch":
			if is_on_floor():
				if not is_jumping:
					animation.play("heavy_punch")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					#_connect_animation_finished()
		"heavy_kick":
			if is_on_floor():
				if not is_jumping:
					animation.play("heavy_kick")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					_connect_animation_finished()
					
		"crouch_lightPunch":
			if is_on_floor():
				if not is_jumping:
					animation.play("crouch_heavyPunch")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					_connect_animation_finished()
		_:
			print("Unknown action: %s" % str(action))
	last_action = action
	#print(last_action)
	#is_dashing = false
	_connect_animation_finished()

func debug_states():
	#print("is_dashing: ", is_dashing)
	#print("is_jumping state: ", is_jumping)
	#print("is_crouching: ", is_crouching)
	#print("is_attacking state:", is_attacking)
	print("is_defending: ", is_defending)
	#print("is_hurt state:", is_hurt)
	#print("is_is_dashing: ", is_dashing)
	pass
	
func update_facing_direction():
	if not is_instance_valid(enemy):
		print("Enemy not found")
		return
		
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

#GET THE OPERATOR FROM 'op', AND COMPARE THE REQUIRED VALUES TO THE CURRENT 
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


#FOR MOVEMENT
func MovementSystem(ai_move_direction: int, delta := 1.0 / 60.0):
	if is_attacking || is_jumping || is_defending || is_hurt:
		return
		
	var curr_distance_to_enemy = abs(enemy.position.x - position.x)
	
	if not is_dashing:
		if ai_move_direction == 1:
			is_dashing = true
			dash_direction = 1
			dash_timer = dash_time
		elif ai_move_direction == -1:
			is_dashing = true
			dash_direction = -1
			dash_timer = dash_time
		
	if is_dashing:
		velocity.x = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = 0

	
	# Movement animations
	if velocity.x != 0:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("move_forward")
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("move_backward")
	
	prev_distance_to_enemy = curr_distance_to_enemy
#
func _sort_by_priority_desc(a_index, b_index):
	var a_priority = rules[a_index]["prioritization"]
	var b_priority = rules[b_index]["prioritization"]
	return b_priority - a_priority

#PASS ANIM NAME TO THE _on_animation_finished FUNCTION
func _connect_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))

#FOR ANIMATIONS IN ORDER TO NOT GET CUT OFF
func _on_animation_finished(anim_name: String):
	match anim_name:
		"light_punch", "light_kick", "crouch_lightPunch", "crouch_lightKick":
			is_attacking = false
		"standing_block":
			is_defending = false
		"hurt", "crouch_hurt":
			is_hurt = false
		"jump":
			is_jumping = false
		"crouch":
			is_crouching = false
		"move_forward":
			is_dashing = false
		"move_backward":
			is_dashing = false
=======
			velocity.x = 0
			animation.play("idle")
		"light_punch":
			animation.play("light_punch")
			is_attacking = true
			velocity.x = 0
		"light_kick":
			animation.play("light_kick")
			is_attacking = true
			velocity.x = 0
		"standing_defense":
			animation.play("standing_block")
			is_defending = true
		"dash_forward":
			var direction = 1 if enemy.global_position.x > global_position.x else -1
			MovementSystem(direction)
			animation.play("move_forward")
		"dash_backward":
			var direction = -1 if enemy.global_position.x > global_position.x else 1
			MovementSystem(direction)
			animation.play("move_backward")
		"jump":
			if is_on_floor():
				velocity.y = JUMP_FORCE
				is_jumping = true
				animation.play("jump")
		"crouch":
			animation.play("crouch")
			velocity.x = 0
		"crouch_lightKick":
			animation.play("crouch_lightKick")
			is_attacking = true
			velocity.x = 0
		"crouch_lightPunch":
			animation.play("crouch_lightPunch")
			is_attacking = true
			velocity.x = 0
		_:
			print("Unknown action: %s" % str(action))
>>>>>>> 483be1a (latest commit)

# ===== SCRIPT GENERATION AND LEARNING =====
func generate_script():
	var active = 0
	var inactive = 0
	
	cycle_used_rules.clear()
	
	# Count active rules in current script
	for rule in DSscript:
		if rule.get("wasUsed", false):
			active += 1
	
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
			
			if rule["weight"] < minWeight:
				weightRemainder += (rule["weight"] - minWeight)
				rule["weight"] = minWeight
			elif rule["weight"] > maxWeight:
				weightRemainder += (rule["weight"] - maxWeight)
				rule["weight"] = maxWeight
	
	DistributeRemainder()
	_create_new_script()
	_reset_rule_usage()
	print("New script generated with weights")
	printSumWeights()

func calculateFitness():
	var offensivenessVal = (0.002 * upper_attacks_landed + 0.002 * lower_attacks_landed)
	var defensiveness = (0.003 * upper_attacks_blocked + 0.003 * lower_attacks_blocked)
	var penaltyVal = (-0.005 * lower_attacks_taken + -0.005 * upper_attacks_taken)
	
	var raw_fitness = baseline + offensivenessVal + defensiveness + penaltyVal 
	return clampf(raw_fitness, 0.0, 1.0)

func calculateAdjustment(fitness: float) -> float:
	var raw_delta = 0.0
	if fitness < baseline:
		raw_delta = (maxPenalty * (baseline - fitness)) / baseline
	else:
		raw_delta = (maxReward * (fitness - baseline)) / (1 - baseline)
	
	if fitness < baseline:
		return -min(maxPenalty, raw_delta)
	return min(maxReward, raw_delta)

func _create_new_script():
	for rule in rules:
		rule["inScript"] = false
	
	DSscript.clear()
	
	var candidates = []
	for rule in rules:
		candidates.append({
			"rule": rule,
			"weight": rule["weight"],
			"random_tie": randf()
		})
	
	candidates.sort_custom(func(a, b):
		if a.weight != b.weight:
			return a.weight > b.weight
		return a.random_tie > b.random_tie
	)
	
	for i in range(min(ruleScript, candidates.size())):
		var rule = candidates[i].rule
		rule["inScript"] = true
		DSscript.append(rule)

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

func _reset_rule_usage():
	for rule in rules:
		rule["wasUsed"] = false
		
	upper_attacks_taken = 0
	lower_attacks_taken = 0
	upper_attacks_landed = 0
	lower_attacks_landed = 0

<<<<<<< HEAD
func DamagedSystem(delta):
#	DEFENSIVE MECHANISM
	if last_action!= "idle":
		last_input_time = 0.0
		is_defending = false
	else:
		last_input_time += delta
		if last_input_time >= defense_delay:
			is_defending = true
			
	if $Hurtbox_LowerBody and $Hurtbox_LowerBody.has_signal("area_entered"):
		if not $Hurtbox_LowerBody.is_connected("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered")):
			$Hurtbox_LowerBody.connect("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered"))
=======
# ===== COMBAT AND DAMAGE SYSTEM =====
func DamagedSystem():
	if $Hurtbox_LowerBody and not $Hurtbox_LowerBody.is_connected("area_entered", _on_hurtbox_lower_body_area_entered):
		$Hurtbox_LowerBody.connect("area_entered", _on_hurtbox_lower_body_area_entered)
>>>>>>> 483be1a (latest commit)
	
	if $Hurtbox_UpperBody and not $Hurtbox_UpperBody.is_connected("area_entered", _on_hurtbox_upper_body_area_entered):
		$Hurtbox_UpperBody.connect("area_entered", _on_hurtbox_upper_body_area_entered)

func _on_hurtbox_upper_body_area_entered(area: Area2D):
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	if area.is_in_group("Player1_Hitboxes"):
		is_recently_hit = true  # Mark as hit immediately
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.3)  # brief pause (0.2 seconds)
			animation.play("standing_block") 
			upper_attacks_blocked += 1
			if get_parent().has_method("apply_damage_to_player1"):
				get_parent().apply_damage_to_player2(7)
			print(" Upper Damaged From Blocking")
		else:
			is_hurt = true
			apply_hitstop(0.3)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
<<<<<<< HEAD
<<<<<<< HEAD
			print("Player 2 Upper body hit taken")
			upper_attacks_taken += 1
=======
=======
>>>>>>> e6c2bc7 (save before rebase)
		print("Player 2 Upper body hit taken")
=======
		print("Player 2 Lower body hit taken")
>>>>>>> c3d067e (save before rebase)
		upper_attacks_taken += 1
		updateDetails()
>>>>>>> 483be1a (latest commit)
		_connect_hurt_animation_finished()
		# Reset hit immunity after short real-time delay
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false

<<<<<<< HEAD
func _on_hurtbox_lower_body_area_entered(area: Area2D):
<<<<<<< HEAD
<<<<<<< HEAD
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	#	MADE GROUP FOR ENEMY NODES "Player1_Hitboxes" 
=======
>>>>>>> 483be1a (latest commit)
=======
=======

func _on_hurtbox_lower_body_area_entered(area: Area2D):
	#	MADE GROUP FOR ENEMY NODES "Player1_Hitboxes" 
>>>>>>> c3d067e (save before rebase)
>>>>>>> e6c2bc7 (save before rebase)
	if area.is_in_group("Player1_Hitboxes"):
		is_recently_hit = true  # Mark as hit immediately
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.3)  # brief pause (0.2 seconds)
			animation.play("standing_block")
			if get_parent().has_method("apply_damage_to_player1"):
				get_parent().apply_damage_to_player2(7)
			lower_attacks_blocked += 1
			print("Lower Damaged From Blocking")
		else:
			is_hurt = true
			apply_hitstop(0.3)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			print("Player 2 Lower body hit taken")
			lower_attacks_taken += 1
		_connect_hurt_animation_finished()
<<<<<<< HEAD
<<<<<<< HEAD
		
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false

=======
	
>>>>>>> 483be1a (latest commit)
=======
	
=======

>>>>>>> c3d067e (save before rebase)
>>>>>>> e6c2bc7 (save before rebase)
func _connect_hurt_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_hurt_finished")):
		animation.connect("animation_finished", Callable(self, "_on_hurt_finished"))
		
	
func _on_hurt_finished(anim_name):
#	IF is_defending, REDUCE THE DAMAGE BY 30%
	#if is_defending and anim_name == "standing_block":
		#if get_parent().has_method("apply_damage_to_player1"):
			#get_parent().apply_damage_to_player2(7)
			#print("Damaged From Blocking")
	#else:
#		IF DS IS NOT DEFENDING WHENT THE DAMAGE RECEIVED
	if anim_name == "light_hurt" or anim_name == "heavy_hurt":
		if get_parent().has_method("apply_damage_to_player1"):
			get_parent().apply_damage_to_player2(10)
	is_hurt = false
	is_attacking = false
	is_defending = false
	is_dashing = false
	animation.play("idle")

func updateDetails():
	playerDetails.text = "Lower Attacks Taken: %d\nUpper Attacks Taken: %d\nLower Attacks Landed: %d\nUpper Attacks Landed: %d \nUpper Attacks Blocked: %d \nLower Attacks Blocked: %d" % [
		lower_attacks_taken, upper_attacks_taken, 
		lower_attacks_landed, upper_attacks_landed, upper_attacks_blocked, lower_attacks_blocked]

<<<<<<< HEAD
func applyGravity(delta):
	if not is_on_floor():
		# If moving up (jumping), apply gravity faster than default
		if velocity.y < 0:
			velocity.y += gravity * jump_multiplier * delta
		else:
			# If moving down (falling), apply even stronger gravity
			velocity.y += gravity * fall_multiplier * delta
		if not is_jumping:
			is_jumping = true
	else:
		if velocity.y > 0:
			velocity.y = 0
			velocity.x = 0
		if is_jumping:
=======
func KO():
	animation.play("knocked_down")

# ===== ANIMATION HANDLING =====
func _on_animation_finished(anim_name: String):
	match anim_name:
		"light_punch", "light_kick", "crouch_lightPunch", "crouch_lightKick":
			is_attacking = false
<<<<<<< HEAD
			#check_attack_hit()
=======
			check_attack_hit()
>>>>>>> c3d067e (save before rebase)
		"standing_block":
			is_defending = false
		"hurt", "crouch_hurt":
			is_hurt = false
		"jump":
>>>>>>> 483be1a (latest commit)
			is_jumping = false
		"crouch":
			is_crouching = false
		"move_forward", "move_backward":
			is_dashing = false

func check_attack_hit():
	for hitbox in get_tree().get_nodes_in_group("Player2_Hitboxes"):
		if hitbox.overlaps_area(enemy_UpperHurtbox):
			upper_attacks_landed += 1
			updateDetails()
		elif hitbox.overlaps_area(enemy_LowerHurtbox):
			lower_attacks_landed += 1
			updateDetails()

# ===== AI STATE MANAGEMENT =====
func save_current_rules(label: String, metadata: Dictionary = {}):
	if not ai_state_manager or ai_state_manager.get_script() == null:
		print("WARNING: AI_StateManager not available - cannot save rules")
		return
		
	var save_metadata = {
		"fitness": current_fitness,
		"upper_attacks_landed": upper_attacks_landed,
		"lower_attacks_landed": lower_attacks_landed,
		"upper_attacks_taken": upper_attacks_taken,
		"lower_attacks_taken": lower_attacks_taken,
		"timestamp": Time.get_datetime_string_from_system()
	}
	save_metadata.merge(metadata, true)
	
	ai_state_manager.save_state(label, rules, save_metadata)
	print("Rules saved with label: ", label)

func load_rules(label: String):
	if not ai_state_manager or ai_state_manager.get_script() == null:
		print("WARNING: AI_StateManager not available - cannot load rules")
		return
		
	var loaded_rules = ai_state_manager.load_state(label)
	if loaded_rules and loaded_rules.size() > 0:
		rules = loaded_rules
		_create_new_script()
		print("Rules loaded successfully: ", label)
		
		var metadata = ai_state_manager.get_state_metadata(label)
		if metadata.has("fitness"):
			current_fitness = metadata["fitness"]
			print("Loaded fitness: ", current_fitness)
	else:
		print("No rules found for label: ", label)

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> c3d067e (save before rebase)
func load_saved_states():
	if Global.player1_saved_state != "":
		load_rules(Global.player1_saved_state)
	if Global.player2_saved_state != "":
		load_rules(Global.player2_saved_state)
<<<<<<< HEAD
=======
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
		animation.play("move_forward")
	else:
		animation.play("move_backward")

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
	
	current_fitness = fitness  # Track current fitness
	print("Script generated - Fitness: ", fitness)
	
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
>>>>>>> 8b50887 (added temporary damage)
=======
>>>>>>> c3d067e (save before rebase)

# ===== UTILITY AND DEBUG FUNCTIONS =====
func printSumWeights():
	var totalWeight = 0.0
	for rule in rules:
		totalWeight += rule.get("weight", 0.0)
	print("Total Rule Weight:", totalWeight)

func print_ai_state():
	print("=== AI STATE DEBUG ===")
	print("Current Fitness: ", current_fitness)
	print("Active Rules in Script: ", DSscript.size())
	print("Upper Attacks Landed: ", upper_attacks_landed)
	print("Lower Attacks Landed: ", lower_attacks_landed)
	print("Upper Attacks Taken: ", upper_attacks_taken)
	print("Lower Attacks Taken: ", lower_attacks_taken)
	print("Total Rule Weight: ", get_total_rule_weight())
	
	var sorted_rules = rules.duplicate()
	sorted_rules.sort_custom(func(a, b): return a["weight"] > b["weight"])
	
	print("Top 3 Rules by Weight:")
	for i in range(min(3, sorted_rules.size())):
		var rule = sorted_rules[i]
		print("  Rule %d: %s (weight: %.2f)" % [rule["ruleID"], rule["enemy_action"], rule["weight"]])

func get_total_rule_weight() -> float:
	var total = 0.0
	for rule in rules:
		total += rule.get("weight", 0.0)
	return total

# ===== TIMER CALLBACKS =====
func _on_generateScript_timer_timeout():
	generate_script()
	
func displacement_small():
	velocity.x = 100
	
func displacement_verySmall():
	velocity.x = 50

func apply_hitstop(hitstop_duration: float, slowdown_factor: float = 0.05) -> void:
	hitstop_id += 1
	var my_id = hitstop_id

	# Apply immediately
	if not is_in_global_hitstop:
		Engine.time_scale = slowdown_factor
		is_in_global_hitstop = true

	# Manual real-time delay (does not wait for next frame)
	var end_time = Time.get_unix_time_from_system() + hitstop_duration
	while Time.get_unix_time_from_system() < end_time:
		await get_tree().process_frame

	# Prevent older hitstops from overwriting new ones
	if my_id != hitstop_id:
		return

	# Restore immediately
	Engine.time_scale = 1.0
	is_in_global_hitstop = false
