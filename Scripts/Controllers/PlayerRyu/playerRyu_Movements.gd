extends Node

#SETTING UP THE CLASS NAME
class_name HumanRyu_Movements

#SETTING UP THE CLASS CONFIGURATIONS
var animation : AnimationPlayer
var character : CharacterBody2D
var speed =  300

func _init(player_animation : AnimationPlayer, player_character : CharacterBody2D):
	animation = player_animation
	character = player_character
	

func handle_movements():
	var move_right = Input.is_action_pressed("right_movement")
	var move_left = Input.is_action_pressed("left_movement")
	var crouch = Input.is_action_pressed("crouch")
	
	# If player is grounded and not attacking or jumping
	#if character.is_on_floor() and not character.is_jumping and not character.attack_system.is_attacking:
	if character.is_on_floor() and not character.is_jumping:
		# Move to the right
		if move_right:
			character.velocity.x = speed
			animation.play("walk_forward")  # Play walk forward animation
		# Move to the left
		elif move_left:
			character.velocity.x = -speed
			animation.play("walk_backward")  # Play walk backward animation
		# Handle idle state when no movement
		else:
			character.velocity.x = 0
			animation.play("idle")  # Play idle animation when not moving
		
		# Handle crouch
		if crouch:  # If the crouch button is being pressed
			animation.play("crouch")  # Play the crouch animation
			character.velocity.x = 0
			character.velocity.y = 0  # Stop any movement while crouching
		else:
			# Stop crouch animation when not crouching
			if not move_right and not move_left: 
				animation.play("idle")  # Stop crouch animation and go back to idle
				

# Handle jumping
func handle_jump():
	if Input.is_action_just_pressed("jump") and character.is_on_floor():
		character.velocity.y = -450  # Apply jump velocity
		character.is_jumping = true
		animation.play("jump")  # Play jump animation
