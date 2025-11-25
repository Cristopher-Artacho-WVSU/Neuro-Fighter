# res://Scripts/Levels/SimulationV2.gd
extends Node2D

#ONREADY NODE VARIABLES
@onready var timer = $MainUI/Timer
@onready var player1HP = $MainUI/Player1_HPBar
@onready var player2HP = $MainUI/Player2_HPBar
@onready var timerLabel = $MainUI/Timer/TimerLabel
@onready var player2 = $NPCCharacter1
@onready var player1 = $PlayerCharacter1
@onready var pause_menu = $PauseMenu
@onready var chart_panel = $RealTimeChartPanel
@onready var chart_panel_p2 = $RealTimeChartPanel2

@onready var match_count_display = $MainUI/MatchCountDisplay
@onready var player1_round_wins_label = $MainUI/Player1RoundWins
@onready var player2_round_wins_label = $MainUI/Player2RoundWins
#OTHER VARIABLES
var totalTimerAmount = 99
var timer_running := true
var max_hp = 100
var P2_CurrentHP = 100
var P1_CurrentHP = 100

# VARIABLES TO TRACK GAME STATE
var game_ended = false
#var end_times = 0

var match_winner: String = ""
var showing_match_result: bool = false
var player1_initial_position: Vector2
var player2_initial_position: Vector2
var round_result_label: Label
var is_saving: bool = false

func _ready():
	# ABLE TO LISTEN TO THE INPUT EVENTS EVEN WHEN THE GAME IS PAUSED
	#process_mode = Node.PROCESS_MODE_ALWAYS
	
	player1_initial_position = player1.position
	player2_initial_position = player2.position
	
	timerLabel.text = str(int(totalTimerAmount))
	timer.start()
	init_HPBar()
	setup_controllers()
	
	setup_chart_panel()
	setup_player2_chart_panel()
	
	# Connect pause menu signals
	if pause_menu:
		pause_menu.connect("resume_game", _on_resume_game)
		pause_menu.connect("save_state", _on_save_state)
		pause_menu.connect("quit_to_menu", _on_quit_to_menu)
	
	initialize_match_count_display()

func _input(event):
	if event.is_action_pressed("close"):  # ESC key
		print("ESC pressed in SimulationV2 - Game Paused: ", Global.game_paused)
		toggle_pause_menu()
		
	# ADD CHART TOGGLE KEY (C key)
	if event.is_action_pressed("ui_accept"):  # Using Enter key for charts
		toggle_chart_panel()

func toggle_pause_menu():
	if not pause_menu:
		print("Pause menu not found!")
		return
	
	if pause_menu.visible:
		hide_pause_menu()
	else:
		show_pause_menu()

func show_pause_menu():
	if pause_menu:
		pause_menu.show()
		Global.set_pause(true)

func hide_pause_menu():
	if pause_menu:
		pause_menu.hide()
		Global.set_pause(false)

func toggle_chart_panel():
	if chart_panel and chart_panel.has_method("toggle_visibility"):
		chart_panel.toggle_visibility()
	
	# Toggle player 2 chart if it exists and is visible
	if chart_panel_p2 and chart_panel_p2.visible and chart_panel_p2.has_method("toggle_visibility"):
		chart_panel_p2.toggle_visibility()

func _on_resume_game():
	hide_pause_menu()

func _on_save_state():
	save_current_ds_state("manual_save")

func _on_quit_to_menu():
	Global.set_pause(false)
	get_tree().change_scene_to_file("res://Levels/main_menu.tscn")
	print("DEBUG: QUIT TO MAIN MENU IS CLICKED")

func setup_controllers():
	match Global.player1_controller:
		"Human":
			player1.set_script(load("res://Scripts/Controllers/PlayerCharacter1/PlayerCharacter1_Controller.gd"))
			player1._ready()
			player1.set_physics_process(true)
		"DecisionTree":
			player1.set_script(load("res://Scripts/Controllers/NPCCharacter1/DTCharacter1.gd"))
			player1._ready()
			player1.set_physics_process(true)
		"DynamicScripting":
			player1.set_script(load("res://Scripts/Controllers/DSCharacter1/DSCharacter1_Controller.gd"))
			player1._ready()
			player1.set_physics_process(true)
		"NDS":
			player1.set_script(load("res://Scripts/Controllers/NDSCharacter1/NDSCharacter1_Controller.gd"))
			player1._ready()
			player1.set_physics_process(true)
		"FSM":
			player1.set_script(load("res://Scripts/Controllers/FSMCharacter1/FSMCharacter1_Controller.gd"))
			player1._ready()
			player1.set_physics_process(true)
	
	# Set up player 2 controller
	match Global.player2_controller:
		"Human":
			player2.set_script(load("res://Scripts/Controllers/PlayerCharacter1/PlayerCharacter1_Controller.gd"))
			player2._ready()
			player2.set_physics_process(true)
		"DecisionTree":
			player2.set_script(load("res://Scripts/Controllers/NPCCharacter1/DTCharacter1.gd"))
			player2._ready()
			player2.set_physics_process(true)
		"DynamicScripting":
			player2.set_script(load("res://Scripts/Controllers/DSCharacter1/DSCharacter1_Controller.gd"))
			player2._ready()
			player2.set_physics_process(true)
		"NDS":
			player2.set_script(load("res://Scripts/Controllers/NDSCharacter1/NDSCharacter1_Controller.gd"))
			player2._ready()
			player2.set_physics_process(true)
		"FSM":
			player2.set_script(load("res://Scripts/Controllers/FSMCharacter1/FSMCharacter1_Controller.gd"))
			player2._ready()
			player2.set_physics_process(true)
			
func setup_chart_panel():
	if chart_panel:
		var show_chart = Global.player1_controller == "DynamicScripting" or Global.player1_controller == "NDS"
		chart_panel.visible = show_chart
		
		if show_chart:
			chart_panel.set_player_reference(player1)
		
		# Set chart panel reference in player 1 if it's DS or NDS
		if player1.has_method("set_chart_panel"):
			player1.set_chart_panel(chart_panel)

func setup_player2_chart_panel():
	if chart_panel_p2:
		var show_p2_chart = Global.player2_controller == "DynamicScripting" or Global.player2_controller == "NDS"
		chart_panel_p2.visible = show_p2_chart
		
		if show_p2_chart:
			chart_panel_p2.set_player_reference(player2)
			
		# Set chart panel reference in player 2 if it's DS/NDS
		if player2.has_method("set_chart_panel"):
			player2.set_chart_panel(chart_panel_p2)

func _physics_process(delta):
	if Global.game_paused:
		return
		
	monitorHP(delta)
	
	if timer_running:
		totalTimerAmount -= delta
		if totalTimerAmount <= 0:
			timer_running = false
			game_over()
	
	timerLabel.text = str(int(totalTimerAmount))

func init_HPBar():
	player1HP.max_value = max_hp
	player2HP.max_value = max_hp

func apply_damage_to_player2(amount):
	P2_CurrentHP = max(0, P2_CurrentHP - amount)
	player2HP.value = P2_CurrentHP
	print("Player 2 HP:", P2_CurrentHP)
		
func apply_damage_to_player1(amount):
	P1_CurrentHP = max(0, P1_CurrentHP - amount)
	player1HP.value = P1_CurrentHP
	print("Player 1 HP:", P1_CurrentHP)

func initialize_match_count_display():
	# Show current match info
	if match_count_display:
		match_count_display.text = "Match %d/%d" % [Global.current_match, Global.match_count]
	
	# Initialize round wins display
	if player1_round_wins_label:
		player1_round_wins_label.text = "Rounds: 0"
	if player2_round_wins_label:
		player2_round_wins_label.text = "Rounds: 0"

func update_match_count_display():
	if match_count_display:
		match_count_display.text = "Match %d/%d" % [Global.current_match, Global.match_count]

func update_round_wins_display():
	if player1_round_wins_label:
		player1_round_wins_label.text = "Rounds: %d" % Global.player1_round_wins
	if player2_round_wins_label:
		player2_round_wins_label.text = "Rounds: %d" % Global.player2_round_wins

func update_all_displays():
	update_match_count_display()
	update_round_wins_display()

func auto_save_ds_states():
	# Auto-save DS/NDS AI states when game ends
	if player1.has_method("save_current_rules") and (Global.player1_controller == "DynamicScripting" or Global.player1_controller == "NDS"):
		var performance = 0.5
		if player1.has_method("calculateFitness"):
			performance = player1.calculateFitness()
		Global.auto_save_ds_state(player1.rules, performance, Global.player1_controller)
	
	if player2.has_method("save_current_rules") and (Global.player2_controller == "DynamicScripting" or Global.player2_controller == "NDS"):
		var performance = 0.5
		if player2.has_method("calculateFitness"):
			performance = player2.calculateFitness()
		Global.auto_save_ds_state(player2.rules, performance, Global.player2_controller)

func save_current_ds_state(label_suffix: String):
	if is_saving:
		print("Save already in progress, skipping duplicate save")
		return
	
	is_saving = true
	
	var timestamp = Time.get_unix_time_from_system()
	var state_name = "manual_%s_%d" % [label_suffix, timestamp]
	
	print("Starting manual save: ", state_name)
	
	# Player 1 save
	if player1.has_method("save_current_rules") and (Global.player1_controller == "DynamicScripting" or Global.player1_controller == "NDS"):
		var performance = 0.5
		if player1.has_method("calculateFitness"):
			performance = player1.calculateFitness()
		
		print("Saving Player 1 %s state..." % Global.player1_controller)
		player1.save_current_rules(state_name + "_P1", {
			"performance": performance,
			"type": Global.player1_controller,
			"description": "Manual save - " + label_suffix,
			"is_autosave": false
		})
	
	# Player 2 save
	if player2.has_method("save_current_rules") and (Global.player2_controller == "DynamicScripting" or Global.player2_controller == "NDS"):
		var performance = 0.5
		if player2.has_method("calculateFitness"):
			performance = player2.calculateFitness()
		
		print("Saving Player 2 %s state..." % Global.player2_controller)
		player2.save_current_rules(state_name + "_P2", {
			"performance": performance,
			"type": Global.player2_controller,
			"description": "Manual save - " + label_suffix,
			"is_autosave": false
		})
	
	print("Manual save completed: ", state_name)
	is_saving = false

func handle_match_result(winner: String):
	if showing_match_result:
		return
		
	showing_match_result = true
	match_winner = winner
	
	# Record the win
	Global.record_win(winner)
	Global.increment_match()
	
	# Auto-save DS states
	auto_save_ds_states()
	update_all_displays()
	
	# Check if the series is complete
	if Global.is_match_series_complete():
		show_series_result()
	else:
		show_match_result()

func show_match_result():
	var winner_text = "Player 1" if match_winner == "player1" else "Player 2"
	print(winner_text + " wins match " + str(Global.current_match) + " of " + str(Global.match_count))
	
	# Update UI or show match result (you can add a proper UI element for this)
	if timerLabel:
		timerLabel.text = winner_text + " wins!"
	
	# Wait and then proceed to next match or end series
	var tree = get_tree()
	await tree.create_timer(3.0).timeout
	
	if not Global.is_match_series_complete():
		# Start next match
		Global.increment_match()
		reset_for_next_match()
	else:
		show_series_result()
		
func show_series_result():
	var series_winner = Global.get_series_winner()
	var winner_text = "Player 1" if series_winner == "player1" else "Player 2"
	
	print("=== SERIES COMPLETE ===")
	print(winner_text + " wins the series!")
	print("Final Score - P1: " + str(Global.player1_round_wins) + " | P2: " + str(Global.player2_round_wins))
	
	# Update UI
	if timerLabel:
		timerLabel.text = winner_text + " wins series!"
	
	# Wait and return to main menu
	var tree = get_tree()
	await tree.create_timer(3.0).timeout
	tree.change_scene_to_file("res://Levels/main_menu.tscn")

func reset_players():
	# Reset player 1 to their initial position
	player1.position = player1_initial_position
	player1.velocity = Vector2.ZERO
	
	# Reset player 2 to their initial position  
	player2.position = player2_initial_position
	player2.velocity = Vector2.ZERO
	
	# Reset character states
	if player1.has_method("reset_state"):
		player1.reset_state()
	else:
		# Fallback reset for players without reset_state method
		reset_player_fallback(player1)
	
	if player2.has_method("reset_state"):
		player2.reset_state()
	else:
		# Fallback reset for players without reset_state method
		reset_player_fallback(player2)

func reset_player_fallback(player: CharacterBody2D):
	if player.has_method("KO"):
		# Force stop KO animation and reset to idle
		var animation = player.get_node("AnimationPlayer")
		if animation:
			animation.play("idle")
	
	# Reset common state variables if they exist
	if "is_attacking" in player:
		player.is_attacking = false
	if "is_defending" in player:
		player.is_defending = false
	if "is_hurt" in player:
		player.is_hurt = false
	if "is_dashing" in player:
		player.is_dashing = false
	if "is_jumping" in player:
		player.is_jumping = false
	if "is_crouching" in player:
		player.is_crouching = false

# Update the reset_for_next_match function to also reset facing direction
func reset_for_next_match():
	print("Starting match " + str(Global.current_match) + " of " + str(Global.match_count))
	
	# Reset game state
	game_ended = false
	showing_match_result = false
	
	# Reset HP
	P1_CurrentHP = max_hp
	P2_CurrentHP = max_hp
	
	# Reset timer
	totalTimerAmount = 99
	timer_running = true
	timer.start()
	
	# Reset player positions and states
	reset_players()
	
	# Update UI
	timerLabel.text = str(int(totalTimerAmount))
	player1HP.value = P1_CurrentHP
	player2HP.value = P2_CurrentHP
	
	# Ensure players face each other initially
	if player1 and player2:
		update_player_facing_directions()

func update_player_facing_directions():
	# Player 1 should face right (towards player 2)
	if player1.position.x < player2.position.x:
		set_player_facing_direction(player1, false)  # Face right
		set_player_facing_direction(player2, true)   # Face left
	else:
		set_player_facing_direction(player1, true)   # Face left
		set_player_facing_direction(player2, false)  # Face right
func set_player_facing_direction(player: CharacterBody2D, flip_h: bool):
	var characterSprite = player.get_node("AnimatedSprite2D")
	if characterSprite:
		characterSprite.flip_h = flip_h
	
	# Update hitboxes and hurtboxes if they exist
	var hitboxGroup = [
		player.get_node_or_null("Hitbox_LeftFoot"),
		player.get_node_or_null("Hitbox_LeftHand"), 
		player.get_node_or_null("Hitbox_RightFoot"),
		player.get_node_or_null("Hitbox_RightHand")
	]
	
	var hurtboxGroup = [
		player.get_node_or_null("Hurtbox_LowerBody"),
		player.get_node_or_null("Hurtbox_UpperBody")
	]
	
	var scale_x = -1 if flip_h else 1
	
	for hitbox in hitboxGroup:
		if hitbox:
			hitbox.scale.x = scale_x
			
	for hurtbox in hurtboxGroup:
		if hurtbox:
			hurtbox.scale.x = scale_x

func game_over():
	if game_ended:
		return
		
	game_ended = true
	
	# Determine winner
	var winner = ""
	if P1_CurrentHP <= 0 and P2_CurrentHP > 0:
		winner = "player2"
	elif P2_CurrentHP <= 0 and P1_CurrentHP > 0:
		winner = "player1"
	elif P1_CurrentHP > P2_CurrentHP:  # Time out - higher HP wins
		winner = "player1"
	elif P2_CurrentHP > P1_CurrentHP:
		winner = "player2"
	else:  # Draw - random winner or handle as needed
		winner = "player1" if randf() > 0.5 else "player2"
	
	handle_match_result(winner)

func monitorHP(delta):
	player1HP.max_value = max_hp
	player2HP.max_value = max_hp
	player1HP.value = P1_CurrentHP
	player2HP.value = P2_CurrentHP
	
	if (player2HP.value <= 0 or player1HP.value <= 0) and not game_ended and not showing_match_result:
		game_over()
