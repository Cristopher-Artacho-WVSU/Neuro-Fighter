#res://Scripts/Controllers/DSCharacter1/DSCharacter1_Controller.gd

extends CharacterBody2D

#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#JUMP
var jump_speed = 3000 
var fall_multiplier = 5.0
var jump_multiplier = 1.6
var jump_force = -1700.0
var jump_frame_ascend_time = 0.5   # frame 6
var jump_frame_fall_time = 0.687   # frame 9
var jump_end_time = 0.75           # frame 11
var jump_forward_played = false
var jump_backward_played = false
# Add these at the top of the script
var jump_frozen_up_done = false
var jump_fall_started = false
var jump_frozen_down_done = false
var jump_landing_done = false
var jump_state = ""     # "ascend", "frozen_up", "fall", "frozen_down"

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

# DOUBLE DASH
var is_sliding: bool = false
var slide_speed: float = 800
var slide_duration: float = 0.4
var slide_timer: float = 0.0
var slide_direction: int = 0
var can_slide: bool = true
var slide_cooldown: float = 0.5

#SCRIPT VALUES
var slide_cooldown_timer: float = 0.0
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
var log_cycles = 0
var DS_10cycleLog_file_path = "res://DS_10Cycles.txt"  # Using JSON format for simplicity
var log_cycles10 = 0


var ai_state_manager: Node
#SAVED AI FITNESS
var current_fitness = 0.5
var fitness = 0.5
#CALCULATING THE ACTION 
var last_action: String

# Chart-related variables
var chart_panel: Node = null
var recent_used_rules_this_cycle: Array = []
var total_rules_used: int

#ONREADY VARIABLES FOR THE CURRENT PLAYER
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var playerDetails = get_parent().get_node("PlayerDetailsUI/Player2Details")
@onready var generateScript_timer = Timer.new()

var enemy: CharacterBody2D = null
var enemyAnimation: AnimationPlayer = null

var enemy_UpperHurtbox: Area2D = null
var enemy_LowerHurtbox: Area2D = null
var prev_distance_to_enemy: float = 0.0

#AREA2D GROUP
var player_index: int = 0
var player_hitboxGroup: String
var enemy_hitboxGroup: String



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
	{
		"ruleID": 16, "prioritization": 44,
		"conditions": { 
			"distance": { "op": ">=", "value": 400 },
			"rand_chance": { "op": ">=", "value": 0.3 }
		},
		"enemy_action": ["slide_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 17, "prioritization": 55,
		"conditions": { 
			"distance": { "op": "<=", "value": 180 },
			"upper_attacks_taken": { "op": ">=", "value": 2 },
			"rand_chance": { "op": ">=", "value": 0.4 }
		},
		"enemy_action": ["slide_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 18, "prioritization": 33,
		"conditions": { 
			"distance": { "op": ">=", "value": 350 },
			"lower_attacks_landed": { "op": ">=", "value": 1 },
			"rand_chance": { "op": ">=", "value": 0.5 }
		},
		"enemy_action": ["slide_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	}
]

func find_enemy_automatically():
	# Look for other CharacterBody2D in parent scene
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is CharacterBody2D and child != self:
				enemy = child
				break
	
	if not enemy:
		push_error("No enemy found for controller: " + name)
	
	if enemy:
		cache_enemy_components()

func cache_enemy_components():
	if enemy:
		enemyAnimation = enemy.get_node("AnimationPlayer") if enemy.has_node("AnimationPlayer") else null
		enemy_UpperHurtbox = enemy.get_node("Hurtbox_UpperBody") if enemy.has_node("Hurtbox_UpperBody") else null
		enemy_LowerHurtbox = enemy.get_node("Hurtbox_LowerBody") if enemy.has_node("Hurtbox_LowerBody") else null
		prev_distance_to_enemy = abs(enemy.position.x - position.x)

# ===== INITIALIZATION =====
func _ready():
	
	#	GROUP HITBOXES
	Global.register_character(self)
	player_hitboxGroup = Global.get_hitbox_group(player_index)
	print("DS Hitbox Group: ", player_hitboxGroup)
	for hb in hitboxGroup:
		hb.add_to_group(player_hitboxGroup)
	get_enemy_hurtbox()
	
	find_enemy_automatically()
	updateDetails()
	
	initialize_ai_state_manager()
	initialize_character_state()
	start_script_generation_timer()
	init_log_file()
	
	initialize_chart_support()
	
	for hitbox in hitboxGroup:
		if not hitbox.is_connected("area_entered", Callable(self, "_on_hitbox_area_entered")):
			hitbox.connect("area_entered", Callable(self, "_on_hitbox_area_entered"))
	
	if $Hurtbox_LowerBody and $Hurtbox_LowerBody.has_signal("area_entered"):
		if not $Hurtbox_LowerBody.is_connected("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered")):
			$Hurtbox_LowerBody.connect("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered"))
			
	if $Hurtbox_UpperBody and $Hurtbox_UpperBody.has_signal("area_entered"):
		if not $Hurtbox_UpperBody.is_connected("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered")):
			$Hurtbox_UpperBody.connect("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered"))
			
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))

func get_enemy_hurtbox():
	if player_hitboxGroup == "Player1_Hitboxes":
		enemy_hitboxGroup = "Player2_Hitboxes"
	else:
		enemy_hitboxGroup = "Player1_Hitboxes"
	print("Enemy Hitboxes: ", enemy_hitboxGroup)

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

		
	print("DS PLAYER Initialized with script: ", DSscript.size(), " rules")
	
func initialize_chart_support():
	# This will be called from the game scene to set up chart reference
	pass

func set_chart_panel(panel_node):
	chart_panel = panel_node
	
func get_rule_ids() -> Array:
	var ids = []
	for rule in rules:
		ids.append(rule["ruleID"])
	return ids

func get_rule_action_name(rule_id: int) -> String:
	for rule in rules:
		if rule["ruleID"] == rule_id:
			var actions = rule.get("enemy_actions", [])
			if actions.size() == 0:
				var raw_action = rule.get("enemy_action", "idle")
				actions = [raw_action] if typeof(raw_action) == TYPE_STRING else raw_action
			
			if actions.size() > 0:
				# Return the first action name, or a combination if multiple
				var action_name = str(actions[0])
				# Make it more readable
				action_name = action_name.replace("_", " ").capitalize()
				return action_name
	return "Rule " + str(rule_id)
	
func get_recent_used_rules() -> Array:
	var recent = recent_used_rules_this_cycle.duplicate()
	recent_used_rules_this_cycle.clear()
	return recent

func get_advanced_metrics() -> Dictionary:
	var metrics = {
		"aggression_score": calculate_aggression_score(),
		"defense_score": calculate_defense_score(),
		"efficiency_score": calculate_efficiency_score(),
		"adaptability_score": calculate_adaptability_score()
	}
	return metrics

func calculate_aggression_score() -> float:
	var total_attacks = upper_attacks_landed + lower_attacks_landed
	var total_actions = total_rules_used
	if total_actions == 0:
		return 0.0
	return float(total_attacks) / total_actions

func calculate_defense_score() -> float:
	var total_defenses = upper_attacks_blocked + lower_attacks_blocked
	var total_hits_taken = upper_attacks_taken + lower_attacks_taken
	if total_hits_taken == 0:
		return 1.0
	return float(total_defenses) / total_hits_taken

func calculate_efficiency_score() -> float:
	var successful_attacks = upper_attacks_landed + lower_attacks_landed
	var total_attacks_attempted = successful_attacks + (upper_attacks_blocked + lower_attacks_blocked)
	if total_attacks_attempted == 0:
		return 0.0
	return float(successful_attacks) / total_attacks_attempted

func calculate_adaptability_score() -> float:
	# Measure how many different rules are being used
	var unique_rules_used = 0
	for rule in rules:
		if rule.get("wasUsed", false):
			unique_rules_used += 1
	
	if rules.size() == 0:
		return 0.0
	return float(unique_rules_used) / rules.size()

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
	
	handle_slide_movement(delta)
	
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
			
	if jump_state == "ascend":
		if curr_distance_to_enemy < prev_distance_to_enemy and not jump_forward_played:
			velocity.x += 30   # instead of 30
			velocity.y -= 5
			animation.play("jump_forward")
			jump_forward_played = true
		if curr_distance_to_enemy < prev_distance_to_enemy and jump_state == "fall":
			velocity.y += 25
			
		elif curr_distance_to_enemy > prev_distance_to_enemy and not jump_backward_played:
			velocity.x += 30   # instead of 30
			velocity.y -= 5
			animation.play("jump_backward")
			jump_backward_played = true
	if velocity.x != 0:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("move_forward")
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("move_backward")
	
	prev_distance_to_enemy = curr_distance_to_enemy
	
func handle_slide_movement(delta):
	# Update slide cooldown
	if slide_cooldown_timer > 0:
		slide_cooldown_timer -= delta
		if slide_cooldown_timer <= 0:
			can_slide = true
	
	if is_sliding:
		slide_timer -= delta
		velocity.x = slide_direction * slide_speed
		
		if slide_timer <= 0:
			is_sliding = false
			velocity.x = 0
			# Start cooldown
			slide_cooldown_timer = slide_cooldown
			can_slide = false
			
func start_slide(direction: int):
	if is_attacking || is_jumping || is_defending || is_hurt || is_sliding || !can_slide:
		return
	
	is_sliding = true
	slide_direction = direction
	slide_timer = slide_duration
	
	# Play slide animation
	if animation.has_animation("slide"):
		animation.play("slide")
	else:
		animation.play("move_forward" if direction > 0 else "move_backward")
	
	print("AI Slide movement activated!")

func can_perform_slide() -> bool:
	return can_slide and not is_sliding and is_on_floor() and not is_jumping

func evaluate_and_execute(rules: Array):
	var enemy_anim = enemyAnimation.current_animation
	var distance = global_position.distance_to(enemy.global_position)
	var matched_rules = []

	for i in range(DSscript.size()):
		var rule = DSscript[i]
		var conditions = rule["conditions"]
		var match_all = true
		
		# Check if this is a slide rule and if sliding is available
		var is_slide_rule = false
		var actions = rule.get("enemy_actions", [])
		if actions.size() == 0:
			var raw_action = rule.get("enemy_action", "idle")
			actions = [raw_action] if typeof(raw_action) == TYPE_STRING else raw_action
		
		for action in actions:
			if action == "slide_forward" or action == "slide_backward":
				is_slide_rule = true
				break
		
		# Skip slide rules if sliding is not available
		if is_slide_rule and not can_perform_slide():
			continue
		
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
		
		# TRACK RULE USAGE FOR CHARTS
		recent_used_rules_this_cycle.append(rule["ruleID"])
		if chart_panel and chart_panel.has_method("record_rule_usage"):
			chart_panel.record_rule_usage(rule["ruleID"])

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
		total_rules_used += 1
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
					#_connect_animation_finished()
		"standing_defense":
			if is_on_floor():
				if not is_jumping:
					animation.play("standing_block")
					is_defending = true
					#_connect_animation_finished()
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
		"slide_forward":
			if is_on_floor() and not is_jumping and can_slide:
				var direction = 1 if enemy.global_position.x > global_position.x else -1
				start_slide(direction)
				
		"slide_backward":
			if is_on_floor() and not is_jumping and can_slide:
				var direction = -1 if enemy.global_position.x > global_position.x else 1
				start_slide(direction)
		"jump":
			if is_on_floor():
				if not is_jumping:
					animation.play("jump")
					print("Jumped")
					velocity.y = jump_force
					is_jumping = true
					jump_state = "ascend"
					#_connect_animation_finished()
				
		"jump_forward":
			if is_on_floor():
				if not is_jumping:
					animation.play("jump_forward")
					print("Jumped")
					var direction = -1 if enemy.global_position.x > global_position.x else 1
					MovementSystem(direction)
					velocity.y = jump_force
					is_jumping = true
					jump_state = "ascend"
					
					#_connect_animation_finished()
				
		"jump_backward":
			if is_on_floor():
				if not is_jumping:
					animation.play("jump_backward")
					print("Jumped")
					var direction = -1 if enemy.global_position.x > global_position.x else 1
					MovementSystem(direction)
					velocity.y = jump_force
					is_jumping = true
					jump_state = "ascend"
					#_connect_animation_finished()
					
		"crouch":
			if is_on_floor():
				if not is_jumping:
					animation.play("crouch")
					velocity.x = 0
					velocity.y = 0
					#_connect_animation_finished()
		"crouch_lightKick":
			if is_on_floor():
				if not is_jumping:
					animation.play("crouch_lightKick")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					#_connect_animation_finished()
		"crouch_lightPunch":
			if is_on_floor():
				if not is_jumping:
					animation.play("crouch_lightPunch")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					#_connect_animation_finished()
					
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
					#_connect_animation_finished()
					
		"crouch_heavyPunch":
			if is_on_floor():
				if not is_jumping:
					animation.play("crouch_heavyPunch")
					is_attacking = true
					velocity.x = 0
					velocity.y = 0
					#_connect_animation_finished()
		_:
			print("Unknown action: %s" % str(action))
	last_action = action
	#print(last_action)
	#is_dashing = false
	#_connect_animation_finished()

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

#FOR ANIMATIONS IN ORDER TO NOT GET CUT OFF
func _on_animation_finished(anim_name: String):
	print("FINISHED:", anim_name)
	print("PLAYING HURT at time:", animation.current_animation_position)
	match anim_name:
		"light_punch", "light_kick", "crouch_lightPunch", "crouch_lightKick", "crouch_heavyPunch", "heavy_punch", "heavy_kick":
			is_attacking = false
		"standing_block":
			is_defending = false
		"light_hurt", "heavy_hurt":
			_on_hurt_finished()
		"jump", "jump_forward", "jump_backward":
			is_jumping = false
		"crouch":
			is_crouching = false
		"move_forward", "move_backward":
			is_dashing = false
			velocity.x = 0
		"slide":
			is_sliding = false
			velocity.x = 0
	#animation.play("idle")
			

func generate_script():
	var active = 0
	var inactive = 0
	
	log_script_generation()
	log_every_10_cycles()
	cycle_used_rules.clear()
	
	# Count active rules in current script
	for rule in DSscript:
		if rule.get("wasUsed", false):
			active += 1
	
	if active == ruleScript:
		_reset_rule_usage()
		return
		
	inactive = ruleScript - active
	fitness = calculateFitness()
	
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

func _on_hurtbox_upper_body_area_entered(area: Area2D):
	if is_recently_hit:
		return
	if area.is_in_group(enemy_hitboxGroup):
		#if "upper_attacks_landed" in enemy:
			#enemy.upper_attacks_landed += 1
		is_recently_hit = true 
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block") 
			upper_attacks_blocked += 1
			applyDamage(7)
			print(" Upper Damaged From Blocking")
		else:
			if enemyAnimation.current_animation in ["heavy_kick", "heavy_punch", "crouch_heavyPunch"]:
				applyDamage(15)
				animation.play("heavy_hurt")
			elif enemyAnimation.current_animation in ["light_kick", "light_punch", "light_heavyPunch", "crouch_lightkick", "crouch_lightPunch"]:
				applyDamage(10)
				animation.play("light_hurt")
			is_hurt = true
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			upper_attacks_taken += 1
			print("Player 2 Upper body hit taken")
		# Reset hit immunity after short real-time delay
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false
		
func _on_hurtbox_lower_body_area_entered(area: Area2D):
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	#	MADE GROUP FOR ENEMY NODES "Player1_Hitboxes" 
	if area.is_in_group(enemy_hitboxGroup):
		#if "lower_attacks_landed" in enemy:
			#enemy.lower_attacks_landed += 1
		is_recently_hit = true 
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block") 
			upper_attacks_blocked += 1
			applyDamage(7)
			print(" Lower Damaged From Blocking")
		else:
			if enemyAnimation.current_animation in ["heavy_kick", "heavy_punch", "crouch_heavyPunch"]:
				applyDamage(15)
				animation.play("heavy_hurt")
			elif enemyAnimation.current_animation in ["light_kick", "light_punch", "light_heavyPunch", "crouch_lightkick", "crouch_lightPunch"]:
				applyDamage(10)
				animation.play("light_hurt")
			is_hurt = true
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			upper_attacks_taken += 1
			print("Player 2 Lower body hit taken")
			
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false
		
func applyDamage(amount: int):
	if player_hitboxGroup == "Player1_Hitboxes":
		if get_parent().has_method("apply_damage_to_player1"):
			get_parent().apply_damage_to_player1(amount)
	else:
		if get_parent().has_method("apply_damage_to_player2"):
			get_parent().apply_damage_to_player2(amount)

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
	print("logging works")
	var timestamp = Time.get_datetime_string_from_system()
	var file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()  # append to the end

	# Step 1: Simplify all rules in DSscript
	var simplified_rules = []
	for rule in DSscript:
		if rule.has("conditions") and rule["conditions"].has("distance"):
			var condition = rule["conditions"]["distance"]
			var action = ""
			if rule.has("enemy_action") and rule["enemy_action"].size() > 0:
				action = rule["enemy_action"][0]

			simplified_rules.append({
				"rule_id": rule["ruleID"],
				"distance": condition["value"],
				"action": action,
				"weight": rule["weight"],
				"was_used": rule["wasUsed"]
			})

	# Step 2: Write the log entry once (after collecting all rules)
	file.store_string("Timestamp: %s\n" % timestamp)
	file.store_string("cycle_id: %d\n" % log_cycles)
	file.store_string("script:" + JSON.stringify(simplified_rules, "  ") + "\n")
	
	file.store_string("executed_rules:" + JSON.stringify(cycle_used_rules) + "\n")
	
	file.store_string("parameters: %s\n" % JSON.stringify({
		"upper_attacks_taken": upper_attacks_taken,
		"lower_attacks_taken": lower_attacks_taken,
		"upper_attacks_landed": upper_attacks_landed,
		"lower_attacks_landed": lower_attacks_landed
	}))
	file.store_string("fitness: %.3f\n" % fitness)
	log_cycles += 1
	file.close()

#	ERASE CONTENT
func init_log_file():
	print("file content erased")
	var file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if file:
		file.store_string("")
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
	print("generating new script")
	generate_script()
	
func displacement_small():
	velocity.x = 100*get_direction_to_enemy()
	
func displacement_verySmall():
	velocity.x = 50 *get_direction_to_enemy()

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

func reset_state():
	velocity = Vector2.ZERO
	# Reset all states
	is_dashing = false
	is_jumping = false
	is_crouching = false
	is_attacking = false
	is_defending = false
	is_hurt = false
	is_recently_hit = false
	is_sliding = false
	jump_backward_played = false
	jump_forward_played = false
	# Reset slide cooldown
	can_slide = true
	slide_cooldown_timer = 0.0
	# Stop any current animation and play idle
	if animation:
		animation.stop()
		animation.play("idle")
	
	print("DS Character reset to initial state")

func handle_jump_animation(delta):
	var vy = velocity.y

	# -------------------------------
	# 1. ASCENDING — freeze at frame 6
	# -------------------------------
	if jump_state == "ascend":
		if vy < 0:
			if animation.current_animation_position >= jump_frame_ascend_time:
				jump_state = "frozen_up"
	# Keep frame frozen every physics frame
	if jump_state == "frozen_up":
		animation.seek(jump_frame_ascend_time, true)

	# -------------------------------------
	# 2. FALLING — play until frame 9
	# -------------------------------------
	if jump_state == "frozen_up" and vy > 0:
		jump_state = "fall"
		animation.play("jump")
		animation.seek(jump_frame_ascend_time, true)

	# 3. Freeze on fall-frame (frame 9)
	if jump_state == "fall":
		if animation.current_animation_position >= jump_frame_fall_time:
			jump_state = "frozen_down"
	if jump_state == "frozen_down":
		animation.seek(jump_frame_fall_time, true)

	# ----------------------------------------------------------
	# 4. If landed, play ending frames (frame 10 → frame 11)
	# ----------------------------------------------------------
	if jump_state == "frozen_down" and is_on_floor():
		jump_state = "landing"
		animation.play("jump")
		animation.seek(jump_frame_fall_time, true)

# 5. End everything when jump animation finishes
	if jump_state == "landing":
		if animation.current_animation_position >= jump_end_time:
			is_jumping = false
			jump_state = ""
			jump_forward_played = false
			jump_backward_played = false
			animation.play("idle")
			
func log_every_10_cycles():
	log_cycles10 += 1
	
	# Only log every 10 cycles
	if log_cycles10 % 10 != 0:
		return
	
	print("Logging DS_10Cycles at cycle:", log_cycles10)
	
	var file = FileAccess.open(DS_10cycleLog_file_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		var entry = {
			"cycle_id": log_cycles,
			"rules": rules
		}
		file.store_string(JSON.stringify(entry) + "\n\n")
		file.close()
		
func _on_hurt_finished():
#	IF is_defending, REDUCE THE DAMAGE BY 30%
		animation.play("idle")
		is_dashing = false
		is_jumping = false
		is_crouching = false
		is_attacking = false
		is_defending = false
		is_hurt = false
		is_recently_hit = false
		is_sliding = false
		jump_backward_played = false
		jump_forward_played = false
		can_slide = true

func _on_hitbox_area_entered(area: Area2D):
	# Make sure this area belongs to the enemy
	if area.get_parent() != enemy:
		return

	var area_name := area.name

	if area_name == "Hurtbox_UpperBody":
		upper_attacks_landed += 1
		print("Player landed upper attack!")
	elif area_name == "Hurtbox_LowerBody":
		lower_attacks_landed += 1
		print("Player landed lower attack!")


func get_direction_to_enemy() -> int:
	if enemy == null:
		return 1  # fallback
	
	return 1 if enemy.global_position.x > global_position.x else -1
