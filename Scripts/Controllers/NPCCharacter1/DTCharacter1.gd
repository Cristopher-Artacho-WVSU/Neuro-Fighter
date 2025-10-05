extends CharacterBody2D

# NODES - Initialize in _ready() to avoid issues
var enemy = null
var animation = null
var character_sprite = null
var hurtboxes = []
var hitboxes = []

# CONSTANTS
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
const SPEED = 300
const ATTACK_RANGE_PUNCH = 200
const ATTACK_RANGE_KICK = 300
const MOVE_THRESHOLD = 250

# STATE VARIABLES
var is_jumping = false
var is_hurt = false
var is_attacking = false

func _ready():
	print("Decision Tree Controller Initialized")
	
	# Initialize nodes safely
	initialize_nodes()
	
	# Connect signals
	connect_signals()
	
	print("DT Controller ready!")

func initialize_nodes():
	# Get enemy reference
	enemy = get_parent().get_node("PlayerCharacter1")
	if not enemy:
		print("ERROR: Could not find PlayerCharacter1!")
		# Try alternative path
		enemy = get_node("../PlayerCharacter1")
		if enemy:
			print("Found enemy via alternative path")
	
	# Get component nodes
	animation = $AnimationPlayer
	character_sprite = $AnimatedSprite2D
	
	# Get hurtboxes and hitboxes
	hurtboxes = [
		$Hurtbox_LowerBody,
		$Hurtbox_UpperBody
	]
	
	hitboxes = [
		$Hitbox_LeftFoot,
		$Hitbox_LeftHand,
		$Hitbox_RightFoot,
		$Hitbox_RightHand
	]
	
	# Verify critical nodes
	if not animation:
		print("ERROR: No AnimationPlayer found!")
	if not character_sprite:
		print("ERROR: No AnimatedSprite2D found!")

func connect_signals():
	# Connect animation finished signal
	if animation and not animation.animation_finished.is_connected(_on_animation_finished):
		animation.animation_finished.connect(_on_animation_finished)
		print("Animation signals connected")
	
	# Connect hurtbox signals
	for hurtbox in hurtboxes:
		if hurtbox and not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			hurtbox.area_entered.connect(_on_hurtbox_area_entered)
			print("Hurtbox signal connected: ", hurtbox.name)

func _physics_process(delta):
	# Skip processing if critical nodes are missing
	if not is_instance_valid(enemy) or not animation:
		return
	
	update_facing_direction()
	apply_gravity(delta)
	
	# State machine - only act if not currently attacking or hurt
	if not is_attacking and not is_hurt:
		# Check for attacks first
		DTAttackSystem()
		# Only move if not attacking
		if not is_attacking:
			DTMovementSystem()
	
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		is_jumping = true
	else:
		velocity.y = 0
		is_jumping = false

func DTMovementSystem():
	if not is_instance_valid(enemy):
		return
	
	var distance = global_position.distance_to(enemy.global_position)
	
	if distance > MOVE_THRESHOLD:
		# Move toward enemy
		if enemy.position.x > position.x:
			# Enemy is to the right, move right
			velocity.x = SPEED
			play_animation("walk_forward")
		else:
			# Enemy is to the left, move left
			velocity.x = -SPEED
			play_animation("walk_backward")
	else:
		# Stop when within attack range
		velocity.x = 0
		if not is_attacking:
			play_animation("idle")

func DTAttackSystem():
	if not is_instance_valid(enemy):
		return
	
	var current_distance = global_position.distance_to(enemy.global_position)
	
	# Choose attack based on distance
	if current_distance <= ATTACK_RANGE_PUNCH:
		# Close range - use punch
		start_attack("light_punch", current_distance)
	elif current_distance <= ATTACK_RANGE_KICK:
		# Medium range - use kick
		start_attack("light_kick", current_distance)
	# If farther than ATTACK_RANGE_KICK, don't attack

func start_attack(attack_animation, distance):
	if not is_attacking:
		print("Starting attack: ", attack_animation, " at distance: ", distance)
		is_attacking = true
		velocity.x = 0  # Stop movement during attack
		play_animation(attack_animation)

func play_animation(anim_name):
	if animation and animation.has_animation(anim_name):
		if animation.current_animation != anim_name:
			animation.play(anim_name)
	else:
		print("WARNING: Animation not found: ", anim_name)

func update_facing_direction():
	if not is_instance_valid(enemy) or not character_sprite:
		return
	
	# Face the enemy
	var face_right = enemy.position.x > position.x
	character_sprite.flip_h = not face_right
	
	# Update hitbox and hurtbox directions
	var scale_x = 1 if face_right else -1
	for hitbox in hitboxes:
		if hitbox:
			hitbox.scale.x = scale_x
	for hurtbox in hurtboxes:
		if hurtbox:
			hurtbox.scale.x = scale_x

func _on_animation_finished(anim_name):
	print("Animation finished: ", anim_name)
	
	match anim_name:
		"light_punch", "light_kick", "heavy_punch", "heavy_kick":
			is_attacking = false
			print("Attack completed, ready for next action")
		"light_hurt", "heavy_hurt":
			is_hurt = false

func _on_hurtbox_area_entered(area: Area2D):
	if area.is_in_group("Player1_Hitboxes"):
		print("DT Character hit by: ", area.name)
		is_hurt = true
		is_attacking = false  # Interrupt attack if hit
		play_animation("light_hurt")
		
		# Apply knockback or other hit effects
		var knockback_direction = -1 if enemy.position.x > position.x else 1
		velocity.x = knockback_direction * 200

# Utility function to check if enemy is in attack range
func is_enemy_in_attack_range():
	if not is_instance_valid(enemy):
		return false
	var distance = global_position.distance_to(enemy.global_position)
	return distance <= ATTACK_RANGE_KICK

# Function to handle KO state
func KO():
	print("DT Character KO!")
	is_attacking = false
	is_hurt = true
	play_animation("knocked_down")
	# Disable movement and attacks
	set_physics_process(false)

# Debug function to see current state
func print_state():
	print("State - Attacking: ", is_attacking, " | Hurt: ", is_hurt, " | Jumping: ", is_jumping)
	if is_instance_valid(enemy):
		var distance = global_position.distance_to(enemy.global_position)
		print("Distance to enemy: ", distance)
