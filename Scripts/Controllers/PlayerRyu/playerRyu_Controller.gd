extends CharacterBody2D

#SETTING UP THE VARIABLE FOR THE NODES
@onready var animation = $Animation
@onready var characterSprite = $AnimatedSprite2D
@onready var character = $Ryu
@onready var enemy = get_parent().get_node("Player2")


#SETTING UP CHARACTER CONFIGURATIONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_jumping = false


var movement_system: HumanRyu_Movements
var attack_system: HumanRyu_Attacks

#FUNCTION FOR FACING THE DIRECTION
func update_facing_direction():
	if enemy.position.x > position.x:
		characterSprite.flip_h = false  # Face right
	else:
		characterSprite.flip_h = true   # Face left

func _ready():
	movement_system = HumanRyu_Movements.new(animation, self)
	#attack_system = HumanRyu_Attacks(animation, self)
	
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
			animation.play("idle")
			
	movement_system.handle_movements()
	movement_system.handle_jump()
	
	#attack_system.handle_punch()
	#attack_system.handle_kick()
	#
	move_and_slide()
	
