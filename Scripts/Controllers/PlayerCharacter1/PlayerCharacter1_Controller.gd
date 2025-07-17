extends CharacterBody2D

#ONREADY VARIABLES
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var enemy = get_parent().get_node("NPCCharacter1")
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#MEASUREMENT VARIABLES
var speed =  300

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
const DEFENSE_TRIGGER_TIME = 0.5  # 2 seconds


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

	AttackSystem()
	MovementSystem()
	DamagedSystem()
	move_and_slide()
			
func handle_defense_triggers(delta):
	
	if is_attacking || is_jumping || is_hurt:
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
	if is_attacking:
		return
	
	var punch = Input.is_action_just_pressed("punch")
	var kick = Input.is_action_just_pressed("kick")
	if kick:
		#print("trying to kick")
		is_attacking = true
		velocity.x = 0
		animation.play("light_kick")
		_connect_animation_finished()
	if punch:
		#print("trying to punch")
		is_attacking = true
		velocity.x = 0
		animation.play("light_punch")
		_connect_animation_finished()
		
func MovementSystem():
	if is_attacking || is_jumping:
		return
		
	var move_right = Input.is_action_pressed("right_movement")
	var move_left = Input.is_action_pressed("left_movement")
	var crouch = Input.is_action_pressed("crouch")

	if move_right:
		#print("moving right")
		velocity.x = speed
		animation.play("walk_forward")
	elif move_left:
		#print("moving left")
		velocity.x = -speed
		animation.play("walk_backward")
	else:
		velocity.x = 0
		animation.play("idle")
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = -1200
			is_jumping = true
	
	if is_defending:
		if animation.current_animation != "standing_block":
			animation.play("standing_block")
		return

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
		
	if area.is_in_group("Player1_Hitboxes"):
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
	
