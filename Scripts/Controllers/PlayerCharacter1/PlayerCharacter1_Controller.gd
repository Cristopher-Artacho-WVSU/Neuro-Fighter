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
var is_attacking = true
#TIMERS
var heavyHurt_timer = 0.5
var combo_timer = 0.5


func _ready():
	if not enemy:
		print("enemy not found")
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

func _physics_process(delta):
	update_facing_direction()
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

	DamagedSystem()      # Handle input for attack first
	MovementSystem()     # Then check for movement (skipped if attacking)
	move_and_slide()
	
func MovementSystem():
	if is_attacking:
		return  # Skip movement animation if attacking
	
	if is_jumping:
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
			
func DamagedSystem():
	if is_jumping:
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
	pass

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
	if anim_name == "light_punch" or anim_name == "light_kick":
		is_attacking = false
		#print("Attack animation finished:", anim_name)
