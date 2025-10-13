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
var jump_speed = 3000  # example, tune as needed
var fall_multiplier = 5.0
var jump_multiplier = 1.6

#VALUE VARIABLES
#DASHING MOVEMENT
var dash_speed = 300
var dash_time = 0.5  
var dash_timer = 0.0
var dash_direction = 0

#DEFENSE 
var last_input_time = 0.0
var defense_delay = 0.5

#BOOL STATES
#MOVEMENT
var is_dashing = false
var is_jumping = false
var is_crouching = false
#ATTACKS
var is_attacking = false
#HURTS
var is_defending = false
var is_hurt = false

#HITSTOP AND HITSTUN
var hitstop_id: int = 0
var is_in_global_hitstop: bool = false
var is_recently_hit: bool = false

#INITIATE VARIABLES, SETUP WHEN THE GAME STARTS
func _ready():
#	FOR MOST ANIMATIONS
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
#	FOR DAMAGED ANIMATONS
	if not animation.is_connected("animation_finished", Callable(self, "_on_hurt_finished")):
		animation.connect("animation_finished", Callable(self, "_on_hurt_finished"))
#RUNTIME
func _physics_process(delta):
#	DEFAULT ANIMATION WHEN NOT PERFORMING ACTIONS

#	CHANGE WHERE THE CHARACTER IS FACING
	update_facing_direction()
	
#	GRAVITY APPLICATION
	applyGravity(delta)
	
#	MOVEMENTS
	MovementSystem(delta)
#	ATTACKS
	AttackSystem()
#	HURT AND DEFENSE
	DamagedSystem(delta)
	
#	DEBUGGING PURPOSES:
	#debug_states()
	move_and_slide()
	
	
func debug_states():
	print("is_dashing", is_dashing)
	print("is_jumping state:", is_jumping)
	print("is_crouching", is_crouching)
	print("is_attacking state:", is_attacking)
	print("is_defending", is_defending)
	print("is_hurt state:", is_hurt)
	print("is_is_dashing", is_dashing)
	
func MovementSystem(delta):
	if is_attacking || is_defending || is_hurt:
		return
	
	var curr_distance_to_enemy = abs(enemy.position.x - position.x)
	var jump = Input.is_action_just_pressed("jump")
	var crouch = Input.is_action_just_pressed("crouch")
	var forward = Input.is_action_pressed("move_right")
	var backward = Input.is_action_pressed("move_left")
	
	
	if jump and not is_jumping:
		animation.play("jump")
		print("Jumped")
		velocity.y = -1200.0
		is_jumping = true
		_connect_animation_finished()
	
	if crouch and not is_jumping:
		animation.play("crouch")
		is_crouching = true
		_connect_animation_finished()
		
	#STARTING THE DASH
	if not is_dashing and not is_jumping:
		if forward:
			is_dashing = true
			dash_direction = 1
			dash_timer = dash_time
		elif backward:
			is_dashing = true
			dash_direction = -1
			dash_timer = dash_time
	
	if is_dashing and not is_jumping:
		velocity.x = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = 0
	else:
		if not is_crouching and not is_jumping:
			animation.play("idle")
			velocity.x = 0
	
	if velocity.x != 0 and is_jumping:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("jump_forward")
			_connect_animation_finished()
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("jump_backward")
			_connect_animation_finished()
	elif velocity.x != 0:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("move_forward")
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("move_backward")
	prev_distance_to_enemy = curr_distance_to_enemy

func AttackSystem():
	if is_attacking || is_jumping || is_hurt:
		return
	
	var punch = Input.is_action_just_pressed("punch")
	var kick = Input.is_action_just_pressed("kick")
	var heavy_punch = Input.is_action_just_pressed("heavy_punch")
	var heavy_kick = Input.is_action_just_pressed("heavy_kick")
	
	
	# Direction to enemy: +1 = enemy on right, -1 = enemy on left
	var dir_to_enemy = sign(enemy.position.x - position.x)
	
	# Check if player is pressing toward the enemy
	var moving_toward_enemy = (
		(dir_to_enemy == 1 and Input.is_action_pressed("move_right")) or
		(dir_to_enemy == -1 and Input.is_action_pressed("move_left"))
	)

	if punch:
		if is_crouching:
			animation.play('crouch_lightPunch')
			is_attacking = true
			_connect_animation_finished()
		else:
			animation.play("light_punch")
			is_attacking = true
			_connect_animation_finished()
			velocity.x = 0
	if kick:
		if is_crouching:
			animation.play('crouch_lightKick')
			is_attacking = true
			_connect_animation_finished()
		else:
			animation.play("light_kick")
			is_attacking = true
			_connect_animation_finished()
			velocity.x = 0

	if heavy_punch:
		if is_crouching:
			animation.play("crouch_heavyPunch")
			is_attacking = true
			_connect_animation_finished()
			velocity.x = 0
		else:
			animation.play("heavy_punch")
			is_attacking = true
			_connect_animation_finished()
			velocity.x = 0
			
	if heavy_kick:
		animation.play("heavy_kick")
		is_attacking = true
		_connect_animation_finished()
		velocity.x = 0

func DamagedSystem(delta):
	#print("DamagedSystem is enabled")
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") \
	or Input.is_action_pressed("jump") or Input.is_action_pressed("crouch") \
	or Input.is_action_pressed("punch") or Input.is_action_pressed("kick"):
		last_input_time = 0.0
		is_defending = false
	else:
		last_input_time += delta
		if last_input_time >= defense_delay:
			is_defending = true

	if $Hurtbox_UpperBody and $Hurtbox_UpperBody.has_signal("area_entered"):
		if not $Hurtbox_UpperBody.is_connected("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered")):
			$Hurtbox_UpperBody.connect("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered"))
			
	if $Hurtbox_LowerBody and $Hurtbox_LowerBody.has_signal("area_entered"):
		if not $Hurtbox_LowerBody.is_connected("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered")):
			$Hurtbox_LowerBody.connect("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered"))

func _on_hurtbox_upper_body_area_entered(area: Area2D):
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	if area.is_in_group("Player2_Hitboxes"):
		is_recently_hit = true  # Mark as hit immediately
		#print("Upper attack received")
		if is_defending:
			print("Player 1 blocked the attack (upper body)")
			velocity.x = 0
			apply_hitstop(0.3)  # brief pause (0.2 seconds)
			animation.play("standing_block")  # play block only on hit
			
		else:
			print("Player 1 Upper body hit taken")
			is_hurt = true
			velocity.x = 0
			apply_hitstop(0.3)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			enemy.upper_attacks_landed +=1
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
			apply_hitstop(0.3)  # brief pause (0.2 seconds)
			animation.play("standing_block")  # play block only on hit
		else:
			print("Player 1 Lower body hit taken")
			is_hurt = true
			velocity.x = 0
			apply_hitstop(0.3)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			enemy.lower_attacks_landed +=1
		_connect_hurt_animation_finished()
		
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false


func _connect_hurt_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_hurt_finished")):
		animation.connect("animation_finished", Callable(self, "_on_hurt_finished"))
		
func _on_hurt_finished(anim_name):
#	IF is_defending, REDUCE THE DAMAGE BY 30%
	if is_defending and anim_name == "standing_block":
		if get_parent().has_method("apply_damage_to_player1"):
			get_parent().apply_damage_to_player1(7)
		animation.play("idle")
		
	else:
#		IF PLAYER IS NOT DEFENDING WHENT HE DAMAGE RECEIVED
		if anim_name == "light_hurt" or anim_name == "heavy_hurt":
			if get_parent().has_method("apply_damage_to_player1"):
				get_parent().apply_damage_to_player1(10)
			animation.play("idle")

#	AFTER THE ATTACK, is_hurt IS TURNED TO FALSE
		is_hurt = false
		is_attacking = false
		is_defending = false
		is_dashing = false
	print("Attack animation finished:", anim_name)


func update_facing_direction():
	if enemy.position.x > position.x:
		characterSprite.flip_h = false  # Face right
		for hitbox in hitboxGroup:
			hitbox.scale.x = 1  # Or flip_h if it's a Sprite/AnimatedSprite2D
		for hurtbox in hurtboxGroup:
			hurtbox.scale.x = 1
	else:
		characterSprite.flip_h = true   # Face left
		for hitbox in hitboxGroup:
			hitbox.scale.x = -1
		for hurtbox in hurtboxGroup:
			hurtbox.scale.x = -1
			
#CALL THE ANIMATION, AND PASS THE ANIMATION NAME TO IT 
func _connect_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))

#RELEASE THE STATES IN ORDER TO MAKE NEW ACTIONS 
func _on_animation_finished(anim_name):
	match anim_name:
		"light_punch":
			is_attacking = false
		"light_kick":
			is_attacking = false
		"heavy_punch":
			is_attacking = false
		"heavy_kick":
			is_attacking = false
		"crouch":
			is_crouching = false
		"crouch_lightKick":
			is_crouching = false
			is_attacking = false
		"crouch_lightPunch":
			is_crouching = false
			is_attacking = false
		"crouch_heavyPunch":
			is_crouching = false
			is_attacking = false
		"jump":
			is_jumping = false
			pass
		"jump_forward":
			is_jumping = false
			pass
		"jump_backward":
			is_jumping = false
			pass
			
func KO():
	animation.play("knocked_down")
	_connect_hurt_animation_finished()
	
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

func displacement_small():
	velocity.x = 100
	
func displacement_verySmall():
	velocity.x = 50

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
