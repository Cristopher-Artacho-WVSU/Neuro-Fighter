#res://Scripts/Controllers/PlayerCharacter1/PlayerCharacter1_Controller.gd
extends CharacterBody2D

#ONREADY VARIABLES
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var enemy: CharacterBody2D = null
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var prev_distance_to_enemy: float = 0.0
var enemyAnimation: AnimationPlayer = null
#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#JUMP PARAMETERS
#var jump_speed = 3000

var fall_multiplier = 5.0
var jump_multiplier = 1.6       # LESS gravity while rising → faster upward travel
var jump_force = -1700.0        # STRONGER initial jump → higher/faster jump start
var jump_frame_ascend_time = 0.5   # frame 6
var jump_frame_fall_time = 0.687   # frame 9
var jump_end_time = 0.75           # frame 11
# Add these at the top of the script
var jump_frozen_up_done = false
var jump_fall_started = false
var jump_frozen_down_done = false
var jump_landing_done = false

var jump_state = ""     # "ascend", "frozen_up", "fall", "frozen_down"
#MOVEMENT
var dash_speed = 300
var dash_time = 0.5
var dash_timer = 0.0
var dash_direction = 0
#DEFENSE
var last_input_time = 0.0
var defense_delay = 0.5

#BOOL STATES
var is_dashing = false
var is_jumping = false
var is_crouching = false
var is_attacking = false
var is_defending = false
var is_hurt = false
var jump_forward_played = false
var jump_backward_played = false
#HITSTOP AND HITSTUN
var hitstop_id: int = 0
var is_in_global_hitstop: bool = false
var is_recently_hit: bool = false

#DOUBLE TAP SYSTEM
var last_move_input_time: float = 0.0
var last_move_direction: int = 0
var double_tap_threshold: float = 0.25 #DOUBLE TAP WINDOW TO TRIGGER SLIDE
var is_sliding: bool = false
var slide_speed: float = 800 #SLIDE SPEED
var slide_duration: float = 0.4 #SLIDE DURATION
var slide_timer: float = 0.0
var slide_direction: int = 0
var can_slide: bool = true
var slide_cooldown: float = 0.5 #COOLDOWN TO SLIDE AGAIN
var slide_cooldown_timer: float = 0.0
var left_key_just_pressed: bool = false
var right_key_just_pressed: bool = false
var input_buffer: Array = []
var max_buffer_size: int = 4

#AREA2D GROUP
var player_index: int = 0
var player_hitboxGroup: String
var enemy_hitboxGroup: String

var upper_attacks_landed: int = 0
var lower_attacks_landed: int = 0

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
		enemyAnimation = enemy.get_node("AnimationPlayer") if enemy.has_node("AnimationPlayer") else null
		if enemyAnimation:
			print("Enemy animation found")
		prev_distance_to_enemy = abs(enemy.position.x - position.x)
		
func _ready():
	set_process_input(true)
	find_enemy_automatically()
	
#	GROUP HITBOXES
	Global.register_character(self)
	player_hitboxGroup = Global.get_hitbox_group(player_index)
	print("Human Group Name: ", player_hitboxGroup)
	for hb in hitboxGroup:
		hb.add_to_group(player_hitboxGroup)
	get_enemy_hurtbox()
	
	
	#	FOR MOST ANIMATIONS
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
		
	if $Hurtbox_UpperBody and not $Hurtbox_UpperBody.is_connected("area_entered", _on_hurtbox_upper_body_area_entered):
		$Hurtbox_UpperBody.connect("area_entered", _on_hurtbox_upper_body_area_entered)
		
	if $Hurtbox_LowerBody and not $Hurtbox_LowerBody.is_connected("area_entered", _on_hurtbox_lower_body_area_entered):
		$Hurtbox_LowerBody.connect("area_entered", _on_hurtbox_lower_body_area_entered)
	
	setup_player_marker()

func get_enemy_hurtbox():
	if player_hitboxGroup == "Player1_Hitboxes":
		enemy_hitboxGroup = "Player2_Hitboxes"
	else:
		enemy_hitboxGroup = "Player1_Hitboxes"
	print("Enemy Hitboxes: ", enemy_hitboxGroup)

func _input(event):
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	
	if event.is_action("move_left") or event.is_action("ui_left"):
		handle_double_tap_input(-1, "left")
	elif event.is_action("move_right") or event.is_action("ui_right"):
		handle_double_tap_input(1, "right")

func handle_double_tap_input(direction: int, input_name: String):
	var current_time = Time.get_unix_time_from_system()

	input_buffer.push_back({"time": current_time, "direction": direction, "name": input_name})
	
	if input_buffer.size() > max_buffer_size:
		input_buffer.pop_front()
	
	check_double_tap_pattern()

func check_double_tap_pattern():
	var current_time = Time.get_unix_time_from_system()
	
	# We need at least 2 inputs to check for double tap
	if input_buffer.size() < 2:
		return
	
	# Get the two most recent inputs
	var first_input = input_buffer[input_buffer.size() - 2]
	var second_input = input_buffer[input_buffer.size() - 1]
	
	# Check if they're the same direction and within threshold
	if (first_input.direction == second_input.direction and 
		(second_input.time - first_input.time) < double_tap_threshold):
		
		# Attempt to slide
		if can_slide and not is_sliding:
			start_slide(second_input.direction)
			
			# Clear buffer after successful double tap to prevent immediate re-trigger
			input_buffer.clear()
			last_move_input_time = 0.0
			last_move_direction = 0


func _physics_process(delta):
	update_facing_direction()
	applyGravity(delta)
	
	if is_hurt:
		# Only handle slide movement if already sliding
		if is_sliding:
			handle_slide_movement(delta)
		move_and_slide()
		return
	
	# Update slide cooldown
	if slide_cooldown_timer > 0:
		slide_cooldown_timer -= delta
		if slide_cooldown_timer <= 0:
			can_slide = true
			
	if is_sliding:
		handle_slide_movement(delta)
	else:
		# Only process normal movement when not sliding
		MovementSystem(delta)
		AttackSystem()
		DefenseSystem(delta)
		
	if is_jumping:
		handle_jump_animation(delta)
	
	#debug_states()
	move_and_slide()

func handle_slide_movement(delta):
	slide_timer -= delta
	velocity.x = slide_direction * slide_speed
	
	## Apply braking in the last 20% of slide for smooth stop
	#if slide_timer <= slide_duration * 0.2:
		#velocity.x = lerp(velocity.x, 0.0, 0.3)
	
	# End slide completely when timer expires
	if slide_timer <= 0:
		end_slide()

func MovementSystem(delta):
	if is_sliding:
		return
		
	if is_attacking || is_defending || is_hurt:
		return
	
	var curr_distance_to_enemy = abs(enemy.position.x - position.x)
	var jump = Input.is_action_just_pressed("jump")
	var crouch = Input.is_action_just_pressed("crouch")
	var forward = Input.is_action_pressed("move_right")
	var backward = Input.is_action_pressed("move_left")
	
	# Handle Jump
	if jump and not is_jumping:
		animation.play("jump")
		velocity.y = jump_force
		is_jumping = true
		jump_state = "ascend"

	
	# Handle Crouch
	if crouch and not is_jumping:
		animation.play("crouch")
		is_crouching = true
	
	# Handle Dash
	handle_dash_movement(forward, backward, delta)
	
	# Handle Idle and Movement Animations
	handle_movement_animations(curr_distance_to_enemy)
	
	prev_distance_to_enemy = curr_distance_to_enemy


func handle_dash_movement(forward: bool, backward: bool, delta: float):
	if is_sliding:
		return
		
	if not is_dashing and not is_jumping:
		if forward:
			start_dash(1)
				
		elif backward:
			start_dash(-1)
	if is_dashing and not is_jumping:
		velocity.x = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = 0
	#if is_dashing and is_jumping:
		

func handle_movement_animations(curr_distance_to_enemy: float):
	if is_sliding:
		return
		
	if not is_crouching and not is_jumping and not is_dashing and not is_attacking and not is_hurt:
		animation.play("idle")
		velocity.x = 0
	
	if jump_state == "ascend":
		if curr_distance_to_enemy < prev_distance_to_enemy and not jump_forward_played:
			velocity.x += 10   # instead of 30
			velocity.y -= 5
			animation.play("jump_forward")
			jump_forward_played = true
		if curr_distance_to_enemy < prev_distance_to_enemy and jump_state == "fall":
			velocity.y += 25
			
		elif curr_distance_to_enemy > prev_distance_to_enemy and not jump_backward_played:
			velocity.x += 10   # instead of 30
			velocity.y -= 5
			animation.play("jump_backward")
			jump_backward_played = true
			
		
	elif velocity.x != 0 and not is_jumping:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("move_forward")
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("move_backward")

func start_dash(direction):
	is_dashing = true
	dash_direction = direction
	dash_timer = dash_time	

func start_slide(direction: int):
	if is_attacking || is_jumping || is_defending || is_hurt || is_sliding || !can_slide:
		print("Cannot slide - blocked by current state")
		return
	
	is_sliding = true
	slide_direction = direction
	slide_timer = slide_duration
	
	is_dashing = false
	velocity.x = 0
	
	# Play slide animation if available, otherwise use dash animation
	if animation.has_animation("slide"):
		animation.play("slide")
	else:
		animation.play("move_forward" if direction > 0 else "move_backward")
	
	print("Slide movement activated!")

func end_slide():
	is_sliding = false
	velocity.x = 0
	slide_cooldown_timer = slide_cooldown
	can_slide = false
	print("Slide ended. Cooldown: ", slide_cooldown, " seconds")

# ===== COMBAT SYSTEM =====
func AttackSystem():
	if is_attacking || is_jumping || is_hurt || is_sliding:
		return
	
	var punch = Input.is_action_just_pressed("punch")
	var kick = Input.is_action_just_pressed("kick")
	var heavy_punch = Input.is_action_just_pressed("heavy_punch")
	var heavy_kick = Input.is_action_just_pressed("heavy_kick")
	
	if punch:
		perform_attack("punch")
	elif kick:  # Use elif to prevent multiple attacks at once
		perform_attack("kick")
	elif heavy_punch:
		perform_attack("heavy_punch")
	elif heavy_kick:
		perform_attack("heavy_kick")

func perform_attack(attack_type: String):
	if is_attacking:
		return
		
	var attack_animations = {
		"punch": "light_punch",
		"kick": "light_kick", 
		"heavy_punch": "heavy_punch",
		"heavy_kick": "heavy_kick"
	}
	
	var crouch_attack_animations = {
		"punch": "crouch_lightPunch",
		"kick": "crouch_lightKick",
		"heavy_punch": "crouch_heavyPunch"
	}
	
	if is_crouching and crouch_attack_animations.has(attack_type):
		animation.play(crouch_attack_animations[attack_type])
	else:
		animation.play(attack_animations[attack_type])
	is_attacking = true
	velocity.x = 0

# ===== DEFENSE AND DAMAGE SYSTEM =====
func DefenseSystem(delta):
	if 	Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or Input.is_action_pressed("jump") or Input.is_action_pressed("crouch") or Input.is_action_pressed("punch") or Input.is_action_pressed("kick"):
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
		is_recently_hit = true 
		
		# CRITICAL: Reset attack state when hit
		is_attacking = false
		
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)
			animation.play("standing_block") 
			#upper_attacks_blocked += 1
			applyDamage(7)
		else:
			if enemyAnimation.current_animation in ["heavy_kick", "heavy_punch", "crouch_heavyPunch"]:
				applyDamage(15)
				animation.play("heavy_hurt")
			elif enemyAnimation.current_animation in ["light_kick", "light_punch", "light_heavyPunch", "crouch_lightkick", "crouch_lightPunch"]:
				applyDamage(10)
				animation.play("light_hurt")
			is_hurt = true
			apply_hitstop(0.15)
			#upper_attacks_taken += 1
		
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false
		
func _on_hurtbox_lower_body_area_entered(area: Area2D):
	if is_recently_hit:
		return
	
	if area.is_in_group(enemy_hitboxGroup):
		is_recently_hit = true 
		
		# CRITICAL: Reset attack state when hit
		is_attacking = false
		
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)
			animation.play("standing_block") 
			#upper_attacks_blocked += 1
			applyDamage(7)
		else:
			if enemyAnimation.current_animation in ["heavy_kick", "heavy_punch", "crouch_heavyPunch"]:
				applyDamage(15)
				animation.play("heavy_hurt")
			elif enemyAnimation.current_animation in ["light_kick", "light_punch", "light_heavyPunch", "crouch_lightkick", "crouch_lightPunch"]:
				applyDamage(10)
				animation.play("light_hurt")
			is_hurt = true
			apply_hitstop(0.15)
			#upper_attacks_taken += 1
			
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false
		
func applyDamage(amount: int):
	if player_hitboxGroup == "Player1_Hitboxes":
		if get_parent().has_method("apply_damage_to_player1"):
			get_parent().apply_damage_to_player1(amount)
	else:
		if get_parent().has_method("apply_damage_to_player2"):
			get_parent().apply_damage_to_player2(amount)
		
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

func apply_hitstop(hitstop_duration: float, slowdown_factor: float = 0.05) -> void:
	hitstop_id += 1
	var my_id = hitstop_id

	if not is_in_global_hitstop:
		Engine.time_scale = slowdown_factor
		is_in_global_hitstop = true
		
	var end_time = Time.get_unix_time_from_system() + hitstop_duration
	while Time.get_unix_time_from_system() < end_time:
		await get_tree().process_frame

	if my_id != hitstop_id:
		return

	Engine.time_scale = 1.0
	is_in_global_hitstop = false

# ===== ANIMATION HANDLING =====
func _on_animation_finished(anim_name):
	match anim_name:
		"slide":
			is_sliding = false
		"light_punch", "light_kick", "heavy_punch", "heavy_kick":
			is_attacking = false
			# Ensure we don't get stuck if animation finishes but state wasn't reset
			velocity.x = 0
			if not is_hurt and not is_defending:
				animation.play("idle")
		"crouch_lightKick", "crouch_lightPunch", "crouch_heavyPunch":
			is_crouching = false
			is_attacking = false
			velocity.x = 0
			if not is_hurt and not is_defending:
				animation.play("idle")
		"crouch":
			is_crouching = false
			velocity.x = 0
			if not is_hurt and not is_defending:
				animation.play("idle")
		"jump", "jump_forward", "jump_backward":
			is_jumping = false
			velocity.x = 0
			if not is_hurt and not is_defending:
				animation.play("idle")
		"standing_block":
			is_defending = false
			velocity.x = 0
			if not is_hurt and not is_attacking:
				animation.play("idle")
		"light_hurt", "heavy_hurt":
			_on_hurt_finished()
			
	if not is_sliding and not is_attacking and not is_hurt and not is_defending and animation.current_animation != "idle":
		velocity.x = 0
		animation.play("idle")

func KO():
	animation.play("knocked_down")

# ===== UTILITY FUNCTIONS =====
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

func displacement_small():
	velocity.x = 100* get_direction_to_enemy()

func displacement_verySmall():
	velocity.x = 50* get_direction_to_enemy()

# ===== DEBUG FUNCTIONS =====
func debug_states():
	print("is_dashing: ", is_dashing)
	print("is_jumping state: ", is_jumping)
	print("is_crouching: ", is_crouching)
	print("is_attacking state: ", is_attacking)
	print("is_defending: ", is_defending)
	print("is_hurt state: ", is_hurt)
	

func reset_state():
	velocity = Vector2.ZERO
	# Reset all states
	is_dashing = false
	is_jumping = false
	is_crouching = false
	is_attacking = false  # Make sure this gets reset
	is_defending = false
	is_hurt = false
	is_recently_hit = false
	is_sliding = false
	jump_backward_played = false
	jump_forward_played = false
	
	# Reset slide cooldown
	can_slide = true
	slide_cooldown_timer = 0.0
	input_buffer.clear()
	
	# Force stop current animation and play idle
	if animation:
		animation.stop()
		animation.play("idle")
	
	print("Player Character reset to initial state")
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
