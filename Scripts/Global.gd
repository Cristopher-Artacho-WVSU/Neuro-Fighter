# res://Scripts/Global.gd
extends Node

# Player controller types
var player1_controller = "Human"
var player2_controller = "DecisionTree"

# AI State references
var player1_saved_state = ""
var player2_saved_state = ""

# Debug settings
var debug_mode = true
var debug_log_level = 1  # 0: None, 1: Basic, 2: Detailed, 3: Verbose

# AI Difficulty and Saved States
var saved_ai_states = {
	"Level 1": {
		"type": "DynamicScripting", 
		"weights": {}, 
		"performance": 0.65,
		"description": "Basic trained AI"
	},
	"Level 2": {
		"type": "DynamicScripting", 
		"weights": {}, 
		"performance": 0.78,
		"description": "Intermediate trained AI"
	},
	"Level 3": {
		"type": "DynamicScripting", 
		"weights": {}, 
		"performance": 0.85,
		"description": "Advanced trained AI"
	},
	"Boss Level": {
		"type": "DynamicScripting", 
		"weights": {}, 
		"performance": 0.92,
		"description": "Expert level AI"
	},
	"20 Min Trained": {
		"type": "DynamicScripting", 
		"weights": {}, 
		"performance": 0.75,
		"description": "Quick training session"
	}
}

# Current selected AI states
var player1_ai_state = null
var player2_ai_state = null

# Training metadata
var current_training_labels = {
	"player1": "Custom Training",
	"player2": "Custom Training"
}

# Real-time performance data for preview charts
var ai_performance_data = {
	"DecisionTree": [],
	"DynamicScripting": [],
	"NDS": []
}

# NDS AI Configuration
var nds_ai_parameters = {
	"learning_rate": 0.1,
	"exploration_rate": 0.3,
	"network_layers": [12, 8, 4]
}

# Debug logging
var debug_log_entries = []

func _ready():
	# Load saved states from file if exists
	load_saved_states()
	if debug_mode:
		add_log_entry("Global.gd initialized - Debug Mode: ON")

func set_controllers(p1_type: String, p2_type: String, p1_state = null, p2_state = null):
	player1_controller = p1_type
	player2_controller = p2_type
	player1_ai_state = p1_state
	player2_ai_state = p2_state
	
	add_log_entry("Controllers set: P1=%s, P2=%s" % [p1_type, p2_type], 1)
	if p1_state:
		add_log_entry("P1 AI State: %s" % p1_state.get("description", "Custom"), 2)
	if p2_state:
		add_log_entry("P2 AI State: %s" % p2_state.get("description", "Custom"), 2)

func save_ai_state(state_name: String, controller_type: String, weights: Dictionary, performance: float, description: String = ""):
	saved_ai_states[state_name] = {
		"type": controller_type,
		"weights": weights.duplicate(true),
		"performance": performance,
		"description": description,
		"timestamp": Time.get_datetime_string_from_system()
	}
	save_saved_states()
	add_log_entry("AI State Saved: " + state_name, 1)

func load_ai_state(state_name: String) -> Dictionary:
	var state = saved_ai_states.get(state_name, {}).duplicate(true)
	if state.is_empty():
		add_log_entry("AI State not found: " + state_name, 2)
	else:
		add_log_entry("AI State loaded: " + state_name, 2)
	return state

func get_saved_state_names() -> Array:
	return saved_ai_states.keys()

func save_saved_states():
	var save_game = FileAccess.open("user://saved_ai_states.save", FileAccess.WRITE)
	if save_game:
		save_game.store_var(saved_ai_states)
		save_game.close()
		add_log_entry("AI states saved to file", 2)
	else:
		add_log_entry("Error saving AI states to file", 0)

func load_saved_states():
	if FileAccess.file_exists("user://saved_ai_states.save"):
		var save_game = FileAccess.open("user://saved_ai_states.save", FileAccess.READ)
		if save_game:
			var loaded_data = save_game.get_var()
			if loaded_data:
				saved_ai_states = loaded_data
				add_log_entry("Loaded " + str(saved_ai_states.size()) + " AI states from file", 1)
			save_game.close()

func add_performance_data(ai_type: String, performance_metric: float):
	if not ai_performance_data.has(ai_type):
		ai_performance_data[ai_type] = []
	
	ai_performance_data[ai_type].append(performance_metric)
	
	# Keep only last 50 data points for performance
	if ai_performance_data[ai_type].size() > 50:
		ai_performance_data[ai_type].pop_front()
	
	add_log_entry("Performance data added for " + ai_type + ": " + str(performance_metric), 3)

func get_performance_data(ai_type: String) -> Array:
	return ai_performance_data.get(ai_type, [])

func set_nds_ai_parameter(param: String, value):
	nds_ai_parameters[param] = value
	add_log_entry("NDS parameter set: " + param + " = " + str(value), 2)

func get_nds_ai_parameters() -> Dictionary:
	return nds_ai_parameters.duplicate()

# Debug logging system
func add_log_entry(message: String, level: int = 1):
	if not debug_mode or level > debug_log_level:
		return
	
	var timestamp = Time.get_time_string_from_system()
	var log_entry = "[%s] %s" % [timestamp, message]
	debug_log_entries.append(log_entry)
	
	# Print to console based on log level
	match level:
		0: print("ERROR: " + message)
		1: print("INFO: " + message)
		2: print("DEBUG: " + message)
		3: print("VERBOSE: " + message)
	
	# Keep log manageable
	if debug_log_entries.size() > 100:
		debug_log_entries.pop_front()

func get_debug_log() -> Array:
	return debug_log_entries.duplicate()

func clear_debug_log():
	debug_log_entries.clear()
	add_log_entry("Debug log cleared", 1)

# Performance metrics
func calculate_ai_performance(ai_type: String, matches_won: int, total_matches: int) -> float:
	if total_matches == 0:
		return 0.5  # Default performance
	
	var win_rate = float(matches_won) / float(total_matches)
	add_log_entry("AI Performance Calculated: " + ai_type + " Win Rate: " + str(win_rate), 2)
	return win_rate
