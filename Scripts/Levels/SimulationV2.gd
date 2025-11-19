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

#OTHER VARIABLES
var totalTimerAmount = 99
var timer_running := true
var max_hp = 100
var P2_CurrentHP = 100
var P1_CurrentHP = 100

# VARIABLES TO TRACK GAME STATE
var game_ended = false
#var end_times = 0

func _ready():
	# ABLE TO LISTEN TO THE INPUT EVENTS EVEN WHEN THE GAME IS PAUSED
	#process_mode = Node.PROCESS_MODE_ALWAYS
	
	timerLabel.text = str(int(totalTimerAmount))
	timer.start()
	init_HPBar()
	setup_controllers()
	
	setup_chart_panel()
	
	# Connect pause menu signals
	if pause_menu:
		pause_menu.connect("resume_game", _on_resume_game)
		pause_menu.connect("save_state", _on_save_state)
		pause_menu.connect("quit_to_menu", _on_quit_to_menu)

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
		chart_panel.set_player_reference(player1)
		
		# Set chart panel reference in player 1 if it's DS
		if player1.has_method("set_chart_panel"):
			player1.set_chart_panel(chart_panel)

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
	
func monitorHP(delta):
	player1HP.max_value = max_hp
	player2HP.max_value = max_hp
	player1HP.value = P1_CurrentHP
	player2HP.value = P2_CurrentHP
	
	if player2HP.value <= 0 and not game_ended:
		print("Player 1 Wins")
		player2.KO()
		game_over()
	if player1HP.value <= 0 and not game_ended:
		print("Player 2 Wins")
		player1.KO()
		game_over()

func apply_damage_to_player2(amount):
	P2_CurrentHP = max(0, P2_CurrentHP - amount)
	player2HP.value = P2_CurrentHP
	print("Player 2 HP:", P2_CurrentHP)
		
func apply_damage_to_player1(amount):
	P1_CurrentHP = max(0, P1_CurrentHP - amount)
	player1HP.value = P1_CurrentHP
	print("Player 1 HP:", P1_CurrentHP)

func auto_save_ds_states():
	# Auto-save DS AI states when game ends
	if player1.has_method("save_current_rules") and Global.player1_controller == "DynamicScripting":
		var performance = 0.5
		if player1.has_method("calculateFitness"):
			performance = player1.calculateFitness()
		Global.auto_save_ds_state(player1.rules, performance)
	
	if player2.has_method("save_current_rules") and Global.player2_controller == "DynamicScripting":
		var performance = 0.5
		if player2.has_method("calculateFitness"):
			performance = player2.calculateFitness()
		Global.auto_save_ds_state(player2.rules, performance)

func save_current_ds_state(label_suffix: String):
	# Manual save of DS AI states
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var state_name = "manual_" + label_suffix + "_" + timestamp
	
	if player1.has_method("save_current_rules") and Global.player1_controller == "DynamicScripting":
		var performance = 0.5
		if player1.has_method("calculateFitness"):
			performance = player1.calculateFitness()
		player1.save_current_rules(state_name + "_P1", {"performance": performance})
	
	if player2.has_method("save_current_rules") and Global.player2_controller == "DynamicScripting":
		var performance = 0.5
		if player2.has_method("calculateFitness"):
			performance = player2.calculateFitness()
		player2.save_current_rules(state_name + "_P2", {"performance": performance})

func game_over():
	#player1.set_physics_process(false)
	#player2.set_physics_process(false)
	#player2.set_process(false)

	# ADD THESE CHECKS AT THE START OF THE FUNCTION
	if game_ended:
		return
		
	game_ended = true
	#end_times += 1
	#print("DEBUG: End: ", end_times, " times")
	auto_save_ds_states()
	
	var tree = get_tree()
	await tree.create_timer(2.1).timeout
	tree.change_scene_to_file("res://Levels/main_menu.tscn")
