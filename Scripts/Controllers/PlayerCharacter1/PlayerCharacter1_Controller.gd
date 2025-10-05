extends CharacterBody2D

# NODES
@onready var animation = $AnimationPlayer
@onready var character_sprite = $AnimatedSprite2D
@onready var enemy = get_parent().get_node("NPCCharacter1")
@onready var hurtboxes = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxes = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]

# CONSTANTS
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
const DEFENSE_DELAY = 0.5
const DASH_SPEED = 300
const DASH_TIME = 0.5
const JUMP_FORCE = -1200.0

# STATE VARIABLES
var dash_timer = 0.0
var dash_direction = 0
var last_input_time = 0.0
var prev_distance_to_enemy = 0.0

# STATE FLAGS
var is_dashing = false
var is_jumping = false
var is_crouching = false
var is_attacking = false
var is_defending = false
var is_hurt = false

func _ready():
	prev_distance_to_enemy = abs(enemy.position.x - position.x)
	
	# Connect signals once
	if not animation.animation_finished.is_connected(_on_animation_finished):
		animation.animation_finished.connect(_on_animation_finished)
	
	# Connect hurtbox signals
	for hurtbox in hurtboxes:
		if hurtbox and not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta):
	update_facing_direction()
	apply_gravity(delta)
	
	# Process systems
	if not is_hurt:
		MovementSystem(delta)
		AttackSystem()
		DefenseSystem(delta)
	
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		is_jumping = true
	else:
		velocity.y = 0
		is_jumping = false

func MovementSystem(delta):
	if is_attacking or is_defending or is_hurt:
		return
	
	var current_distance_to_enemy = abs(enemy.position.x - position.x)
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE
		is_jumping = true
	
	# Handle crouch
	if Input.is_action_just_pressed("crouch"):
		play_animation("crouch")
		is_crouching = true
	
	# Handle dash
	handle_dash(delta)
	
	# Movement animation
	if velocity.x != 0:
		if current_distance_to_enemy < prev_distance_to_enemy:
			play_animation("move_forward")
		else:
			play_animation("move_backward")
	else:
		if not is_crouching and not is_dashing:
			play_animation("idle")
	
	prev_distance_to_enemy = current_distance_to_enemy

func handle_dash(delta):
	if not is_dashing:
		# Start dash
		if Input.is_action_pressed("move_right"):
			start_dash(1)
		elif Input.is_action_pressed("move_left"):
			start_dash(-1)
	else:
		# Continue dash
		velocity.x = dash_direction * DASH_SPEED
		dash_timer -= delta
		
		if dash_timer <= 0:
			end_dash()

func start_dash(direction):
	is_dashing = true
	dash_direction = direction
	dash_timer = DASH_TIME

func end_dash():
	is_dashing = false
	velocity.x = 0

func AttackSystem():
	if is_attacking or is_jumping or is_hurt:
		return
	
	var punch = Input.is_action_just_pressed("punch")
	var kick = Input.is_action_just_pressed("kick")
	
	if punch or kick:
		handle_attack(punch, kick)

func handle_attack(is_punch, is_kick):
	var dir_to_enemy = sign(enemy.position.x - position.x)
	var moving_toward_enemy = (
		(dir_to_enemy == 1 and Input.is_action_pressed("move_right")) or
		(dir_to_enemy == -1 and Input.is_action_pressed("move_left"))
	)
	
	var attack_animation = get_attack_animation(is_punch, is_kick, moving_toward_enemy, is_crouching)
	
	if attack_animation:
		play_animation(attack_animation)
		is_attacking = true
		velocity.x = 0

func get_attack_animation(is_punch, is_kick, is_heavy, is_crouched):
	if is_crouched:
		if is_punch: return "crouch_lightPunch"
		if is_kick: return "crouch_lightKick"
	else:
		if is_punch: return "heavy_punch" if is_heavy else "light_punch"
		if is_kick: return "heavy_kick" if is_heavy else "light_kick"
	return ""

func DefenseSystem(delta):
	if any_input_pressed():
		last_input_time = 0.0
		is_defending = false
	else:
		last_input_time += delta
		if last_input_time >= DEFENSE_DELAY:
			is_defending = true

func any_input_pressed() -> bool:
	return (
		Input.is_action_pressed("move_right") or 
		Input.is_action_pressed("move_left") or
		Input.is_action_pressed("jump") or 
		Input.is_action_pressed("crouch") or
		Input.is_action_pressed("punch") or 
		Input.is_action_pressed("kick")
	)

func _on_hurtbox_area_entered(area: Area2D):
	if area.is_in_group("Player2_Hitboxes"):
		handle_damage(area)

func handle_damage(area):
	if is_defending:
		play_animation("standing_block")
		apply_damage(7)  # Reduced damage when blocking
	else:
		is_hurt = true
		play_animation("light_hurt")
		apply_damage(10)  # Full damage when not blocking
	
	velocity.x = 0

func apply_damage(amount):
	if get_parent().has_method("apply_damage_to_player1"):
		get_parent().apply_damage_to_player1(amount)

func update_facing_direction():
	var face_right = enemy.position.x > position.x
	var scale_x = 1 if face_right else -1
	
	character_sprite.flip_h = not face_right
	
	for hitbox in hitboxes:
		hitbox.scale.x = scale_x
	
	for hurtbox in hurtboxes:
		hurtbox.scale.x = scale_x

func play_animation(anim_name):
	if animation.current_animation != anim_name:
		animation.play(anim_name)

func _on_animation_finished(anim_name):
	match anim_name:
		"light_punch", "light_kick", "heavy_punch", "heavy_kick":
			is_attacking = false
		"crouch":
			is_crouching = false
		"crouch_lightKick", "crouch_lightPunch":
			is_crouching = false
			is_attacking = false
		"light_hurt", "heavy_hurt":
			is_hurt = false
			is_attacking = false
			is_defending = false
			is_dashing = false
		"standing_block":
			is_defending = false

func KO():
	play_animation("knocked_down")
