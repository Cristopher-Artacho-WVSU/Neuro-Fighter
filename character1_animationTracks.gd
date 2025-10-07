extends CharacterBody2D

func movement_step():
	# Small forward push depending on facing direction
	var push_force = 200
	velocity.x = push_force
