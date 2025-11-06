extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK }
var current_state = State.IDLE
var state_timer = 0.0
var state_interval = 1.0 # time between FSM decisions (1 second)
var has_executed_attack = false
var rng = RandomNumberGenerator.new()

#ONREADY VARIABLES FOR THE CURRENT PLAYER
@onready var animation = $AnimationPlayer
@onready var characterSprite = $AnimatedSprite2D
@onready var hurtboxGroup = [$Hurtbox_LowerBody, $Hurtbox_UpperBody]
@onready var hitboxGroup = [$Hitbox_LeftFoot, $Hitbox_LeftHand, $Hitbox_RightFoot, $Hitbox_RightHand]
@onready var playerDetails = get_parent().get_node("PlayerDetailsUI/Player2Details")
@onready var generateScript_timer = Timer.new()

#ONREADY VARIABLES FOR THE OTHER PLAYER
@onready var enemy = get_parent().get_node("PlayerCharacter1")
@onready var enemyAnimation = enemy.get_node("AnimationPlayer")
@onready var enemy_UpperHurtbox = enemy.get_node("Hurtbox_UpperBody")
@onready var enemy_LowerHurtbox = enemy.get_node("Hurtbox_LowerBody")
@onready var prev_distance_to_enemy = abs(enemy.position.x - position.x)

#ADDONS
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#JUMP
var jump_speed = 3000 
var fall_multiplier = 5.0
var jump_multiplier = 1.6
var jump_force = -1200.0

#HITSTOPS
var hitstop_id: int = 0
var is_in_global_hitstop: bool = false
var is_recently_hit: bool = false

#VALUE VARIABLES
#MOVEMENT
var dash_speed = 300
var dash_time = 0.5
var dash_timer = 0.0
var dash_direction = 0

#DEFENSE 
var last_input_time = 0.0
var defense_delay = 0.5

#BOOL STATES
#MOVEMENTS
var is_dashing = false
var is_jumping = false
var is_crouching = false
#ATTACKS
var is_attacking = false
#DEFENSE
var is_defending = false
var is_hurt = false

#ATTACKS
const lightPunch_Range = 315
const heavyPunch_Range = 315
const lightKick_Range = 345
const heavyKick_Range = 345
const crouch_heavyPunch_Range = 315
const crouch_lightPunch_Range = 315
const crouch_lightKick_Range = 325



func _ready() -> void:
	randomize()
	rng.randomize()
	var is_defending = false
	var is_hurt = false
	var is_attacking = false
	var is_dashing = false
	var is_jumping = false
	var is_crouching = false
	if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
		
	print("Animation connected:", animation.is_connected("animation_finished", Callable(self, "_on_animation_finished")))
	
	if $Hurtbox_UpperBody and not $Hurtbox_UpperBody.is_connected("area_entered", _on_hurtbox_upper_body_area_entered):
			$Hurtbox_UpperBody.connect("area_entered", _on_hurtbox_upper_body_area_entered)
		
	if $Hurtbox_LowerBody and not $Hurtbox_LowerBody.is_connected("area_entered", _on_hurtbox_lower_body_area_entered):
		$Hurtbox_LowerBody.connect("area_entered", _on_hurtbox_lower_body_area_entered)


func _physics_process(delta):
	var direction = 1 if enemy.global_position.x > global_position.x else -1
	
	update_facing_direction()
	applyGravity(delta)
	DamagedSystem(delta)
	debug_states()
	# FSM behavior decision every interval
	state_timer += delta
	if state_timer >= state_interval and not (is_attacking or is_hurt or is_jumping):
		state_timer = 0.0
		select_state()  # Decide next state randomly

	# State execution
	match current_state:
		State.MOVE:
			MovementSystem(get_direction())
			has_executed_attack = false
		State.ATTACK:
			if not has_executed_attack and not is_attacking:
				attackSystem()
				has_executed_attack = true
		State.IDLE:
			velocity.x = 0
			animation.play("idle")
			has_executed_attack = false
	
	move_and_slide()

func select_state():
	var choice = rng.randf()  # 0.0–1.0
	if choice < 0.7:
		current_state = State.MOVE
	else:
		current_state = State.ATTACK

func get_direction() -> int:
	# MovementSystem probability split: 0.6 forward, 0.4 backward
	var move_choice = rng.randf()
	if move_choice < 0.6:
		return 1  # forward
	else:
		return -1  # backward

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

func MovementSystem(ai_move_direction: int, delta := 1.0 / 60.0):
	if is_attacking || is_jumping || is_hurt:
		return
		
	var curr_distance_to_enemy = abs(enemy.position.x - position.x)
	
	if curr_distance_to_enemy >=345 and not is_dashing:
		if ai_move_direction == 1:
			is_dashing = true
			dash_direction = 1
			dash_timer = dash_time
			
		elif ai_move_direction == -1:
			is_dashing = true
			dash_direction = -1
			dash_timer = dash_time
		
	if is_dashing:
		velocity.x = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = 0
			
	# Movement animations
	if velocity.x != 0:
		if curr_distance_to_enemy < prev_distance_to_enemy:
			animation.play("move_forward")
		elif curr_distance_to_enemy > prev_distance_to_enemy:
			animation.play("move_backward")
	
	prev_distance_to_enemy = curr_distance_to_enemy

func DamagedSystem(delta):
#	DEFENSIVE MECHANISM
	if not is_dashing and not is_jumping and not is_crouching and not is_attacking and not is_defending and not is_hurt:
		last_input_time = 0.0
		is_defending = true
	else:
		last_input_time += delta
		if last_input_time >= defense_delay:
			is_defending = false

func _on_hurtbox_upper_body_area_entered(area: Area2D):
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	if area.is_in_group("Player1_Hitboxes"):
		is_recently_hit = true  # Mark as hit immediately
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block") 
			applyDamage(7)
			print(" Upper Damaged From Blocking")
		else:
			is_hurt = true
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			print("Current animation:", animation.current_animation)
			applyDamage(10)
			print("Player 2 Upper body hit taken")
		# Reset hit immunity after short real-time delay
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false
		
func _on_hurtbox_lower_body_area_entered(area: Area2D):
	if is_recently_hit:
		return  # Ignore duplicate hits during hitstop/hitstun
	#	MADE GROUP FOR ENEMY NODES "Player1_Hitboxes" 
	if area.is_in_group("Player1_Hitboxes"):
		is_recently_hit = true  # Mark as hit immediately
		if is_defending:
			velocity.x = 0
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("standing_block")
			applyDamage(7)
			print("Lower Damaged From Blocking")
		else:
			is_hurt = true
			apply_hitstop(0.15)  # brief pause (0.2 seconds)
			animation.play("light_hurt")
			print("Current animation:", animation.current_animation)
			applyDamage(10)
			print("Player 2 Lower body hit taken")
		
		await get_tree().create_timer(0.2, true).timeout
		is_recently_hit = false
		
func applyDamage(amount: int):
	if get_parent().has_method("apply_damage_to_player2"):
		get_parent().apply_damage_to_player2(amount)

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

func attackSystem():
	if not is_instance_valid(enemy):
		return
		
	var current_distance = global_position.distance_to(enemy.global_position)

	# Attack selection (50% total; evenly distributed among 7 attacks)
	var attacks = [
		{"name": "light_kick", "range": lightKick_Range},
		{"name": "heavy_kick", "range": heavyKick_Range},
		{"name": "light_punch", "range": lightPunch_Range},
		{"name": "heavy_punch", "range": heavyPunch_Range},
		{"name": "crouch_lightKick", "range": crouch_lightKick_Range},
		{"name": "crouch_lightPunch", "range": crouch_lightPunch_Range},
		{"name": "crouch_heavyPunch", "range": crouch_heavyPunch_Range},
	]

	var selected_attack = attacks[rng.randi_range(0, attacks.size() - 1)]
	if current_distance <= selected_attack["range"]:
		chooseAttack(selected_attack["name"])
		


func chooseAttack(attack):
	match attack:
		"light_kick":
			velocity.x = 0
			velocity.y = 0
			animation.play("light_kick")
			
		"heavy_kick":
			velocity.x = 0
			velocity.y = 0
			animation.play("heavy_kick")
		"light_punch":
			velocity.x = 0
			velocity.y = 0
			animation.play("light_punch")
		"heavy_punch":
			velocity.x = 0
			velocity.y = 0
			animation.play("heavy_punch")
		"crouch_lightKick":
			velocity.x = 0
			velocity.y = 0
			animation.play("crouch_lightKick")
		"crouch_lightPunch":
			velocity.x = 0
			velocity.y = 0
			animation.play("crouch_lightPunch")
		"crouch_heavyPunch":
			velocity.x = 0
			velocity.y = 0
			animation.play("crouch_heavyPunch")
	
	
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
		"light_hurt", "heavy_hurt":
			is_hurt = false
			is_attacking = false
			is_defending = false
			is_dashing = false
		"move_forward", "move_backward":
			is_dashing = false
	velocity.x = 0
	animation.play("idle")
	current_state = State.IDLE
	
func debug_states():
	print("is_dashing: ", is_dashing)
	print("is_jumping state: ", is_jumping)
	print("is_crouching: ", is_crouching)
	print("is_attacking state: ", is_attacking)
	print("is_defending: ", is_defending)
	print("is_hurt state: ", is_hurt)
	
func KO():
	animation.play("knocked_down")
	#
	## Choose attack based on distance
	#if  current_distance <= ATTACK_RANGE_KICK:
		## Close range - use punch
		#start_attack("light_punch", current_distance)
	#elif current_distance >= ATTACK_RANGE_KICK and current_distance <= ATTACK_RANGE_LIMIT:
		## Medium range - use kick
		#start_attack("light_kick", current_distance)
	## If farther than ATTACK_RANGE_KICK, don't attack
#



#extends CharacterBody2D
#
## NODES - Initialize in _ready() to avoid issues
#var enemy = null
#var animation = null
#var character_sprite = null
#var hurtboxes = []
#var hitboxes = []
#
## CONSTANTS
#var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
#const SPEED = 300
#const ATTACK_RANGE_PUNCH = 200
#const ATTACK_RANGE_KICK = 320
#const ATTACK_RANGE_LIMIT = 400
#const MOVE_THRESHOLD = 250
#
## STATE VARIABLES
#var is_jumping = false
#var is_hurt = false
#var is_attacking = false
#var is_defending = false
#var is_dashing = false
#
#var dash_speed = 300
#var dash_time = 0.5
#var dash_timer = 0.0
#var dash_direction = 0
#
#@onready var prev_distance_to_enemy = abs(enemy.position.x - position.x)
#
#
#func _ready():
	#print("Decision Tree Controller Initialized")
	#
	## Initialize nodes safely
	#initialize_nodes()
	#
	## Connect signals
	#connect_signals()
	#
	#print("DT Controller ready!")
#
#func initialize_nodes():
	## Get enemy reference
	#enemy = get_parent().get_node("PlayerCharacter1")
	#if not enemy:
		#print("ERROR: Could not find PlayerCharacter1!")
		## Try alternative path
		#enemy = get_node("../PlayerCharacter1")
		#if enemy:
			#print("Found enemy via alternative path")
	#
	## Get component nodes
	#animation = $AnimationPlayer
	#character_sprite = $AnimatedSprite2D
	#
	## Get hurtboxes and hitboxes
	#hurtboxes = [
		#$Hurtbox_LowerBody,
		#$Hurtbox_UpperBody
	#]
	#
	#hitboxes = [
		#$Hitbox_LeftFoot,
		#$Hitbox_LeftHand,
		#$Hitbox_RightFoot,
		#$Hitbox_RightHand
	#]
	#
	## Verify critical nodes
	#if not animation:
		#print("ERROR: No AnimationPlayer found!")
	#if not character_sprite:
		#print("ERROR: No AnimatedSprite2D found!")
#
#func connect_signals():
	## Connect animation finished signal
	#if animation and not animation.animation_finished.is_connected(_on_animation_finished):
		#animation.animation_finished.connect(_on_animation_finished)
		#print("Animation signals connected")
	#
	## Connect hurtbox signals
	#for hurtbox in hurtboxes:
		#if hurtbox and not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			#hurtbox.area_entered.connect(_on_hurtbox_area_entered)
			#print("Hurtbox signal connected: ", hurtbox.name)
#
#func _physics_process(delta):
	## Skip processing if critical nodes are missing
	#if not is_instance_valid(enemy) or not animation:
		#return
	#
	#update_facing_direction()
	#apply_gravity(delta)
	#
	#if is_on_floor() and not is_attacking:
				#if not is_jumping:
					#var direction = -1 if enemy.global_position.x > global_position.x else 1
	#
	## State machine - only act if not currently attacking or hurt
	#if not is_attacking and not is_hurt:
		## Check for attacks first
		#DTAttackSystem()
		## Only move if not attacking
		##if not is_attacking:
			##DTMovementSystem()
	#
	#move_and_slide()
#
#func apply_gravity(delta):
	#if not is_on_floor():
		#velocity.y += GRAVITY * delta
		#is_jumping = true
	#else:
		#velocity.y = 0
		#is_jumping = false
#
#func DTMovementSystem():
	#if not is_instance_valid(enemy):
		#return
	#
	#var distance = global_position.distance_to(enemy.global_position)
	#if is_on_floor():
				#if not is_jumping:
					#var direction = -1 if enemy.global_position.x > global_position.x else 1
					#
#
#func DTAttackSystem():
	#if not is_instance_valid(enemy):
		#return
	#
	#var current_distance = global_position.distance_to(enemy.global_position)
	#
	## Choose attack based on distance
	#if  current_distance <= ATTACK_RANGE_KICK:
		## Close range - use punch
		#start_attack("light_punch", current_distance)
	#elif current_distance >= ATTACK_RANGE_KICK and current_distance <= ATTACK_RANGE_LIMIT:
		## Medium range - use kick
		#start_attack("light_kick", current_distance)
	## If farther than ATTACK_RANGE_KICK, don't attack
#
#func start_attack(attack_animation, distance):
	#if not is_attacking:
		#print("Starting attack: ", attack_animation, " at distance: ", distance)
		#is_attacking = true
		#velocity.x = 0  # Stop movement during attack
		#play_animation(attack_animation)
#
#func play_animation(anim_name):
	#if animation and animation.has_animation(anim_name):
		#if animation.current_animation != anim_name:
			#animation.play(anim_name)
	#else:
		#print("WARNING: Animation not found: ", anim_name)
#
#func update_facing_direction():
	#if not is_instance_valid(enemy) or not character_sprite:
		#return
	#
	## Face the enemy
	#var face_right = enemy.position.x > position.x
	#character_sprite.flip_h = not face_right
	#
	## Update hitbox and hurtbox directions
	#var scale_x = 1 if face_right else -1
	#for hitbox in hitboxes:
		#if hitbox:
			#hitbox.scale.x = scale_x
	#for hurtbox in hurtboxes:
		#if hurtbox:
			#hurtbox.scale.x = scale_x
#
#func _on_animation_finished(anim_name):
	#print("Animation finished: ", anim_name)
	#
	#match anim_name:
		#"light_punch", "light_kick", "heavy_punch", "heavy_kick":
			#is_attacking = false
			#print("Attack completed, ready for next action")
		#"light_hurt", "heavy_hurt":
			#is_hurt = false
#
#func _on_hurtbox_area_entered(area: Area2D):
	#if area.is_in_group("Player1_Hitboxes"):
		#print("DT Character hit by: ", area.name)
		#is_hurt = true
		#is_attacking = false  # Interrupt attack if hit
		#play_animation("light_hurt")
		#
		#apply_damage(10)
		#
		## Apply knockback or other hit effects
		#var knockback_direction = -1 if enemy.position.x > position.x else 1
		#velocity.x = knockback_direction * 200
#
#func apply_damage(amount):
	#if get_parent().has_method("apply_damage_to_player2"):
		#get_parent().apply_damage_to_player2(amount)
		#
## Utility function to check if enemy is in attack range
#func is_enemy_in_attack_range():
	#if not is_instance_valid(enemy):
		#return false
	#var distance = global_position.distance_to(enemy.global_position)
	#return distance <= ATTACK_RANGE_KICK
#
## Function to handle KO state
#func KO():
	#print("DT Character KO!")
	#is_attacking = false
	#is_hurt = true
	#play_animation("knocked_down")
	## Disable movement and attacks
	#set_physics_process(false)
#
## Debug function to see current state
#func print_state():
	#print("State - Attacking: ", is_attacking, " | Hurt: ", is_hurt, " | Jumping: ", is_jumping)
	#if is_instance_valid(enemy):
		#var distance = global_position.distance_to(enemy.global_position)
		#print("Distance to enemy: ", distance)
#
#
#
#func MovementSystem(ai_move_direction: int, delta := 1.0 / 60.0):
	#if is_attacking || is_jumping || is_defending || is_hurt:
		#return
		#
	#var curr_distance_to_enemy = abs(enemy.position.x - position.x)
	#
	#if not is_dashing:
		#if ai_move_direction == 1:
			#is_dashing = true
			#dash_direction = 1
			#dash_timer = dash_time
		#elif ai_move_direction == -1:
			#is_dashing = true
			#dash_direction = -1
			#dash_timer = dash_time
		#
	#if is_dashing:
		#velocity.x = dash_direction * dash_speed
		#dash_timer -= delta
		#if dash_timer <= 0:
			#is_dashing = false
			#velocity.x = 0
			#
	## Movement animations
	#if velocity.x != 0:
		#if curr_distance_to_enemy < prev_distance_to_enemy:
			#animation.play("move_forward")
		#elif curr_distance_to_enemy > prev_distance_to_enemy:
			#animation.play("move_backward")
	#
	#prev_distance_to_enemy = curr_distance_to_enemy
