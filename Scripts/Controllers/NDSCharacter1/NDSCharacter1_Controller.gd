#res://Scripts/Controllers/DSCharacter1/DSCharacter1_Controller.gd

extends CharacterBody2D

#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#SERVER
var websocket := WebSocketPeer.new()
var server_url := "ws://127.0.0.1:8000/ws"  # WebSocket endpoint in lstm_server.py
var connected := false

#JUMP
var jump_speed = 3000 
var fall_multiplier = 5.0
var jump_multiplier = 1.6       # LESS gravity while rising → faster upward travel
var jump_force = -1700.0        # STRONGER initial jump → higher/faster jump start
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
var jump_timer = 0.0

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
var is_sliding: bool = false
var slide_cooldown_timer: float = 0.0
var slide_direction: int = 0
var slide_speed: float = 800
var slide_duration: float = 0.4
var slide_cooldown: float = 0.5


#DEFENSE 
var last_input_time = 0.0
var defense_delay = 0.5

#BOOL STATES
#MOVEMENTS
var is_dashing = false
var is_jumping = false
var is_crouching = false
var can_slide: bool = true
var slide_timer: float = 0.0
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
var NDSsuggestions: Array = []


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
var log_file_path = "res://nds_training.txt"
var cycle_used_rules = []
var log_cycles = 0
var NDS_10cycleLog_file_path = "res://NDS_10Cycles.txt"  # Using JSON format for simplicity
var log_cycles10 = 0

var ai_state_manager: Node
#SAVED AI FITNESS
var current_fitness = 0.5
var fitness = 0.5
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

#AREA2D GROUP
var player_index: int = 0
var player_hitboxGroup: String
var enemy_hitboxGroup: String

var chart_panel: Node = null
var recent_used_rules_this_cycle: Array = []
var total_rules_used: int = 0
var total_actions_taken: int = 0

var consecutive_idle_cycles = 0
var max_idle_cycles = 11

#var rules = [
	#{
		#"ruleID": 1, "prioritization": 1,
		#"conditions": { "distance": { "op": ">=", "value": 325 } },
		#"enemy_action": ["dash_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 2, "prioritization": 11,
		#"conditions": { "distance": { "op": "<=", "value": 325 } },
		#"enemy_action": ["light_kick"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 3, "prioritization": 12,
		#"conditions": { "distance": { "op": "<=", "value": 315 } },
		#"enemy_action": ["light_punch"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 4, "prioritization": 13,
		#"conditions": { "distance": { "op": "<=", "value": 325 } },
		#"enemy_action": ["crouch_lightKick"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 5, "prioritization": 14,
		#"conditions": { "distance": { "op": "<=", "value": 315 } },
		#"enemy_action": ["crouch_lightPunch"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 6, "prioritization": 41,
		#"conditions": { "distance": { "op": ">=", "value": 345 }, "upper_attacks_landed": { "op": ">=", "value": 1 } },
		#"enemy_action": ["heavy_kick"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 7, "prioritization": 42,
		#"conditions": { "distance": { "op": ">=", "value": 345 }, "upper_attacks_landed": { "op": ">=", "value": 1 } },
		#"enemy_action": ["heavy_punch"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 8, "prioritization": 2,
		#"conditions": { "distance": { "op": "<=", "value": 315 } },
		#"enemy_action": ["dash_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 9, "prioritization": 23,
		#"conditions": {  "enemy_anim": "light_kick", "distance": { "op": "<=", "value": 345 },  "upper_attacks_taken": { "op": ">=", "value": 1 } },
		#"enemy_action": ["crouch"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 10, "prioritization": 24,
		#"conditions": {  "enemy_anim": "light_punch", "distance": { "op": "<=", "value": 315 } },
		#"enemy_action": ["crouch"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 11, "prioritization": 100,
		#"conditions": { "player_anim": "idle" },
		#"enemy_action": ["idle"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 12, "prioritization": 51,
		#"conditions": { "distance": { "op": "<=", "value": 250 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		#"enemy_action": ["jump"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
		#{
		#"ruleID": 13, "prioritization": 42,
		#"conditions": { "distance": { "op": ">=", "value": 315 }, "lower_attacks_landed": { "op": ">=", "value": 1 } },
		#"enemy_action": ["crouch_heavyPunch"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
		#{
		#"ruleID": 14, "prioritization": 52,
		#"conditions": { "distance": { "op": "<=", "value": 350 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		#"enemy_action": ["jump_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
		#{
		#"ruleID": 15, "prioritization": 53,
		#"conditions": { "distance": { "op": "<=", "value": 250 }, "rand_chance": { "op": ">=", "value": 0.5 } },
		#"enemy_action": ["jump_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 16, "prioritization": 44,
		#"conditions": { 
			#"distance": { "op": ">=", "value": 400 },
			#"rand_chance": { "op": ">=", "value": 0.3 }
		#},
		#"enemy_action": ["slide_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 17, "prioritization": 55,
		#"conditions": { 
			#"distance": { "op": "<=", "value": 180 },
			#"upper_attacks_taken": { "op": ">=", "value": 2 },
			#"rand_chance": { "op": ">=", "value": 0.4 }
		#},
		#"enemy_action": ["slide_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#},
	#{
		#"ruleID": 18, "prioritization": 33,
		#"conditions": { 
			#"distance": { "op": ">=", "value": 350 },
			#"lower_attacks_landed": { "op": ">=", "value": 1 },
			#"rand_chance": { "op": ">=", "value": 0.5 }
		#},
		#"enemy_action": ["slide_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	#}
#]
var rules = [
	# ===== HIGH PRIORITY: DEFENSIVE ACTIONS =====
	#{
		#"ruleID": 1, "prioritization": 100,
		#"conditions": { 
			#"enemy_anim": ["light_punch", "light_kick", "heavy_punch", "heavy_kick", "crouch_lightPunch", "crouch_lightKick"],
			#"distance": { "op": "<=", "value": 350 }
		#},
		#"enemy_action": ["standing_defense"], "weight": 0.7, "wasUsed": false, "inScript": false
	#},
	{
		"ruleID": 2, "prioritization": 95,
		"conditions": { 
			"enemy_anim": ["crouch_lightPunch", "crouch_lightKick", "crouch_heavyPunch"],
			"distance": { "op": "<=", "value": 350 }
		},
		"enemy_action": ["crouch"], "weight": 0.7, "wasUsed": false, "inScript": false
	},
	
	# ===== MEDIUM PRIORITY: ATTACKS =====
	{
		"ruleID": 3, "prioritization": 80,
		"conditions": { 
			"distance": { "op": "<=", "value": 300 },
			"rand_chance": { "op": ">=", "value": 0.6 }
		},
		"enemy_action": ["light_punch"], "weight": 0.8, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 4, "prioritization": 80,
		"conditions": { 
			"distance": { "op": "<=", "value": 320 },
			"rand_chance": { "op": ">=", "value": 0.5 }
		},
		"enemy_action": ["light_kick"], "weight": 0.8, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 5, "prioritization": 75,
		"conditions": { 
			"distance": { "op": "<=", "value": 280 },
			"upper_attacks_landed": { "op": ">=", "value": 1 }
		},
		"enemy_action": ["heavy_punch"], "weight": 0.6, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 6, "prioritization": 75,
		"conditions": { 
			"distance": { "op": "<=", "value": 300 },
			"upper_attacks_landed": { "op": ">=", "value": 1 }
		},
		"enemy_action": ["heavy_kick"], "weight": 0.6, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 7, "prioritization": 70,
		"conditions": { 
			"distance": { "op": "<=", "value": 280 },
			"rand_chance": { "op": ">=", "value": 0.4 }
		},
		"enemy_action": ["crouch_lightPunch"], "weight": 0.7, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 8, "prioritization": 70,
		"conditions": { 
			"distance": { "op": "<=", "value": 300 },
			"rand_chance": { "op": ">=", "value": 0.4 }
		},
		"enemy_action": ["crouch_lightKick"], "weight": 0.7, "wasUsed": false, "inScript": false
	},
	
	# ===== MOVEMENT AND POSITIONING =====
	{
		"ruleID": 9, "prioritization": 60,
		"conditions": { 
			"distance": { "op": ">=", "value": 400 },
			"rand_chance": { "op": ">=", "value": 0.8 }
		},
		"enemy_action": ["dash_forward"], "weight": 0.9, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 10, "prioritization": 60,
		"conditions": { 
			"distance": { "op": ">=", "value": 350 },
			"rand_chance": { "op": ">=", "value": 0.7 }
		},
		"enemy_action": ["dash_forward"], "weight": 0.8, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 11, "prioritization": 55,
		"conditions": { 
			"distance": { "op": "<=", "value": 200 },
			"upper_attacks_taken": { "op": ">=", "value": 2 },
			"rand_chance": { "op": ">=", "value": 0.6 }
		},
		"enemy_action": ["dash_backward"], "weight": 0.7, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 12, "prioritization": 50,
		"conditions": { 
			"distance": { "op": ">=", "value": 500 },
			"rand_chance": { "op": ">=", "value": 0.5 }
		},
		"enemy_action": ["slide_forward"], "weight": 0.6, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 13, "prioritization": 45,
		"conditions": { 
			"distance": { "op": "<=", "value": 150 },
			"upper_attacks_taken": { "op": ">=", "value": 3 },
			"rand_chance": { "op": ">=", "value": 0.5 }
		},
		"enemy_action": ["slide_backward"], "weight": 0.6, "wasUsed": false, "inScript": false
	},
	
	# ===== JUMPS AND ADVANCED MOVEMENT =====
	{
		"ruleID": 14, "prioritization": 40,
		"conditions": { 
			"distance": { "op": "<=", "value": 250 },
			"rand_chance": { "op": ">=", "value": 0.3 }
		},
		"enemy_action": ["jump"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 15, "prioritization": 40,
		"conditions": { 
			"distance": { "op": "<=", "value": 300 },
			"rand_chance": { "op": ">=", "value": 0.4 }
		},
		"enemy_action": ["jump_forward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 16, "prioritization": 40,
		"conditions": { 
			"distance": { "op": "<=", "value": 200 },
			"upper_attacks_taken": { "op": ">=", "value": 2 },
			"rand_chance": { "op": ">=", "value": 0.5 }
		},
		"enemy_action": ["jump_backward"], "weight": 0.5, "wasUsed": false, "inScript": false
	},
	
	# ===== AGGRESSIVE FOLLOW-UPS =====
	{
		"ruleID": 17, "prioritization": 85,
		"conditions": { 
			"enemy_anim": ["light_hurt", "heavy_hurt"],
			"distance": { "op": "<=", "value": 350 },
			"rand_chance": { "op": ">=", "value": 0.8 }
		},
		"enemy_action": ["dash_forward", "light_punch"], "weight": 0.9, "wasUsed": false, "inScript": false
	},
	{
		"ruleID": 18, "prioritization": 30,
		"conditions": { 
			"distance": { "op": ">=", "value": 600 }
		},
		"enemy_action": ["dash_forward"], "weight": 1.0, "wasUsed": false, "inScript": false
	}
]

func find_enemy_automatically():
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is CharacterBody2D and child != self:
				enemy = child
				print("Enemy found: ", enemy.name)
				cache_enemy_components()
				return
	
	# Fallback: try after a short delay
	await get_tree().create_timer(0.5).timeout
	parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is CharacterBody2D and child != self:
				enemy = child
				print("Enemy found after delay: ", enemy.name)
				cache_enemy_components()
				return
	
	push_error("No enemy found for controller: " + name)

func cache_enemy_components():
	if enemy:
		enemyAnimation = enemy.get_node("AnimationPlayer") if enemy.has_node("AnimationPlayer") else null
		enemy_UpperHurtbox = enemy.get_node("Hurtbox_UpperBody") if enemy.has_node("Hurtbox_UpperBody") else null
		enemy_LowerHurtbox = enemy.get_node("Hurtbox_LowerBody") if enemy.has_node("Hurtbox_LowerBody") else null
		prev_distance_to_enemy = abs(enemy.position.x - position.x)
		print("Enemy components cached for: ", name)

# ===== INITIALIZATION =====
func _ready():
	#	GROUP HITBOXES
	Global.register_character(self)
	player_hitboxGroup = Global.get_hitbox_group(player_index)
	print("NDS HitboxGroup: ", player_hitboxGroup)
	for hb in hitboxGroup:
		hb.add_to_group(player_hitboxGroup)
	get_enemy_hurtbox()
#	PRINT THE SERVER IF IT IS CONNECTING
	connect_to_server()
	
	updateDetails()
	if enemy and enemy.has_node("AnimationPlayer"):
		print("AnimationPlayer of Enemy detected")
	
	initialize_ai_state_manager()
	initialize_character_state()
	start_script_generation_timer()
	init_log_file()
	
	initialize_chart_support()
	
	find_enemy_automatically()
	
	for hitbox in hitboxGroup:
		if not hitbox.is_connected("area_entered", Callable(self, "_on_hitbox_area_entered")):
			hitbox.connect("area_entered", Callable(self, "_on_hitbox_area_entered"))
	if $Hurtbox_LowerBody and $Hurtbox_LowerBody.has_signal("area_entered"):
		if not $Hurtbox_LowerBody.is_connected("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered")):
			$Hurtbox_LowerBody.connect("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered"))
			
	if $Hurtbox_UpperBody and $Hurtbox_UpperBody.has_signal("area_entered"):
		if not $Hurtbox_UpperBody.is_connected("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered")):
			$Hurtbox_UpperBody.connect("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered"))
##	FOR MOST ANIMATIONS
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
		
	setup_player_marker()


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


func start_script_generation_timer():
	add_child(generateScript_timer)
	generateScript_timer.wait_time = 4.0
	generateScript_timer.one_shot = false
	generateScript_timer.start()
	generateScript_timer.connect("timeout", Callable(self, "_on_generateScript_timer_timeout"))

# ===== PHYSICS AND MOVEMENT =====
func _physics_process(delta):
	
	websocket.poll()
	var state = websocket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN and not connected:
		print("✅ Connected to LSTM server")
		connected = true
	elif state == WebSocketPeer.STATE_CLOSING or state == WebSocketPeer.STATE_CLOSED:
		if connected:
			print("❌ Disconnected from LSTM server")
			connected = false

	if connected:
		while websocket.get_available_packet_count() > 0:
			var msg = websocket.get_packet().get_string_from_utf8()
			var parse_result = JSON.parse_string(msg)
			
			if typeof(parse_result) == TYPE_ARRAY:
				NDSsuggestions = parse_result  # Save suggestions array for generate_script()
				print("📨 LSTM suggestion received:", NDSsuggestions)
			else:
				print("⚠️ Unexpected message format from server:", msg)
						
	updateDetails()
	update_facing_direction()
	applyGravity(delta)
	
	#if animation.current_animation == "idle" and is_on_floor() and not is_hurt:
		#check_emergency_action()
	#
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
			
		if is_jumping:
			jump_timer += delta

		## -------------------------------
		## ASCEND PHASE
		## -------------------------------
		#if jump_state == "ascend":
#
			## Jump forward / backward detection
			#if curr_distance_to_enemy < prev_distance_to_enemy and not jump_forward_played:
				#velocity.x = 200 * ai_move_direction   # Forward widen
				#animation.play("jump_forward")
				#jump_forward_played = true
#
			#elif curr_distance_to_enemy > prev_distance_to_enemy and not jump_backward_played:
				#velocity.x = -200 * ai_move_direction  # Backward widen
				#animation.play("jump_backward")
				#jump_backward_played = true
#
			## Gravity reduction on rising
			#velocity.y += gravity * delta * jump_multiplier
#
			## Switch to FALL at exact animation time
			#if jump_timer >= jump_frame_fall_time:
				#jump_state = "fall"
				#jump_fall_started = true
#
#
		## -------------------------------
		## FALL PHASE
		## -------------------------------
		#elif jump_state == "fall":
			#velocity.y += gravity * delta * fall_multiplier
#
			## Prevent floaty jumps
			#if velocity.y > 0:
				#velocity.y += gravity * delta * 2
#
			#if is_on_floor() and not jump_landing_done:
				#animation.play("jump_end")
				#jump_landing_done = true
				#jump_state = "landing"
				#velocity.x = 0
#
#
		## -------------------------------
		## LANDING PHASE
		## -------------------------------
		#elif jump_state == "landing":
			#if animation.current_animation == "jump_end":
				## Let animation finish naturally
				#pass
			#else:
				#_reset_jump_state()
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


func evaluate_and_execute(rules: Array):
	if not is_instance_valid(enemy):
		find_enemy_automatically()
		if not enemy:
			return
	
	var enemy_anim = enemyAnimation.current_animation if enemyAnimation else "idle"
	var distance = global_position.distance_to(enemy.global_position)
	var matched_rules = []

	# NEW: Track if we have any defensive needs
	var needs_defense = false
	var enemy_is_attacking = enemy_anim in ["light_punch", "light_kick", "heavy_punch", "heavy_kick", 
										   "crouch_lightPunch", "crouch_lightKick", "crouch_heavyPunch"]
	
	if enemy_is_attacking and distance <= 350:
		needs_defense = true

	for i in range(DSscript.size()):
		var rule = DSscript[i]
		var conditions = rule["conditions"]
		var match_all = true
		
		# Check distance condition
		if "distance" in conditions:
			var cond = conditions["distance"]
			var current_distance = distance
			if not _compare_numeric(cond["op"], current_distance, cond["value"]):
				match_all = false
				continue
				
		# Check upper attacks landed condition
		if match_all and "upper_attacks_landed" in conditions:
			var cond = conditions["upper_attacks_landed"]
			if not _compare_numeric(cond["op"], upper_attacks_landed, cond["value"]):
				match_all = false
				continue
				
		# Check lower attacks landed condition  
		if match_all and "lower_attacks_landed" in conditions:
			var cond = conditions["lower_attacks_landed"]
			if not _compare_numeric(cond["op"], lower_attacks_landed, cond["value"]):
				match_all = false
				continue
				
		# Check upper attacks taken condition
		if match_all and "upper_attacks_taken" in conditions:
			var cond = conditions["upper_attacks_taken"]
			if not _compare_numeric(cond["op"], upper_attacks_taken, cond["value"]):
				match_all = false
				continue
				
		# Check enemy animation condition
		if "enemy_anim" in conditions:
			var enemy_anims = conditions["enemy_anim"]
			if typeof(enemy_anims) == TYPE_ARRAY:
				if not enemy_anim in enemy_anims:
					match_all = false
					continue
			else:
				if enemy_anim != enemy_anims:
					match_all = false
					continue
			
		# Check random chance condition
		if "rand_chance" in conditions:
			var rand_val = conditions["rand_chance"]["value"]
			if randf() > rand_val:
				match_all = false
				continue

		# Check slide-specific conditions
		var actions = rule.get("enemy_actions", [])
		if actions.size() == 0:
			var raw_action = rule.get("enemy_action", "idle")
			actions = [raw_action] if typeof(raw_action) == TYPE_STRING else raw_action
		
		var is_slide_rule = false
		for action in actions:
			if action == "slide_forward" or action == "slide_backward":
				is_slide_rule = true
				break
		
		if is_slide_rule and not can_perform_slide():
			match_all = false
			continue

		if match_all:
			matched_rules.append(i)

	# Sort matched rules by prioritization (highest first)
	matched_rules.sort_custom(_sort_by_priority_desc)

	# NEW: Fallback system - if no rules match but we need defense, use defensive action
	if matched_rules.size() == 0 and needs_defense:
		# Emergency defense - choose based on enemy attack type
		if enemy_anim in ["crouch_lightPunch", "crouch_lightKick", "crouch_heavyPunch"]:
			_execute_single_action("crouch")
			print("Emergency crouch defense!")
		#else:
			#_execute_single_action("standing_defense")
			#print("Emergency standing defense!")
		return

	if matched_rules.size() > 0:
		var rule_index = matched_rules[0]
		var rule = DSscript[rule_index]
		
		# TRACK RULE USAGE FOR CHARTS
		recent_used_rules_this_cycle.append(rule["ruleID"])
		total_rules_used += 1
		
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
			else:
				print("Invalid action type in rule %d: %s" % [rule.get("ruleID", -1), str(action)])

		if valid_actions.size() > 0:
			if Global.debug_mode:
				print(name, " - Executing rule ", rule["ruleID"], " with actions: ", valid_actions)
			_execute_actions(valid_actions)
			if not rule["ruleID"] in cycle_used_rules:
				cycle_used_rules.append(rule["ruleID"])
				
			# Mark rule as used
			for j in range(rules.size()):
				if rules[j]["ruleID"] == rule["ruleID"]:
					rules[j]["wasUsed"] = true
					break
					
			for script_rule in DSscript:
				if script_rule["ruleID"] == rule["ruleID"]:
					script_rule["wasUsed"] = true
					break
	else:
		# NEW: Smart fallback instead of idle
		execute_smart_fallback(distance)
			
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
	
	# Don't execute new actions if we're in a non-interruptible state
	if is_hurt:
		return
		
	match action:
		"idle":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				velocity.x = 0
				if animation.current_animation != "idle":
					animation.play("idle")
		"light_punch":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("light_punch")
				is_attacking = true
				velocity.x = 0
				velocity.y = 0
		"light_kick":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("light_kick")
				is_attacking = true
				velocity.x = 0
				velocity.y = 0
		#"standing_defense":
			#if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				#animation.play("standing_block")
				#is_defending = true
		"dash_forward":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				var direction = 1 if enemy.global_position.x > global_position.x else -1
				MovementSystem(direction)
		"dash_backward":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				var direction = -1 if enemy.global_position.x > global_position.x else 1
				MovementSystem(direction)
		"slide_forward":
			if can_perform_slide():
				var direction = 1 if enemy.global_position.x > global_position.x else -1
				start_slide(direction)
		"slide_backward":
			if can_perform_slide():
				var direction = -1 if enemy.global_position.x > global_position.x else 1
				start_slide(direction)
		"jump":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("jump")
				velocity.y = jump_force
				is_jumping = true
				jump_state = "ascend"
				jump_timer = 0.0
				jump_forward_played = false
				jump_backward_played = false
		"jump_forward":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("jump_forward")
				var direction = 1 if enemy.global_position.x > global_position.x else -1
				MovementSystem(direction)
				velocity.y = jump_force
				is_jumping = true
				jump_state = "ascend"
		"jump_backward":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("jump_backward")
				var direction = -1 if enemy.global_position.x > global_position.x else 1
				MovementSystem(direction)
				velocity.y = jump_force
				is_jumping = true
				jump_state = "ascend"
		"crouch":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("crouch")
				is_crouching = true
				velocity.x = 0
				velocity.y = 0
		"crouch_lightKick":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("crouch_lightKick")
				is_attacking = true
				velocity.x = 0
				velocity.y = 0
		"crouch_lightPunch":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("crouch_lightPunch")
				is_attacking = true
				velocity.x = 0
				velocity.y = 0
		"heavy_punch":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("heavy_punch")
				is_attacking = true
				velocity.x = 0
				velocity.y = 0
		"heavy_kick":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("heavy_kick")
				is_attacking = true
				velocity.x = 0
				velocity.y = 0
		"crouch_heavyPunch":
			if is_on_floor() and not is_jumping and not is_attacking and not is_hurt:
				animation.play("crouch_heavyPunch")
				is_attacking = true
				velocity.x = 0
				velocity.y = 0
		_:
			print("Unknown action: %s" % str(action))
	
	last_action = action
	
func debug_states():
	#print("is_dashing: ", is_dashing)
	#print("is_jumping state: ", is_jumping)
	#print("is_crouching: ", is_crouching)
	#print("is_attacking state:", is_attacking)
	#print("is_defending: ", is_defending)
	#print("is_hurt state:", is_hurt)
	#print("is_is_dashing: ", is_dashing)
	#print("is_on_floor(): ", is_on_floor())
	print("Current animation:", animation.current_animation)
	pass

#FOR ANIMATIONS IN ORDER TO NOT GET CUT OFF
func _on_animation_finished(anim_name: String):
	# Debug logging
	if Global.debug_mode:
		print(name, " - Animation finished: ", anim_name)
	
	match anim_name:
		"light_punch", "light_kick", "crouch_lightPunch", "crouch_lightKick", "crouch_heavyPunch", "heavy_punch", "heavy_kick":
			is_attacking = false
			# Don't automatically play idle - let the AI decide next action
		"standing_block":
			is_defending = false
		"light_hurt", "heavy_hurt":
			_on_hurt_finished()
		"jump", "jump_forward", "jump_backward":
			_reset_jump_state()
		"crouch":
			is_crouching = false
		"move_forward", "move_backward":
			is_dashing = false
			velocity.x = 0
		"slide":
			is_sliding = false
			velocity.x = 0
	
	# Only go to idle if we're not in any special state and not already processing
	if (!is_attacking && !is_defending && !is_hurt && !is_dashing && !is_jumping && 
		!is_crouching && !is_sliding && animation.current_animation == anim_name):
		# Small delay before idle to allow AI to choose next action
		await get_tree().create_timer(0.1).timeout
		if (!is_attacking && !is_defending && !is_hurt && !is_dashing && !is_jumping && 
			!is_crouching && !is_sliding):
			animation.play("idle")			

func generate_script():
	var active = 0
	var inactive = 0
	
	# Track if we're being too idle
	if cycle_used_rules.size() == 0:
		consecutive_idle_cycles += 1
	else:
		consecutive_idle_cycles = 0
	
	# Force rule refresh if too idle
	if consecutive_idle_cycles >= max_idle_cycles:
		print("FORCING RULE REFRESH - Too many idle cycles!")
		# Reset weights to encourage different rules
		for rule in rules:
			rule["weight"] = randf_range(0.3, 0.9)
		consecutive_idle_cycles = 0
	
	log_script_generation()
	log_every_10_cycles()
	cycle_used_rules.clear()
	
	# Count active rules in current script
	for rule in DSscript:
		if rule.get("wasUsed", false):
			active += 1
	
	# If all rules were used, just reset and continue
	if active == ruleScript:
		_reset_rule_usage()
		return
		
	inactive = ruleScript - active
	fitness = calculateFitness()
	
	# Calculate weight adjustment - make it more aggressive
	var weightAdjustment = calculateAdjustment(fitness)
	
	print("Weight Adjustment for fitness ", fitness, ": ", weightAdjustment)
	
	# Apply LSTM suggestions first (for NDS)
	if has_method("apply_nds_suggestions"):
		apply_nds_suggestions()
	
	# NEW: Track which rules to boost (frequently used and successful)
	var rules_to_boost = []
	var rules_to_reduce = []
	
	# Apply weight adjustments with smarter logic
	for rule in rules:
		if rule.get("inScript", false):
			if rule.get("wasUsed", false):
				# Rule was used - adjust based on fitness
				if fitness > baseline:
					# Successful rule - boost more
					rule["weight"] += weightAdjustment * 1.5
					rules_to_boost.append(rule["ruleID"])
				else:
					# Unsuccessful rule - penalize less
					rule["weight"] += weightAdjustment * 0.7
					rules_to_reduce.append(rule["ruleID"])
			else:
				# Rule wasn't used - small adjustment based on fitness
				if fitness < baseline:
					# If we're doing poorly, give unused rules a chance
					rule["weight"] += abs(weightAdjustment) * 0.3
				else:
					# If we're doing well, slightly reduce unused rules
					rule["weight"] += weightAdjustment * 0.2
			
			# Clamp weights
			if rule["weight"] < minWeight:
				weightRemainder += (rule["weight"] - minWeight)
				rule["weight"] = minWeight
			elif rule["weight"] > maxWeight:
				weightRemainder += (rule["weight"] - maxWeight)
				rule["weight"] = maxWeight
	
	# NEW: Ensure movement rules don't get too low
	ensure_minimum_movement_weights()
	
	DistributeRemainder()
	_create_new_script()
	_reset_rule_usage()
	
	print("New script generated. Boosted: ", rules_to_boost, " Reduced: ", rules_to_reduce)
	printSumWeights()
func calculateFitness():
	var base_score = 0.5
	
	# Reward attacks landed more heavily
	var attack_reward = (0.004 * upper_attacks_landed + 0.004 * lower_attacks_landed)
	
	# Reward defense moderately
	var defense_reward = (0.002 * upper_attacks_blocked + 0.002 * lower_attacks_blocked)
	
	# Penalize getting hit, but not too severely
	var hit_penalty = (-0.003 * lower_attacks_taken + -0.003 * upper_attacks_taken)
	
	# NEW: Heavy penalty for inactivity
	var inactivity_penalty = 0.0
	if total_rules_used < 5:  # If very few actions taken
		inactivity_penalty = -0.2
	
	var raw_fitness = base_score + attack_reward + defense_reward + hit_penalty + inactivity_penalty
	
	return clampf(raw_fitness, 0.1, 1.0)

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
	
	# Sort by weight descending
	candidates.sort_custom(func(a, b):
		if a.weight != b.weight:
			return a.weight > b.weight
		else:
			return a.random_tie > b.random_tie
	)
	
	# NEW: Ensure we have a mix of rule types
	var selected_rules = []
	var rule_types_added = {
		"defense": false,
		"close_attack": false, 
		"far_attack": false,
		"movement": false
	}
	
	for i in range(min(ruleScript, candidates.size())):
		var rule = candidates[i].rule
		var rule_id = rule["ruleID"]
		
		# Categorize rule
		if rule_id in [1, 2]:
			rule_types_added["defense"] = true
		elif rule_id in [3, 4, 5, 6, 7, 8]:
			rule_types_added["close_attack"] = true
		elif rule_id in [9, 10, 11, 12, 13, 14, 15, 16, 18]:
			rule_types_added["movement"] = true
		
		rule["inScript"] = true
		selected_rules.append(rule)
	
	# NEW: If missing critical rule types, add them forcibly
	if not rule_types_added["movement"] and selected_rules.size() < ruleScript:
		# Find a movement rule with highest weight not already selected
		var movement_candidates = []
		for rule in rules:
			if rule["ruleID"] in [9, 10, 11, 12, 13, 14, 15, 16, 18] and not rule["inScript"]:
				movement_candidates.append(rule)
		
		if movement_candidates.size() > 0:
			movement_candidates.sort_custom(func(a, b): return a["weight"] > b["weight"])
			var movement_rule = movement_candidates[0]
			movement_rule["inScript"] = true
			selected_rules.append(movement_rule)
			print("Forcibly added movement rule: ", movement_rule["ruleID"])
	
	DSscript = selected_rules
	print("Rules Generated (", DSscript.size(), " rules):")
	for rule in DSscript:
		print("  - Rule ", rule["ruleID"], " (weight: ", rule["weight"], ")")

func DistributeRemainder():
	var num_rules = rules.size()
	var target_total = num_rules / 2.0  # Total weight must be exactly this

	# 1️⃣ Clamp each rule's weight to [0.0, 1.0] and collect leftover/excess
	var leftover = 0.0
	for rule in rules:
		if rule.get("weight", 0.0) < 0.0:
			leftover += rule["weight"]  # negative, will add back
			rule["weight"] = 0.0
		elif rule.get("weight", 0.0) > 1.0:
			leftover += rule["weight"] - 1.0  # positive, will remove
			rule["weight"] = 1.0

	# 2️⃣ Redistribute leftover/excess evenly
	if leftover != 0.0:
		var adjust_per_rule = leftover / num_rules
		for rule in rules:
			rule["weight"] += adjust_per_rule
			rule["weight"] = clamp(rule["weight"], 0.0, 1.0)

	# 3️⃣ Ensure total weight == target_total
	var current_total = 0.0
	for rule in rules:
		current_total += rule.get("weight", 0.0)

	var diff = current_total - target_total
	if abs(diff) > 0.0001:  # only adjust if needed
		var adjust = diff / num_rules
		for rule in rules:
			rule["weight"] -= adjust
			rule["weight"] = clamp(rule["weight"], 0.0, 1.0)

	# Optional: print total weight for debugging
	var totalWeight = 0.0
	for rule in rules:
		totalWeight += rule.get("weight", 0.0)
	print("Total Rule Weight after adjustment:", totalWeight)



	#var max_total_weight = rules.size() / 2.0  # Maximum allowed total weight
#
	## 1️⃣ Clamp each rule's weight to [0.0, 1.0] and collect leftover weight
	#var leftover = 0.0
	#for rule in rules:
		#if rule["weight"] < 0.0:
			#leftover += rule["weight"]  # negative value, will be redistributed
			#rule["weight"] = 0.0
		#elif rule["weight"] > 1.0:
			#leftover += rule["weight"] - 1.0  # positive excess
			#rule["weight"] = 1.0
#
	## 2️⃣ Distribute leftover weight evenly across rules (if any)
	#if leftover != 0:
		#print("leftover: ", leftover)
		#var per_rule_adjust = leftover / rules.size() 
		#for rule in rules:
			#rule["weight"] += per_rule_adjust
			## Ensure clamping after redistribution
			#rule["weight"] = clamp(rule["weight"], 0.0, 1.0)
#
	## 3️⃣ Ensure total weight does not exceed max_total_weight
	#var current_total = 0.0
	#for rule in rules:
		#current_total += rule["weight"]
#
	#if current_total > max_total_weight:
		#var excess_weight = current_total - max_total_weight
		#var per_rule_reduction = excess_weight / rules.size() 
		#for rule in rules:
			#rule["weight"] -= per_rule_reduction
			#rule["weight"] = max(rule["weight"], 0.0)  # prevent negative weight
	#
	#if weightRemainder == 0:
		#return
		#
	#var non_script_rules = []
	#for rule in rules:
		#if not rule.get("inScript", false):
			#non_script_rules.append(rule)
	#
	#if non_script_rules.size() > 0:
		#var per_rule_adjust = weightRemainder / non_script_rules.size()
		#for rule in non_script_rules:
			#rule["weight"] += per_rule_adjust
	#
	#weightRemainder = 0

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
		return  # Ignore duplicate hits during hitstop/hitstun
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
		# Reset hit immunity after short real-time delay
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
	if connected:
		var data_to_send = {
			"timestamp": Time.get_datetime_string_from_system(),
			"cycle_id": log_cycles,
			"script": DSscript,
			"parameters": {
				"upper_attacks_taken": upper_attacks_taken,
				"lower_attacks_taken": lower_attacks_taken,
				"upper_attacks_landed": upper_attacks_landed,
				"lower_attacks_landed": lower_attacks_landed
			},
			"fitness": fitness
		}
		var json_data = JSON.stringify(data_to_send)
		websocket.send_text(json_data)
		print("JSON Data:" + json_data)

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
	velocity.x = 50*get_direction_to_enemy()

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

func connect_to_server():
	var err = websocket.connect_to_url("ws://127.0.0.1:8000/ws")
	if err != OK:
		print("❌ Failed to connect to LSTM server:", err)
		return
	websocket.connect("connection_established", Callable(self, "_on_connected"))
	websocket.connect("connection_closed", Callable(self, "_on_disconnected"))
	websocket.connect("data_received", Callable(self, "_on_data_received"))
	set_process(true)
	print("🔌 Connecting to LSTM server...")
	

func _on_connected(proto = ""):
	connected = true
	print("✅ Connected to LSTM server")

func _on_disconnected(was_clean_close = true):
	connected = false
	print("⚠️ Disconnected from LSTM server")

func _on_data_received():
	var msg = websocket.get_peer(1).get_packet().get_string_from_utf8()
	var data = JSON.parse_string(msg)
	if data.error == OK:
		NDSsuggestions = data.result  # Save suggestions array
		print("📨 LSTM suggestion received:", NDSsuggestions)
		#_apply_lstm_recommendations(data)

func send_script_to_lstm():
	if not connected:
			print("⚠️ Not connected to LSTM server — skipping send.")
			return
	
	if not FileAccess.file_exists(log_file_path):
		print("⚠️ Log file not found:", log_file_path)
		return
	
	var file = FileAccess.open(log_file_path, FileAccess.READ)
	if not file:
		print("⚠️ Failed to open log file.")
		return
	
	# Read the entire file content
	var content = file.get_as_text()
	file.close()
	
	# Split the content by lines
	var lines = content.split("\n", false)
	var latest_cycle_data = []
	var found_latest = false
	
	# We look for the last occurrence of "cycle_id:"
	for i in range(lines.size() - 1, -1, -1):
		if lines[i].begins_with("cycle_id:"):
			# Found the start of the latest cycle
			found_latest = true
			# Collect lines from here to the next Timestamp (or end)
			for j in range(i, lines.size()):
				if lines[j].begins_with("Timestamp:") and j != i:
					break
				latest_cycle_data.append(lines[j])
			break
	
	if not found_latest:
		print("⚠️ No cycle_id found in log file.")
		return
	
	# ✅ Join manually (Godot 4 fix)
	var latest_block = ""
	for line in latest_cycle_data:
		latest_block += line + "\n"
	
	print("📄 Latest log cycle content:\n" + latest_block)
	
	# ✅ Send this entire formatted text to LSTM
	websocket.send_text(latest_block)
	print("📤 Sent latest log cycle to LSTM server.")

#
#func _apply_lstm_recommendations(recommendations):
	## Example: adjust DS rule weights based on LSTM output
	#print("recommendations: ", recommendations)
	#for i in range(min(recommendations.size(), DSscript.size())):
		#DSscript[i]["weight"] = recommendations[i]
		#
	#print("✅ Updated DSscript weights from LSTM suggestions")

func reset_state():
	print(name, " - Resetting AI state")
	
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
	
	# Reset jump state
	jump_backward_played = false
	jump_forward_played = false
	jump_state = ""
	jump_timer = 0.0
	
	# Reset slide cooldown
	can_slide = true
	slide_cooldown_timer = 0.0
	
	# Re-initialize enemy reference
	find_enemy_automatically()
	
	# Reset animation
	if animation:
		animation.stop()
		# Small delay before playing idle to ensure everything is reset
		#await get_tree().create_timer(0.1).timeout
		#animation.play("idle")
	
	print(name, " - AI reset complete")
	
func can_perform_slide() -> bool:
	return can_slide and not is_sliding and is_on_floor() and not is_jumping
	
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
	
	print("Logging NDS_10Cycles at cycle:", log_cycles10)
	
	var file = FileAccess.open(NDS_10cycleLog_file_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		var entry = {
			"cycle_id": log_cycles,
			"rules": rules
		}
		file.store_string(JSON.stringify(entry) + "\n\n")
		file.close()
		# Write the rules array as JSON
		#file.store_string(JSON.stringify(rules))
		#file.close()

func get_rule_display_name(rule_id: int) -> String:
	for rule in rules:
		if rule["ruleID"] == rule_id:
			var actions = rule.get("enemy_actions", [])
			if actions.size() == 0:
				var raw_action = rule.get("enemy_action", "idle")
				actions = [raw_action] if typeof(raw_action) == TYPE_STRING else raw_action
			
			if actions.size() > 0:
				var action_name = str(actions[0])
				# Make it more readable
				action_name = action_name.replace("_", " ").capitalize()
				return action_name
	return "Rule " + str(rule_id)

func get_advanced_metrics() -> Dictionary:
	var metrics = {
		"aggression_score": calculate_aggression_score(),
		"defense_score": calculate_defense_score(),
		"efficiency_score": calculate_efficiency_score(),
		"adaptability_score": calculate_adaptability_score(),
		"lstm_influence": calculate_lstm_influence()
	}
	return metrics
	
func calculate_aggression_score() -> float:
	var total_attacks = upper_attacks_landed + lower_attacks_landed
	var total_actions = total_actions_taken if total_actions_taken > 0 else 1
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

func calculate_lstm_influence() -> float:
	# Measure how much LSTM is influencing decisions
	if not NDSsuggestions or NDSsuggestions.size() == 0:
		return 0.0
	
	var total_influence = 0.0
	for suggestion in NDSsuggestions:
		total_influence += abs(suggestion.get("weight_adjustment", 0.0))
	
	return total_influence / NDSsuggestions.size()

func initialize_chart_support():
	# Reset rule usage tracking for charts
	recent_used_rules_this_cycle.clear()
	total_rules_used = 0
	total_actions_taken = 0

func set_chart_panel(panel_node):
	chart_panel = panel_node

func get_recent_used_rules() -> Array:
	var recent = recent_used_rules_this_cycle.duplicate()
	recent_used_rules_this_cycle.clear()
	return recent

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
				var action_name = str(actions[0])
				action_name = action_name.replace("_", " ").capitalize()
				return action_name
	return "Rule " + str(rule_id)


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

func setup_player_marker():
	var player_type = identify_player_type()
	var color = Color.RED if player_type == "player1" else Color.BLUE
	var text = "PLAYER 1" if player_type == "player1" else "PLAYER 2"
	
	create_player_marker(text, color)
	
func create_player_marker(text: String, color: Color):
	if has_node("PlayerMarker"):
		return
		
	var marker = Label.new()
	marker.name = "PlayerMarker"
	marker.text = text
	marker.add_theme_font_size_override("font_size", 33)
	marker.add_theme_color_override("font_color", color)
	marker.position = Vector2(-50, -280)  # Adjust position as needed
	add_child(marker)

func identify_player_type() -> String:
	if "PlayerCharacter1" in name or "player1" in name.to_lower():
		return "player1"
	elif "NPCCharacter1" in name or "player2" in name.to_lower():
		return "player2"
	return "undefined"

func _reset_jump_state():
	is_jumping = false
	jump_state = ""
	jump_forward_played = false
	jump_backward_played = false
	jump_fall_started = false
	jump_landing_done = false
	velocity.x = 0

func ensure_minimum_movement_weights():
	var movement_rule_ids = [9, 10, 11, 12, 13, 14, 15, 16, 18]  # Movement-related rules
	
	for rule in rules:
		if rule["ruleID"] in movement_rule_ids and rule["weight"] < 0.3:
			rule["weight"] = 0.3
			print("Boosted movement rule ", rule["ruleID"], " to minimum weight")

func execute_smart_fallback(distance: float):
	if distance >= 400:
		_execute_single_action("dash_forward")
		print("Smart fallback: dash_forward (distance: ", distance, ")")
	elif distance <= 200:
		_execute_single_action("dash_backward") 
		print("Smart fallback: dash_backward (distance: ", distance, ")")
	else:
		# In mid-range, choose random attack
		var attacks = ["light_punch", "light_kick", "crouch_lightPunch", "crouch_lightKick"]
		var random_attack = attacks[randi() % attacks.size()]
		_execute_single_action(random_attack)
		print("Smart fallback: ", random_attack, " (distance: ", distance, ")")

func apply_nds_suggestions():
	if NDSsuggestions and NDSsuggestions.size() > 0:
		print("Applying NDS suggestions: ", NDSsuggestions)
		for suggestion in NDSsuggestions:
			var target_rule_id = suggestion.get("rule_id", -1)
			var weight_adj = suggestion.get("weight_adjustment", 0.0)
			
			# Find the rule in rules by ruleID
			for rule in rules:
				if rule.get("ruleID", -1) == target_rule_id:
					rule["weight"] += weight_adj
					print("NDS rule adjusted: %d: %.3f" % [rule["ruleID"], rule["weight"]])
					break
	else:
		print("No NDS suggestions to apply")

func check_emergency_action():
	# If both players are idle and close to each other for too long, force action
	if not is_instance_valid(enemy):
		return
		
	var distance = global_position.distance_to(enemy.global_position)
	var both_idle = (animation.current_animation == "idle" and 
					enemyAnimation and enemyAnimation.current_animation == "idle")
	
	if both_idle and distance < 400:
		# Force an action based on distance
		if distance < 250:
			# Too close - create space
			_execute_single_action("dash_backward")
			print("EMERGENCY: Forced dash_backward - too close and idle")
		elif distance > 600:
			# Too far - close distance  
			_execute_single_action("dash_forward")
			print("EMERGENCY: Forced dash_forward - too far and idle")
		else:
			# Mid range - attack
			var attacks = ["light_punch", "light_kick", "crouch_lightPunch"]
			var random_attack = attacks[randi() % attacks.size()]
			_execute_single_action(random_attack)
			print("EMERGENCY: Forced attack - stuck in idle")
