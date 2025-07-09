extends CharacterBody2D
# ONREADY VARIABLES
@onready var enemy = get_parent().get_node("PlayerCharacter1")
@onready var distance = position.distance_to(enemy.position)
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var opponentHitboxes = [
	get_parent().get_node("PlayerCharacter1/Hitbox_LeftFoot/CollisionShape2D"),
	get_parent().get_node("PlayerCharacter1/Hitbox_RightFoot/CollisionShape2D"),
	get_parent().get_node("PlayerCharacter1/Hitbox_LeftHand/CollisionShape2D"),
	get_parent().get_node("PlayerCharacter1/Hitbox_RightHand/CollisionShape2D")
]

# ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# MEASUREMENT VARIABLES
var speed = 300

# STATE VARIABLES
var is_jumping = false
var is_hurt = false
var in_combo = false
var is_crouching = false
var is_attacking = false

func _ready():
	$Hurtbox_UpperBody.area_entered.connect(Callable(self, "_on_hurtbox_entered").bind("Hurtbox_Upper"))
	$Hurtbox_UpperBody.area_entered.connect(Callable(self, "_on_hurtbox_entered").bind("Hurtbox_Lower"))
	
func _process(delta):
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

	if not is_attacking:
		DTAttackSystem()
		if not is_attacking:
			DTMovementSystem()

	move_and_slide()


func _on_hurtbox_entered(hitbox: Area2D, hurtbox_name: String):
	var hitbox_name = hitbox.get_parent().name
	print("Hitbox: %s detected in %s" % [hitbox_name, hurtbox_name])

func DTMovementSystem():
	if not is_instance_valid(enemy):
		return
	
	var distance = global_position.distance_to(enemy.position)
	
	if distance > 325:
		# Determine movement direction
		if enemy.position.x > position.x:
			# Move right
			velocity.x = speed
			animation.play("walk_forward")
		else:
			# Move left
			velocity.x = -speed
			animation.play("walk_backward")
	else:
		# Stop when within range
		velocity.x = 0
		animation.play("idle")


func DTAttackSystem():
	if not is_instance_valid(enemy):
		return

	var current_distance = global_position.distance_to(enemy.global_position)

	if current_distance <= 315:
		if not is_attacking:
			print("Attacking enemy at distance:", current_distance)
			is_attacking = true
			velocity.x = 0
			animation.play("light_punch")
			_connect_animation_finished()
	elif current_distance <= 325:
		if not is_attacking:
			is_attacking = true
			velocity.x = 0
			animation.play("light_kick")
			_connect_animation_finished()
	else:
		print("Enemy too far to attack: ", current_distance)



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
		print("Attack animation finished:", anim_name)
