extends CharacterBody2D

#ONREADY VARIABLES
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var enemy: CharacterBody2D = null
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var prev_distance_to_enemy: float = 0.0

#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#JUMP PARAMETERS
var jump_speed = 3000
var fall_multiplier = 7.0
var jump_multiplier = 2.6
var jump_force = -2000.0
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
		prev_distance_to_enemy = abs(enemy.position.x - position.x)
		
func _ready():
	set_process_input(true)
	find_enemy_automatically()
	#	FOR MOST ANIMATIONS
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	if $Hurtbox_UpperBody and not $Hurtbox_UpperBody.is_connected("area_entered", _on_hurtbox_upper_body_area_entered):
		$Hurtbox_UpperBody.connect("area_entered", _on_hurtbox_upper_body_area_entered)
		
	if $Hurtbox_LowerBody and not $Hurtbox_LowerBody.is_connected("area_entered", _on_hurtbox_lower_body_area_entered):
		$Hurtbox_LowerBody.connect("area_entered", _on_hurtbox_lower_body_area_entered)

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
		print("Jumped")
		velocity.y = -1700.0
		is_jumping = true
	
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

func handle_movement_animations(curr_distance_to_enemy: float):
	if is_sliding:
		return
		
	if not is_crouching and not is_jumping and not is_dashing and not is_attacking and not is_hurt:
		animation.play("idle")
		velocity.x = 0
	
	if velocity.x != 0 and is_jumping:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("jump_forward")
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("jump_backward")
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
	if is_attacking || is_jumping || is_hurt:
		return
	
	var punch = Input.is_action_just_pressed("punch")
	var kick = Input.is_action_just_pressed("kick")
	var heavy_punch = Input.is_action_just_pressed("heavy_punch")
	var heavy_kick = Input.is_action_just_pressed("heavy_kick")
	
	if punch:
		perform_attack("punch")
	if kick:
		perform_attack("kick")
	if heavy_punch:
		perform_attack("heavy_punch")
	if heavy_kick:
		perform_attack("heavy_kick")

func perform_attack(attack_type: String):
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
		return  # Ignore duplicate hits during hitstop/hitstun
	if area.is_in_group("Player2_Hitboxes"):
		is_recently_hit = true  # Mark as hit immediately
		#print("Upper attack received")
		if is_defending:
			print("Player 1 blocked the attack (upper body)")
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block")  # play block only on hit
			applyDamage(7)
			
		else:
			print("Player 1 Upper body hit taken")
			is_hurt = true
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			applyDamage(10)
			#enemy.upper_attacks_landed +=1
		
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false

func _on_hurtbox_lower_body_area_entered(area: Area2D):
	#print("Upper attack received")
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	#	MADE GROUP FOR ENEMY NODES "Player1_Hitboxes" 
	if area.is_in_group("Player2_Hitboxes"):
		is_recently_hit = true  # Mark as hit immediately
		if is_defending:
			print("Player 1 blocked the attack (lower body)")
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block")  # play block only on hit
			applyDamage(7)
		else:
			print("Player 1 Lower body hit taken")
			is_hurt = true
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			applyDamage(10)
			#enemy.lower_attacks_landed +=1c
		
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false
		
func applyDamage(amount: int):
	if get_parent().has_method("apply_damage_to_player1"):
		get_parent().apply_damage_to_player1(amount)
		
func _on_hurt_finished(anim_name):
#	IF is_defending, REDUCE THE DAMAGE BY 30%
	if is_defending or anim_name == "standing_block":
		applyDamage(7)
		animation.play("idle")
	else:
		applyDamage(10)
		animation.play("idle")
	is_hurt = false
	is_attacking = false
	is_defending = false
	is_dashing = false

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
			
	if not is_sliding and not is_attacking and not is_hurt:
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
	velocity.x = 100

func displacement_verySmall():
	velocity.x = 50

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
	is_attacking = false
	is_defending = false
	is_hurt = false
	is_recently_hit = false
	is_sliding = false
	
	# Reset slide cooldown
	can_slide = true
	slide_cooldown_timer = 0.0
	input_buffer.clear()
	
	if animation:
		animation.stop()
		animation.play("idle")
	
	print("Player Character reset to initial state")
