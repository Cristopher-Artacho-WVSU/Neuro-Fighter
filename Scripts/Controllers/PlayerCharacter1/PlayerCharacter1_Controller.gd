extends CharacterBody2D

# CONSTANTS
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
const DEFENSE_TRIGGER_TIME = 1.0
const BASE_SPEED: float = 300.0
const DASH_SPEED: float = 1000.0
const DASH_DURATION: float = 0.3
const DASH_COOLDOWN: float = 0.4
const MOVEMENT_SMOOTHING: float = 8.0
const JUMP_FORCE: float = -1200.0
const HIT_THRESHOLD = 10.0

# NODE REFERENCES
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var enemy = get_parent().get_node("NPCCharacter1") as Node2D
@onready var hurtboxes = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxes = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]

# STATE VARIABLES
var is_jumping := false
var is_hurt := false
var is_crouching := false
var is_attacking := false
var is_defending := false
var is_dashing := false

# TIMERS
var dash_cooldown_timer: float = 0.0
var current_dash_timer: float = 0.0
var idle_timer: float = 0.0
var backward_timer: float = 0.0
var dash_velocity := Vector2.ZERO

# PRECOMPUTED VALUES
var enemy_to_right: bool = false

func _ready():
	# CONNECT SIGNALS ONCE
	animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
	for hurtbox in hurtboxes:
		hurtbox.connect("area_entered", Callable(self, "_on_hurtbox_area_entered"))

func _physics_process(delta):
	# PRE-COMPUTE ENEMY POSITION ONCE PER FRAME
	enemy_to_right = enemy.position.x > position.x
	
	# HANDLE DEFENSE TRIGGERS
	handle_defense_triggers(delta)
	
	# HANDLE DASH STATE
	handle_dash(delta)
	
	# APPLY GRAVITY
	apply_gravity(delta)
	
	# PROCESS MOVEMENT IF NOT IN BLOCKED STATE
	if !is_attacking && !is_defending && !is_hurt && !is_dashing:
		handle_movement_input(delta)
	
	# PROCESS ATTACK INPUT
	AttackSystem()
	
	# UPDATE FACING DIRECTION
	update_facing_direction()
	
	# APPLY MOVEMENT
	move_and_slide()

func handle_defense_triggers(delta):
	# RESET DEFENSE IF IN BLOCKED STATE
	if is_attacking || is_jumping || is_hurt || is_dashing:
		idle_timer = 0.0
		backward_timer = 0.0
		is_defending = false
		return
	
	# STANDING STILL - INCREMENT IDLE TIMER
	if is_zero_approx(velocity.x) && is_on_floor():
		idle_timer += delta
		backward_timer = 0.0
	else:
		idle_timer = 0.0
		# MOVING BACKWARD - INCREMENT BACKWARD TIMER
		if (enemy_to_right && velocity.x < 0) || (!enemy_to_right && velocity.x > 0):
			backward_timer += delta
		else:
			backward_timer = 0.0
	
	# TRIGGER DEFENSE IF TIMER REACHES THRESHOLD
	if idle_timer >= DEFENSE_TRIGGER_TIME || backward_timer >= DEFENSE_TRIGGER_TIME:
		start_defense()

func handle_dash(delta):
	# HANDLE DASH COOLDOWN
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# HANDLE ACTIVE DASH
	if is_dashing:
		current_dash_timer -= delta
		if current_dash_timer <= 0:
			end_dash()
		else:
			velocity.x = dash_velocity.x
			# SMOOTH DASH ENDING
			if current_dash_timer < DASH_DURATION * 0.3:
				velocity.x = lerp(0.0, dash_velocity.x, current_dash_timer / (DASH_DURATION * 0.3))

func apply_gravity(delta):
	# APPLY GRAVITY WHEN NOT ON FLOOR
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if not is_jumping:
			is_jumping = true
	elif is_jumping:
		# RESET JUMP STATE WHEN LANDING
		is_jumping = false
		velocity.y = 0

func handle_movement_input(delta):
	var move_right = Input.is_action_pressed("right_movement")
	var move_left = Input.is_action_pressed("left_movement")
	
	# DASH INPUT HANDLING
	if (move_left || move_right) && dash_cooldown_timer <= 0 && is_on_floor():
		start_dash(1 if move_right else -1)
		return
	
	# NORMAL MOVEMENT
	var target_velocity = 0.0
	if move_right:
		target_velocity = BASE_SPEED
	elif move_left:
		target_velocity = -BASE_SPEED
	
	# APPLY SMOOTH MOVEMENT
	velocity.x = lerp(velocity.x, target_velocity, MOVEMENT_SMOOTHING * delta)
	
	# ANIMATION HANDLING
	if abs(velocity.x) > HIT_THRESHOLD:
		if (enemy_to_right && velocity.x > 0) || (!enemy_to_right && velocity.x < 0):
			animation.play("walk_forward")
		else:
			animation.play("walk_backward")
	else:
		animation.play("idle")
	
	# JUMPING INPUT
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_FORCE
		is_jumping = true

func start_dash(direction: int):
	# INITIATE DASH STATE
	is_dashing = true
	current_dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	dash_velocity = Vector2(direction * DASH_SPEED, 0)
	
	# DASH ANIMATION (UNCOMMENT WHEN READY)
	# if (enemy_to_right && direction > 0) || (!enemy_to_right && direction < 0):
	#     animation.play("dash_forward")
	# else:
	#     animation.play("dash_backward")

func end_dash():
	# CLEAN UP AFTER DASH
	is_dashing = false
	velocity.x = 0
	animation.play("idle")

func start_defense():
	# ENTER DEFENSE STATE
	is_defending = true
	velocity.x = 0
	animation.play("standing_block")

func AttackSystem():
	# SKIP IF ALREADY ATTACKING OR DASHING
	if is_attacking || is_dashing:
		return
	
	# HANDLE KICK INPUT
	if Input.is_action_just_pressed("kick"):
		execute_attack("light_kick")
	# HANDLE PUNCH INPUT
	elif Input.is_action_just_pressed("punch"):
		execute_attack("light_punch")

func execute_attack(anim_name: String):
	# INITIATE ATTACK
	is_attacking = true
	velocity.x = 0
	
	# STOP CURRENT ANIMATION IF NOT A LIGHT ATTACK
	if animation.is_playing() && !animation.current_animation.begins_with("light_"):
		animation.stop()
	
	# PLAY ATTACK ANIMATION
	animation.play(anim_name)

func update_facing_direction():
	# UPDATE SPRITE FLIPPING BASED ON ENEMY POSITION
	characterSprite.flip_h = !enemy_to_right
	var scale_x = 1 if enemy_to_right else -1
	
	# UPDATE HITBOX SCALING
	for hitbox in hitboxes:
		hitbox.scale.x = scale_x
	# UPDATE HURTBOX SCALING
	for hurtbox in hurtboxes:
		hurtbox.scale.x = scale_x

func _on_animation_finished(anim_name):
	# HANDLE ANIMATION FINISHED EVENTS
	match anim_name:
		"light_punch", "light_kick":
			# EXIT ATTACK STATE
			is_attacking = false
		"standing_block":
			# EXIT DEFENSE STATE
			is_defending = false
			animation.play("idle")
		"light_hurt", "heavy_hurt":
			# APPLY DAMAGE AND EXIT HURT STATE
			if get_parent().has_method("apply_damage_to_player1"):
				get_parent().apply_damage_to_player1(10)
			is_hurt = false
			is_attacking = false

func _on_hurtbox_area_entered(area: Area2D):
	# IGNORE IF DEFENDING OR NOT ENEMY HITBOX
	if is_defending || !area.is_in_group("Player2_Hitboxes"):
		return
	
	# CANCEL ANY CURRENT ATTACK WHEN HIT
	is_attacking = false
	is_dashing = false
	
	# ENTER HURT STATE
	is_hurt = true
	animation.play("light_hurt")

func KO():
	# PLAY KNOCKDOWN ANIMATION
	animation.play("knocked_down")
