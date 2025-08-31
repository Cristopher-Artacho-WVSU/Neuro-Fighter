# Global.gd
extends Node

# Player controller types
var player1_controller = "Human"
var player2_controller = "DecisionTree"

# Function to set controllers from main menu
func set_controllers(p1_type, p2_type):
	player1_controller = p1_type
	player2_controller = p2_type
	print("Controllers set: P1=", p1_type, ", P2=", p2_type)
