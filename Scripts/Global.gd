# res://Scripts/Global.gd
extends Node

# Player controller types
var player1_controller = "Human"
var player2_controller = "DecisionTree"

# AI State references
var player1_saved_state_name = "" 
var player2_saved_state_name = "" 

# Current selected AI states
var player1_ai_state = null
var player2_ai_state = null

# Debug settings
var debug_mode = true
var debug_log_level = 1  # 0: None, 1: Basic, 2: Detailed, 3: Verbose

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

# Pause state
var game_paused = false

func _ready():
	if debug_mode:
		add_log_entry("Global.gd initialized - Debug Mode: ON", 1)

func set_controllers(p1_type: String, p2_type: String, p1_state = null, p2_state = null, p1_state_name: String = "", p2_state_name: String = ""):
	player1_controller = p1_type
	player2_controller = p2_type
	player1_ai_state = p1_state
	player2_ai_state = p2_state
	player1_saved_state_name = p1_state_name
	player2_saved_state_name = p2_state_name
	
	add_log_entry("Controllers set: P1=%s, P2=%s" % [p1_type, p2_type], 1)
	if p1_state:
		add_log_entry("P1 AI State: %s" % p1_state.get("description", "Custom"), 2)
	if p2_state:
		add_log_entry("P2 AI State: %s" % p2_state.get("description", "Custom"), 2)
	if p1_state_name:
		add_log_entry("P1 Saved State Name: %s" % p1_state_name, 2)
	if p2_state_name:
		add_log_entry("P2 Saved State Name: %s" % p2_state_name, 2)

# AI State Management through AI_StateManager
func save_ai_state(state_name: String, controller_type: String, rules: Array, performance: float, description: String = ""):
	var ai_state_manager = get_node_or_null("/root/AI_StateManager")
	if not ai_state_manager:
		add_log_entry("ERROR: AI_StateManager not found", 0)
		return false
	
	var metadata = {
		"type": controller_type,
		"performance": performance,
		"description": description,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	var success = ai_state_manager.save_state(state_name, rules, metadata)
	if success:
		add_log_entry("AI State Saved: " + state_name, 1)
	else:
		add_log_entry("Failed to save AI State: " + state_name, 0)
	return success

func load_ai_state(state_name: String) -> Dictionary:
	var ai_state_manager = get_node_or_null("/root/AI_StateManager")
	if not ai_state_manager:
		add_log_entry("ERROR: AI_StateManager not found", 0)
		return {}
	
	var rules = ai_state_manager.load_state(state_name)
	var metadata = ai_state_manager.get_state_metadata(state_name)
	
	if rules.size() > 0:
		var state_data = {
			"type": metadata.get("type", ""),
			"weights": extract_weights_from_rules(rules),
			"performance": metadata.get("performance", 0.5),
			"description": metadata.get("description", ""),
			"timestamp": metadata.get("timestamp", ""),
			"rules": rules
		}
		add_log_entry("AI State loaded: " + state_name, 1)
		return state_data
	else:
		add_log_entry("AI State not found: " + state_name, 2)
		return {}

func extract_weights_from_rules(rules: Array) -> Dictionary:
	var weights = {}
	for rule in rules:
		if rule.has("ruleID") and rule.has("weight"):
			weights[str(rule["ruleID"])] = rule["weight"]
	return weights

func get_saved_state_names() -> Array:
	var ai_state_manager = get_node_or_null("/root/AI_StateManager")
	if ai_state_manager:
		return ai_state_manager.get_saved_state_labels()
	return []

func get_saved_states_for_algorithm(algorithm_type: String) -> Array:
	var ai_state_manager = get_node_or_null("/root/AI_StateManager")
	if ai_state_manager:
		return ai_state_manager.get_saved_states_for_algorithm(algorithm_type)
	return []

func auto_save_ds_state(rules: Array, performance: float = 0.5) -> String:
	var ai_state_manager = get_node_or_null("/root/AI_StateManager")
	if ai_state_manager:
		var label = ai_state_manager.auto_save_state(rules, "DynamicScripting", performance)
		add_log_entry("Auto-saved DS AI state: " + label, 1)
		return label
	return ""

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

# Pause functionality
func toggle_pause():
	game_paused = !game_paused
	get_tree().paused = game_paused
	add_log_entry("Game " + ("paused" if game_paused else "unpaused"), 1)

func set_pause(paused: bool):
	game_paused = paused
	get_tree().paused = game_paused
	add_log_entry("Game " + ("paused" if game_paused else "unpaused"), 1)
