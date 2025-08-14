extends CharacterBody2D

# ONREADY VARIABLES
@onready var enemy = get_parent().get_node("PlayerCharacter1")
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]

# ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# MOVEMENT VARIABLES (from PlayerCharacter1)
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

# STATE VARIABLES
var is_jumping = false
var is_hurt = false
var in_combo = false
var is_crouching = false
var is_attacking = false
var is_defending = false

# DEFENSE TIMERS
var idle_timer = 0.0
var backward_timer = 0.0
const DEFENSE_TRIGGER_TIME = 1.0  # 2 seconds

func _ready():
	# Initialize state variables
	is_jumping = false
	is_hurt = false
	in_combo = false
	is_crouching = false
	is_attacking = false
	is_defending = false
	
	# Connect hurtbox signals
	$Hurtbox_UpperBody.area_entered.connect(Callable(self, "_on_hurtbox_upper_body_area_entered"))
	$Hurtbox_LowerBody.area_entered.connect(Callable(self, "_on_hurtbox_lower_body_area_entered"))
	
	# Connect animation finished signal
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))

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

	# AI decision making
	if !is_attacking && !is_defending && !is_hurt && !is_dashing:
		DTAttackSystem()
	if !is_attacking && !is_defending && !is_hurt && !is_dashing:
		DTMovementSystem(delta)
	
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

func DTMovementSystem(delta):
	if not is_instance_valid(enemy):
		return
	
	var distance = global_position.distance_to(enemy.position)
	var move_toward = false
	var move_away = false
	
	# AI decision logic
	if distance > 400:  # Far away - dash toward player
		move_toward = true
		if dash_cooldown_timer <= 0 && is_on_floor():
			var dash_dir = 1 if enemy.position.x > position.x else -1
			start_dash(dash_dir)
	elif distance > 325:  # Outside attack range - move toward
		move_toward = true
	elif distance < 200:  # Too close - move away
		move_away = true
	
	# Normal movement
	if !is_dashing:
		var target_velocity = 0.0
		
		if move_toward:
			target_velocity = base_speed if enemy.position.x > position.x else -base_speed
		elif move_away:
			target_velocity = -base_speed if enemy.position.x > position.x else base_speed
		
		# Smoothly interpolate to target velocity
		velocity.x = lerp(float(velocity.x), float(target_velocity), movement_smoothing * delta)
		
		# Animation handling
		if abs(velocity.x) > 10:  # Small threshold to prevent jitter
			if (enemy.position.x > position.x and velocity.x > 0) or (enemy.position.x < position.x and velocity.x < 0):
				animation.play("walk_forward")
			else:
				animation.play("walk_backward")
		else:
			animation.play("idle")

	# Jumping logic - NPC jumps randomly when close to player
	if is_on_floor() && distance < 250 && randf() < 0.01:  # 1% chance per frame
		velocity.y = -1200.0
		is_jumping = true
		animation.play("jump")

func DTAttackSystem():
	if not is_instance_valid(enemy):
		return

	var current_distance = global_position.distance_to(enemy.global_position)

	# Only attack if in range and not already attacking
	if current_distance <= 315 && !is_attacking:
		is_attacking = true
		velocity.x = 0
		
		# Choose attack randomly
		if randf() < 0.5:  # 50% chance for punch
			animation.play("light_punch")
		else:  # 50% chance for kick
			animation.play("light_kick")

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

func _on_animation_finished(anim_name):
	match anim_name:
		"light_punch", "light_kick":
			is_attacking = false
		"standing_block":
			end_defense()
		"dash_forward", "dash_backward":
			end_dash()
		"light_hurt":
			is_hurt = false  # CRITICAL: Reset hurt state after animation
			is_attacking = false
			print("Hurt animation finished, resetting is_hurt")

# FIXED: Proper hurtbox handlers
func _on_hurtbox_upper_body_area_entered(area: Area2D):
	if is_defending or is_hurt:  # Prevent multiple hits during hurt state
		return
		
	# Only get hurt by player's hitboxes
	if area.is_in_group("Player1_Hitboxes"):
		print("NPC Upper body hit taken")
		is_hurt = true
		velocity = Vector2.ZERO
		animation.play("light_hurt")
		if get_parent().has_method("apply_damage_to_player2"):
			get_parent().apply_damage_to_player2(10)
		#pass

func _on_hurtbox_lower_body_area_entered(area: Area2D):
	if is_defending or is_hurt:  # Prevent multiple hits during hurt state
		return
		
	# Only get hurt by player's hitboxes
	if area.is_in_group("Player1_Hitboxes"):
		print("NPC Lower body hit taken")
		is_hurt = true
		velocity = Vector2.ZERO
		animation.play("light_hurt")
		if get_parent().has_method("apply_damage_to_player2"):
			get_parent().apply_damage_to_player2(10)
		#pass
