# MainMenu.gd
extends Control

# Signals to communicate with the game scene
signal start_game(player1_type, player2_type)

# Player type constants
const HUMAN = "Human"
const DECISION_TREE = "DecisionTree"
const DYNAMIC_SCRIPTING = "DynamicScripting"
const NDS = "NDS"

# UI elements
@onready var player1_options = $MarginContainer/VBoxContainer/HBoxContainer/Player1Options
@onready var player2_options = $MarginContainer/VBoxContainer/HBoxContainer/Player2Options
@onready var start_button = $MarginContainer/VBoxContainer/StartButton
# Selected controller types
var player1_type = HUMAN
var player2_type = DECISION_TREE

func _ready():
	# Connect signals for player 1 options
	player1_options.get_node("HumanButton").connect("pressed", Callable(self, "_on_Player1_option_selected").bind(HUMAN))
	player1_options.get_node("NDSButton").connect("pressed", Callable(self, "_on_Player1_option_selected").bind(NDS))
	
	# Connect signals for player 2 options
	player2_options.get_node("DecisionTreeButton").connect("pressed", Callable(self, "_on_Player2_option_selected").bind(DECISION_TREE))
	player2_options.get_node("DynamicScriptingButton").connect("pressed", Callable(self, "_on_Player2_option_selected").bind(DYNAMIC_SCRIPTING))
	player2_options.get_node("NDSButton").connect("pressed", Callable(self, "_on_Player2_option_selected").bind(NDS))
	
	# Connect start button
	start_button.connect("pressed", Callable(self, "_on_StartButton_pressed"))
	
	# Set initial selection visuals
	update_selection_visuals()

func _on_Player1_option_selected(type):
	player1_type = type
	update_selection_visuals()

func _on_Player2_option_selected(type):
	player2_type = type
	update_selection_visuals()

func update_selection_visuals():
	# Update player 1 buttons
	for button in player1_options.get_children():
		if button is Button:
			button.disabled = (button.name.replace("Button", "") == player1_type)
	
	# Update player 2 buttons
	for button in player2_options.get_children():
		if button is Button:
			button.disabled = (button.name.replace("Button", "") == player2_type)

func _on_StartButton_pressed():
	Global.set_controllers(player1_type, player2_type)
	emit_signal("start_game", player1_type, player2_type)
	get_tree().change_scene_to_file("res://Levels/Simulationv2.0.tscn")
