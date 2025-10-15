extends CharacterBody2D

#ONREADY VARIABLES
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var enemy = get_parent().get_node("NPCCharacter1")
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var prev_distance_to_enemy = abs(enemy.position.x - position.x)

#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#JUMP PARAMETERS
var jump_speed = 3000
var fall_multiplier = 5.0
var jump_multiplier = 1.6
var jump_force = -1200.0
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

func _ready():
	#	FOR MOST ANIMATIONS
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
	#	FOR DAMAGED ANIMATONS
	if not animation.is_connected("animation_finished", Callable(self, "_on_hurt_finished")):
		animation.connect("animation_finished", Callable(self, "_on_hurt_finished"))

 
func _physics_process(delta):
	update_facing_direction()
	applyGravity(delta)
	
	MovementSystem(delta)
	AttackSystem()
	DefenseSystem(delta)
	#debug_states()
	move_and_slide()

func MovementSystem(delta):
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
		velocity.y = -1200.0
		is_jumping = true
		_connect_animation_finished()
	
	# Handle Crouch
	if crouch and not is_jumping:
		animation.play("crouch")
		is_crouching = true
		_connect_animation_finished()
	
	# Handle Dash
	handle_dash_movement(forward, backward, delta)
	
	# Handle Idle and Movement Animations
	handle_movement_animations(curr_distance_to_enemy)
	
	prev_distance_to_enemy = curr_distance_to_enemy


func handle_dash_movement(forward: bool, backward: bool, delta: float):
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
	if not is_crouching and not is_jumping and not is_dashing:
		animation.play("idle")
		velocity.x = 0
	
	if velocity.x != 0 and is_jumping:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("jump_forward")
			_connect_animation_finished()
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("jump_backward")
			_connect_animation_finished()
	elif velocity.x != 0 and not is_jumping:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("move_forward")
			_connect_animation_finished()
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("move_backward")
			_connect_animation_finished()

func start_dash(direction):
	is_dashing = true
	dash_direction = direction
	dash_timer = dash_time


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
	_connect_animation_finished()

# ===== DEFENSE AND DAMAGE SYSTEM =====
func DefenseSystem(delta):
	if 	Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or Input.is_action_pressed("jump") or Input.is_action_pressed("crouch") or Input.is_action_pressed("punch") or Input.is_action_pressed("kick"):
		last_input_time = 0.0
		is_defending = false
	else:
		last_input_time += delta
		if last_input_time >= defense_delay:
			is_defending = true
	
	if $Hurtbox_UpperBody and not $Hurtbox_UpperBody.is_connected("area_entered", _on_hurtbox_upper_body_area_entered):
		$Hurtbox_UpperBody.connect("area_entered", _on_hurtbox_upper_body_area_entered)
		
	if $Hurtbox_LowerBody and not $Hurtbox_LowerBody.is_connected("area_entered", _on_hurtbox_lower_body_area_entered):
		$Hurtbox_LowerBody.connect("area_entered", _on_hurtbox_lower_body_area_entered)

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
			
		else:
			print("Player 1 Upper body hit taken")
			is_hurt = true
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			#enemy.upper_attacks_landed +=1
		_connect_hurt_animation_finished()
		
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
		else:
			print("Player 1 Lower body hit taken")
			is_hurt = true
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			#enemy.lower_attacks_landed +=1c
		_connect_hurt_animation_finished()
		
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false


func _connect_hurt_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_hurt_finished")):
		animation.connect("animation_finished", Callable(self, "_on_hurt_finished"))
		
func _on_hurt_finished(anim_name):
#	IF is_defending, REDUCE THE DAMAGE BY 30%
	if is_defending or anim_name == "standing_block":
		if get_parent().has_method("apply_damage_to_player1"):
			get_parent().apply_damage_to_player1(7)
		animation.play("idle")
	else:
#		IF PLAYER IS NOT DEFENDING WHENT HE DAMAGE RECEIVED
		if anim_name == "light_hurt" or anim_name == "heavy_hurt":
			if get_parent().has_method("apply_damage_to_player1"):
				get_parent().apply_damage_to_player1(7)
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

func _connect_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))

# ===== ANIMATION HANDLING =====
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
	
	
