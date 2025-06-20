extends Node

class_name HumanRyu_Attacks

var animation : AnimationPlayer
var player : CharacterBody2D
var is_attacking = false

# Initialize with animation and player reference
func _init(anim : AnimationPlayer, p : CharacterBody2D):
	animation = anim
	player = p

# Handle the punch action
func handle_punch():
	# Check if player is walking forward (player's velocity in the X direction is positive)
	var is_walking_forward = player.velocity.x > 0  # Declare the variable outside of the condition
	var crouch = Input.is_action_pressed("crouch")  # Check if the player is crouching

	# If not attacking and player is on the ground
	if Input.is_action_just_pressed("punch") and player.is_on_floor() and not is_attacking:
		is_attacking = true
		player.velocity.x = 0
		player.velocity.y = 0
		
		# If crouching, perform crouch punch
		#if crouch:
			#animation.play("crouch_punch")
		# If player is walking forward, do heavy punch
		if is_walking_forward:
			animation.play("heavy_punch")
		else:
			animation.play("light_punch")
		
		_connect_animation_finished()

# Handle the kick action
func handle_kick():
	# Check if player is walking forward (player's velocity in the X direction is positive)
	var is_walking_forward = player.velocity.x > 0  # Declare the variable outside of the condition
	var crouch = Input.is_action_pressed("crouch")  # Check if the player is crouching
	
	# If not attacking and player is on the ground
	if Input.is_action_just_pressed("kick") and player.is_on_floor() and not is_attacking:
		is_attacking = true
		player.velocity.x = 0
		player.velocity.y = 0
		
		# If crouching, perform crouch kick
		if crouch:
			animation.play("low_kick")
		# If player is walking forward, do heavy kick
		elif is_walking_forward:
			animation.play("heavy_kick")
		else:
			animation.play("light_kick")
		
		_connect_animation_finished()

# Connect the animation finished signal to a callback function
func _connect_animation_finished():
	if not animation.is_connected("animation_finished", Callable(self, "_on_attack_finished")):
		animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

# Callback function to reset attack state when animation finishes
func _on_attack_finished(_anim):
	is_attacking = false
	animation.stop()
