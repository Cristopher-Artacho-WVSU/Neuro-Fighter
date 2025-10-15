extends CharacterBody2D

#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#JUMP
var jump_speed = 3000 
var fall_multiplier = 5.0
var jump_multiplier = 1.6
var jump_force = -1200.0

#HITSTOPS
var hitstop_id: int = 0
var is_in_global_hitstop: bool = false
var is_recently_hit: bool = false

#VALUE VARIABLES
#MOVEMENT
var dash_speed = 300
var dash_time = 0.5
var dash_timer = 0.0
var dash_direction = 0

#DEFENSE 
var last_input_time = 0.0
var defense_delay = 0.5

#BOOL STATES
#MOVEMENTS
var is_dashing = false
var is_jumping = false
var is_crouching = false
#ATTACKS
var is_attacking = false
#DEFENSE
var is_defending = false
var is_hurt = false

#SCRIPT VALUES
var ruleScript = 5
var current_rule_dict: Dictionary = {}
var weightRemainder = 0
var DSscript = []

#PLAYER DETAILS
var upper_attacks_taken: int = 0
var lower_attacks_taken: int = 0
var upper_attacks_landed: int = 0
var lower_attacks_landed: int = 0
var upper_attacks_blocked: int = 0
var lower_attacks_blocked: int = 0


# WEIGHT ADJUSTMENT CONFIGURATIONS
var baseline = 0.5
var maxPenalty = 0.4
var maxReward = 0.4
var minWeight = 0.1
var maxWeight = 1.0

#LOGGING PURPOSES
var log_file_path = "res://training.txt"
var cycle_used_rules = []

var ai_state_manager: Node
#SAVED AI FITNESS
var current_fitness = 0.5

#CALCULATING THE ACTION 
var last_action: String

#ONREADY VARIABLES FOR THE CURRENT PLAYER
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var playerDetails = get_parent().get_node("PlayerDetailsUI/Player2Details")
@onready var generateScript_timer = Timer.new()

#ONREADY VARIABLES FOR THE OTHER PLAYER
@onready var enemy = get_parent().get_node("PlayerCharacter1")
@onready var enemyAnimation = enemy.get_node("AnimationPlayer")
@onready var enemy_UpperHurtbox = enemy.get_node("Hurtbox_UpperBody")
@onready var enemy_LowerHurtbox = enemy.get_node("Hurtbox_LowerBody")
@onready var prev_distance_to_enemy = abs(enemy.position.x - position.x)

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
		"ruleID": 12, "prioritization": 51,
		"conditions": { "distance": { "op": "<=", "value": 250 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		"enemy_action": ["jump"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
		{
		"ruleID": 13, "prioritization": 42,
		"conditions": { "distance": { "op": ">=", "value": 315 }, "lower_attacks_landed": { "op": ">=", "value": 1 } },
		"enemy_action": ["crouch_heavyPunch"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
		{
		"ruleID": 14, "prioritization": 52,
		"conditions": { "distance": { "op": "<=", "value": 350 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		"enemy_action": ["jump_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
		{
		"ruleID": 15, "prioritization": 53,
		"conditions": { "distance": { "op": "<=", "value": 250 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		"enemy_action": ["jump_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
]

# ===== INITIALIZATION =====
func _ready():
	updateDetails()
	if enemy and enemy.has_node("AnimationPlayer"):
		print("AnimationPlayer of Enemy detected")
	
	initialize_ai_state_manager()
	initialize_character_state()
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
#	FOR MOST ANIMATIONS
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
#	FOR DAMAGED ANIMATONS
	if not animation.is_connected("animation_finished", Callable(self, "_on_hurt_finished")):
		animation.connect("animation_finished", Callable(self, "_on_hurt_finished"))
		
	print("DS PLAYER Initialized with script: ", DSscript.size(), " rules")


func start_script_generation_timer():
	add_child(generateScript_timer)
	generateScript_timer.wait_time = 4.0
	generateScript_timer.one_shot = false
	generateScript_timer.start()
	generateScript_timer.connect("timeout", Callable(self, "_on_generateScript_timer_timeout"))

# ===== PHYSICS AND MOVEMENT =====
func _physics_process(delta):
	updateDetails()
	update_facing_direction()
	applyGravity(delta)
	
	if !is_attacking && !is_defending && !is_hurt && !is_dashing:
		evaluate_and_execute(rules)
	
	DamagedSystem(delta)
	#debug_states()
	move_and_slide()

func update_facing_direction():
	if not is_instance_valid(enemy):
		print("Enemy not found")
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
				print(valid_actions)
			else:
				print("Invalid action type in rule %d: %s" % [rule.get("ruleID", -1), str(action)])

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
					velocity.y = jump_force
					is_jumping = true
					_connect_animation_finished()
				
		"jump_forward":
			if is_on_floor():
				if not is_jumping:
					animation.play("jump_forward")
					print("Jumped")
					var direction = 1 if enemy.global_position.x > global_position.x else -1
					MovementSystem(direction)
					velocity.y = jump_force
					is_jumping = true
					_connect_animation_finished()
				
		"jump_backward":
			if is_on_floor():
				if not is_jumping:
					animation.play("jump_backward")
					print("Jumped")
					var direction = -1 if enemy.global_position.x > global_position.x else 1
					MovementSystem(direction)
					velocity.y = jump_force
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
	print("is_dashing: ", is_dashing)
	print("is_jumping state: ", is_jumping)
	print("is_crouching: ", is_crouching)
	print("is_attacking state:", is_attacking)
	print("is_defending: ", is_defending)
	print("is_hurt state:", is_hurt)
	print("is_is_dashing: ", is_dashing)
	print("is_on_floor(): ", is_on_floor())
	pass

#PASS ANIM NAME TO THE _on_animation_finished FUNCTION
func _connect_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))

#FOR ANIMATIONS IN ORDER TO NOT GET CUT OFF
func _on_animation_finished(anim_name: String):
	match anim_name:
		"light_punch", "light_kick", "crouch_lightPunch", "crouch_lightKick", "crouch_heavyPunch", "heavy_punch", "heavy_kick":
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
			velocity.x = 0
			animation.play("idle")
			

func generate_script():
	var active = 0
	var inactive = 0
	
	log_script_generation()
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
		else:
			return a.random_tie > b.random_tie
	)
	
	for i in range(min(ruleScript, candidates.size())):
		var rule = candidates[i].rule
		rule["inScript"] = true
		DSscript.append(rule)
		print("Rules Generated:")
	print(DSscript)

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
	upper_attacks_blocked = 0
	lower_attacks_blocked = 0
	
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
			
	if $Hurtbox_UpperBody and $Hurtbox_UpperBody.has_signal("area_entered"):
		if not $Hurtbox_UpperBody.is_connected("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered")):
			$Hurtbox_UpperBody.connect("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered"))

func _on_hurtbox_upper_body_area_entered(area: Area2D):
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	if area.is_in_group("Player1_Hitboxes"):
		is_recently_hit = true  # Mark as hit immediately
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block") 
			upper_attacks_blocked += 1
			if get_parent().has_method("apply_damage_to_player1"):
				get_parent().apply_damage_to_player2(7)
			print(" Upper Damaged From Blocking")
		else:
			is_hurt = true
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			print("Player 2 Upper body hit taken")
			upper_attacks_taken += 1
		_connect_hurt_animation_finished()
		# Reset hit immunity after short real-time delay
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false

func _on_hurtbox_lower_body_area_entered(area: Area2D):
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	#	MADE GROUP FOR ENEMY NODES "Player1_Hitboxes" 
	if area.is_in_group("Player1_Hitboxes"):
		is_recently_hit = true  # Mark as hit immediately
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block")
			if get_parent().has_method("apply_damage_to_player1"):
				get_parent().apply_damage_to_player2(7)
			lower_attacks_blocked += 1
			print("Lower Damaged From Blocking")
		else:
			is_hurt = true
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			print("Player 2 Lower body hit taken")
			lower_attacks_taken += 1
		_connect_hurt_animation_finished()
		
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false

func _connect_hurt_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_hurt_finished")):
		animation.connect("animation_finished", Callable(self, "_on_hurt_finished"))
		
			
func _on_hurt_finished(anim_name):
#		IF DS IS NOT DEFENDING WHENT THE DAMAGE RECEIVED
	if anim_name == "light_hurt" or anim_name == "heavy_hurt":
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
			is_jumping = false
			
			
func KO():
	animation.play("knocked_down")

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

func load_saved_states():
	if Global.player1_saved_state != "":
		load_rules(Global.player1_saved_state)
	if Global.player2_saved_state != "":
		load_rules(Global.player2_saved_state)

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

# ===== UTILITY AND DEBUG FUNCTIONS =====
func printSumWeights():
	var totalWeight = 0.0
	for rule in rules:
		totalWeight += rule.get("weight", 0.0)
	print("Total Rule Weight:", totalWeight)


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
