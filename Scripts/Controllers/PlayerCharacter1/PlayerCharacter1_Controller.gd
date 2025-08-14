extends CharacterBody2D

#ONREADY VARIABLES
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var enemy = get_parent().get_node("NPCCharacter1")
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#MOVEMENT VARIABLES
var base_speed: float = 300.0
var dash_speed: float = 1000.0
var dash_duration: float = 0.3
var dash_cooldown: float = 0.4
var current_dash_timer: float = 0.0
var dash_direction: int = 0
var is_dashing: bool = false
var dash_cooldown_timer:float = 0.0
var dash_velocity = Vector2.ZERO
var movement_smoothing: float = 8.0

#BOOL STATEMENTS
var is_jumping = false
var is_hurt = false
var in_combo = false
var is_crouching = false
var is_attacking = false
var is_defending = false

#TIMERS
var heavyHurt_timer = 0.5
var combo_timer = 0.5
var idle_timer = 0.0
var backward_timer = 0.0
const DEFENSE_TRIGGER_TIME = 1.0  # 2 seconds


func _ready():
	is_jumping = false
	is_hurt = false
	in_combo = false
	is_crouching = false
	is_attacking = false
	if not enemy:
		print("enemy not found")
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

func _physics_process(delta):
	if is_hurt:
		return
	update_facing_direction()
	
	handle_defense_triggers(delta)
	
	if not is_on_floor():
		velocity.y += gravity * delta
		if not is_jumping:
			is_jumping = true
	else:
		velocity.y = 0
		if is_jumping:
			is_jumping = false

	#HANDLE DASH COOLDOWN
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		
	#HANDLE ACTIVE DASH
	if is_dashing:
		current_dash_timer -= delta
		if current_dash_timer <= 0:
			end_dash()
		else:
			#APPLY DASH VELOCITY
			velocity.x = dash_velocity.x
			#SMOOTHLY END VELOCITY AT THE END OF DASH
			if current_dash_timer < dash_duration * 0.3:
				velocity.x = lerp(0.0, float(dash_velocity.x), float(current_dash_timer) / (float(dash_duration) * 0.3))

	AttackSystem()
	if !is_attacking && !is_defending && !is_hurt && !is_dashing:
		MovementSystem(delta)
	DamagedSystem()
	move_and_slide()
			
func handle_defense_triggers(delta):
	
	if is_attacking || is_jumping || is_hurt || is_dashing:
		idle_timer = 0.0
		backward_timer = 0.0
		is_defending = false
		return
	
	#IF NOT MOVING, PLUS IDLE TIMER
	if velocity.x == 0 && is_on_floor():
		idle_timer += delta
		backward_timer = 0.0
	else:
		idle_timer = 0.0
		
		#CHECK MOVING BACKWARD
		var is_moving_backward = false
		if enemy.position.x > position.x:  #ENEMY RIGHT
			is_moving_backward = velocity.x < 0
		else:  #ENEMY LEFT
			is_moving_backward = velocity.x > 0
		
		#ADD TIMER
		if is_moving_backward:
			backward_timer += delta
		else:
			backward_timer = 0.0
	
	#TRIGGER DEFENSE IF RIGHT TIME
	if idle_timer >= DEFENSE_TRIGGER_TIME || backward_timer >= DEFENSE_TRIGGER_TIME:
		start_defense()
		
func start_defense():
	is_defending = true
	velocity.x = 0
	animation.play("standing_block")
	_connect_animation_finished()

func AttackSystem():
	if is_attacking || is_dashing:
		return
	
	var punch = Input.is_action_just_pressed("punch")
	var kick = Input.is_action_just_pressed("kick")
	if kick:
		is_attacking = true
		velocity.x = 0
		if animation.is_playing() && !animation.current_animation.begins_with("light_"):
			animation.stop()
		animation.play("light_kick")
		_connect_animation_finished()
	if punch:
		is_attacking = true
		velocity.x = 0
		if animation.is_playing() && !animation.current_animation.begins_with("light_"):
			animation.stop()
		animation.play("light_punch")
		_connect_animation_finished()
		
func MovementSystem(delta):
	if is_attacking || is_jumping || is_defending || is_hurt:
		return

	var move_right = Input.is_action_pressed("right_movement")
	var move_left = Input.is_action_pressed("left_movement")
	
	if (move_left or move_right) and dash_cooldown_timer <= 0 and is_on_floor():
		var dash_direction
		if move_right:
			dash_direction = 1
		elif move_left:
			dash_direction = -1
		else:
			dash_direction = 1 if characterSprite.flip_h == false else -1
			
		start_dash(dash_direction)
	
	#NORMAL MOVEMENT
	if !is_dashing:
		var target_velocity = 0.0
		
		if move_right:
			target_velocity = base_speed
		elif move_left:
			target_velocity = -base_speed
		
		#SMOOTHLY ITERPOLATE TO TARGET VELOCITY
		velocity.x = lerp(float(velocity.x), float(target_velocity), movement_smoothing * delta)
		
		#ANIMATION HANDLING
		if abs(velocity.x) > 10:  # Small threshold to prevent jitter
			if (enemy.position.x > position.x and velocity.x > 0) or (enemy.position.x < position.x and velocity.x < 0):
				animation.play("walk_forward")
			else:
				animation.play("walk_backward")
		else:
			animation.play("idle")

	#JUMPING LOGIC
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -1200.0
		is_jumping = true

func start_dash(dash_direction):
	
	#SET DASH STATE
	is_dashing = true
	current_dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_velocity = Vector2(dash_direction * dash_speed, 0)
	
	#PLAY DASH ANIMATION
	if (enemy.position.x > position.x and dash_direction > 0) or (enemy.position.x < position.x and dash_direction < 0):
		#animation.play("dash_forward")  # Create this animation
		pass
	else:
		#animation.play("dash_backward")  # Create this animation
		pass

func end_dash():
	is_dashing = false
	velocity.x = 0
	animation.play("idle")

func DamagedSystem():
	if $Hurtbox_LowerBody and $Hurtbox_LowerBody.has_signal("area_entered"):
		if not $Hurtbox_LowerBody.is_connected("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered")):
			$Hurtbox_LowerBody.connect("area_entered", Callable(self, "_on_hurtbox_lower_body_area_entered"))
	
	if $Hurtbox_UpperBody and $Hurtbox_UpperBody.has_signal("area_entered"):
		if not $Hurtbox_UpperBody.is_connected("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered")):
			$Hurtbox_UpperBody.connect("area_entered", Callable(self, "_on_hurtbox_upper_body_area_entered"))

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


func _connect_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

# Callback function to reset attack state when animation finishes
func _on_attack_finished(anim_name):
	match anim_name:
		"light_punch", "light_kick":
			is_attacking = false
		"standing_block":
			is_defending = false
			# Return to idle after defense
			animation.play("idle")


func _on_hurtbox_upper_body_area_entered(area: Area2D):
	if is_defending:
		return
		
#	MADE GROUP FOR ENEMY NODES "Player2_Hitboxes" 
	if area.is_in_group("Player2_Hitboxes"):
		print("Player 1 Upper body hit taken")
		is_hurt = true
		animation.play("light_hurt")
		_connect_hurt_animation_finished()


func _on_hurtbox_lower_body_area_entered(area: Area2D):
	if is_defending:
		return 
		
	if area.is_in_group("Player2_Hitboxes"):
		print("Player 1 Lower body hit taken")
		is_hurt = true
		animation.play("light_hurt")
		_connect_hurt_animation_finished()

		#print("Attack animation finished:", anim_name)
	

func _connect_hurt_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_hurt_finished")):
		animation.connect("animation_finished", Callable(self, "_on_hurt_finished"))
		
func _on_hurt_finished(anim_name):
	if anim_name == "light_hurt" or anim_name == "heavy_hurt":
		if get_parent().has_method("apply_damage_to_player1"):
			get_parent().apply_damage_to_player1(10)
		is_hurt = false
		print("Attack animation finished:", anim_name)

func KO():
	animation.play("knocked_down")
	_connect_hurt_animation_finished()
	
