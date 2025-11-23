extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK }
var current_state = State.IDLE
var state_timer = 0.0
var state_interval = 1.0 # time between FSM decisions (1 second)
var has_executed_attack = false
var rng = RandomNumberGenerator.new()

#ONREADY VARIABLES FOR THE CURRENT PLAYER
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var playerDetails = get_parent().get_node("PlayerDetailsUI/Player2Details")
@onready var generateScript_timer = Timer.new()

#ONREADY VARIABLES FOR THE OTHER PLAYER
var enemy: CharacterBody2D = null
var enemyAnimation: AnimationPlayer = null
var enemy_UpperHurtbox: Area2D = null
var enemy_LowerHurtbox: Area2D = null
var prev_distance_to_enemy: float = 0.0

#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#JUMP
var jump_speed = 3000 
var fall_multiplier = 5.0
var jump_multiplier = 1.6
var jump_force = -1200.0
var jump_frame_ascend_time = 0.5   # frame 6
var jump_frame_fall_time = 0.687   # frame 9
var jump_end_time = 0.75           # frame 11
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

#ATTACKS
const lightPunch_Range = 315
const heavyPunch_Range = 315
const lightKick_Range = 345
const heavyKick_Range = 345
const crouch_heavyPunch_Range = 315
const crouch_lightPunch_Range = 315
const crouch_lightKick_Range = 325


#AREA2D GROUP
var player_index: int = 0
var player_hitboxGroup: String
var enemy_hitboxGroup: String

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

func _ready() -> void:
#	GROUP HITBOXES
	Global.register_character(self)
	player_hitboxGroup = Global.get_hitbox_group(player_index)
	print("FSM HitboxGroup: ", player_hitboxGroup)
	for hb in hitboxGroup:
		hb.add_to_group(player_hitboxGroup)
	get_enemy_hurtbox()

	find_enemy_automatically()
	randomize()
	rng.randomize()
	var is_defending = false
	var is_hurt = false
	var is_attacking = false
	var is_dashing = false
	var is_jumping = false
	var is_crouching = false
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
		
	print("Animation connected:", animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")))
	
	if $Hurtbox_UpperBody and not $Hurtbox_UpperBody.is_connected("area_entered", _on_hurtbox_upper_body_area_entered):
			$Hurtbox_UpperBody.connect("area_entered", _on_hurtbox_upper_body_area_entered)
		
	if $Hurtbox_LowerBody and not $Hurtbox_LowerBody.is_connected("area_entered", _on_hurtbox_lower_body_area_entered):
		$Hurtbox_LowerBody.connect("area_entered", _on_hurtbox_lower_body_area_entered)

func get_enemy_hurtbox():
	if player_hitboxGroup == "Player1_Hitboxes":
		enemy_hitboxGroup = "Player2_Hitboxes"
	else:
		enemy_hitboxGroup = "Player1_Hitboxes"
	print("Enemy Hitboxes: ", enemy_hitboxGroup)


func _physics_process(delta):
	var direction = 1 if enemy.global_position.x > global_position.x else -1
	
	update_facing_direction()
	applyGravity(delta)
	DamagedSystem(delta)
	debug_states()
	# FSM behavior decision every interval
	state_timer += delta
	if state_timer >= state_interval and not (is_attacking or is_hurt or is_jumping):
		state_timer = 0.0
		select_state()  # Decide next state randomly

	# State execution
	match current_state:
		State.MOVE:
			MovementSystem(get_direction())
			has_executed_attack = false
		State.ATTACK:
			if not has_executed_attack and not is_attacking:
				attackSystem()
				has_executed_attack = true
		State.IDLE:
			velocity.x = 0
			animation.play("idle")
			has_executed_attack = false
	
	move_and_slide()

func select_state():
	var choice = rng.randf()  # 0.0–1.0
	if choice < 0.7:
		current_state = State.MOVE
	else:
		current_state = State.ATTACK

func get_direction() -> int:
	# MovementSystem probability split: 0.6 forward, 0.4 backward
	var move_choice = rng.randf()
	if move_choice < 0.6:
		return 1  # forward
	else:
		return -1  # backward

func applyGravity(delta):
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y += gravity * jump_multiplier * delta
		else:
			velocity.y += gravity * fall_multiplier * delta
		if not is_jumping:
			is_jumping = true
	else:
		if velocity.y > 0:
			velocity.y = 0
		if is_jumping:
			is_jumping = false
			
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

func MovementSystem(ai_move_direction: int, delta := 1.0 / 60.0):
	if is_attacking || is_jumping || is_hurt:
		return
		
	var curr_distance_to_enemy = abs(enemy.position.x - position.x)
	
	if curr_distance_to_enemy >=345 and not is_dashing:
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
	if velocity.x != 0 and is_jumping:
		if curr_distance_to_enemy < prev_distance_to_enemy and jump_state == "ascend":
			velocity.x += 30
			velocity.y -= 10
			animation.play("jump_forward")
##		FORWARD
		#if curr_distance_to_enemy < prev_distance_to_enemy and jump_state == "frozen_up":
			#velocity.x -= 30
		#
##		BACKWARD
		#elif curr_distance_to_enemy > prev_distance_to_enemy and jump_state == "frozen_up":
			#velocity.x += 30
		if curr_distance_to_enemy < prev_distance_to_enemy and jump_state == "fall":
			velocity.y += 50
			
		elif curr_distance_to_enemy > prev_distance_to_enemy and jump_state == "ascend":
			velocity.x -= 30
			velocity.y -= 10
	if velocity.x != 0:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("move_forward")
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("move_backward")
	
	prev_distance_to_enemy = curr_distance_to_enemy

func DamagedSystem(delta):
#	DEFENSIVE MECHANISM
	if not is_dashing and not is_jumping and not is_crouching and not is_attacking and not is_defending and not is_hurt:
		last_input_time = 0.0
		is_defending = true
	else:
		last_input_time += delta
		if last_input_time >= defense_delay:
			is_defending = false

func _on_hurtbox_upper_body_area_entered(area: Area2D):
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	if area.is_in_group(enemy_hitboxGroup):
		is_recently_hit = true 
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block") 
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
			print("Player 2 Upper body hit taken")
		# Reset hit immunity after short real-time delay
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false
		
func _on_hurtbox_lower_body_area_entered(area: Area2D):
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	#	MADE GROUP FOR ENEMY NODES "Player1_Hitboxes" 
	if area.is_in_group(enemy_hitboxGroup):
		is_recently_hit = true 
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block") 
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
			print("Player 2 Lower body hit taken")
		# Reset hit immunity after short real-time delay
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false
		
func applyDamage(amount: int):
	if get_parent().has_method("apply_damage_to_player2"):
		get_parent().apply_damage_to_player2(amount)

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

func attackSystem():
	if not is_instance_valid(enemy):
		return
		
	var current_distance = global_position.distance_to(enemy.global_position)

	# Attack selection (50% total; evenly distributed among 7 attacks)
	var attacks = [
		{"name": "light_kick", "range": lightKick_Range},
		{"name": "heavy_kick", "range": heavyKick_Range},
		{"name": "light_punch", "range": lightPunch_Range},
		{"name": "heavy_punch", "range": heavyPunch_Range},
		{"name": "crouch_lightKick", "range": crouch_lightKick_Range},
		{"name": "crouch_lightPunch", "range": crouch_lightPunch_Range},
		{"name": "crouch_heavyPunch", "range": crouch_heavyPunch_Range},
	]

	var selected_attack = attacks[rng.randi_range(0, attacks.size() - 1)]
	if current_distance <= selected_attack["range"]:
		chooseAttack(selected_attack["name"])
		


func chooseAttack(attack):
	match attack:
		"light_kick":
			velocity.x = 0
			velocity.y = 0
			animation.play("light_kick")
			
		"heavy_kick":
			velocity.x = 0
			velocity.y = 0
			animation.play("heavy_kick")
		"light_punch":
			velocity.x = 0
			velocity.y = 0
			animation.play("light_punch")
		"heavy_punch":
			velocity.x = 0
			velocity.y = 0
			animation.play("heavy_punch")
		"crouch_lightKick":
			velocity.x = 0
			velocity.y = 0
			animation.play("crouch_lightKick")
		"crouch_lightPunch":
			velocity.x = 0
			velocity.y = 0
			animation.play("crouch_lightPunch")
		"crouch_heavyPunch":
			velocity.x = 0
			velocity.y = 0
			animation.play("crouch_heavyPunch")
	
	
func _on_animation_finished(anim_name):
	match anim_name:
		"light_punch", "light_kick", "heavy_punch", "heavy_kick":
			is_attacking = false
		"crouch_lightKick", "crouch_lightPunch", "crouch_heavyPunch":
			is_crouching = false
			is_attacking = false
		"crouch":
			is_crouching = false
		"jump", "jump_forward", "jump_backward":
			is_jumping = false
		"standing_block":
			is_defending = false
		"light_hurt", "heavy_hurt":
			is_hurt = false
			is_attacking = false
			is_defending = false
			is_dashing = false
		"move_forward", "move_backward":
			is_dashing = false
	velocity.x = 0
	animation.play("idle")
	current_state = State.IDLE
	
func debug_states():
	print("is_dashing: ", is_dashing)
	print("is_jumping state: ", is_jumping)
	print("is_crouching: ", is_crouching)
	print("is_attacking state: ", is_attacking)
	print("is_defending: ", is_defending)
	print("is_hurt state: ", is_hurt)
	
func KO():
	animation.play("knocked_down")
	#
	## Choose attack based on distance
	#if  current_distance <= ATTACK_RANGE_KICK:
		## Close range - use punch
		#start_attack("light_punch", current_distance)
	#elif current_distance >= ATTACK_RANGE_KICK and current_distance <= ATTACK_RANGE_LIMIT:
		## Medium range - use kick
		#start_attack("light_kick", current_distance)
	## If farther than ATTACK_RANGE_KICK, don't attack
	
#

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
	
	# Reset FSM state
	current_state = State.IDLE
	has_executed_attack = false
	state_timer = 0.0
	
	if animation:
		animation.stop()
		animation.play("idle")
	
	print("FSM Character reset to initial state")


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
			animation.play("idle")
