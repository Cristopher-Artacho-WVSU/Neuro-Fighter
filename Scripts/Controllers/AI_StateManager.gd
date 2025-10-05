# res://Scripts/Controllers/AI_StateManager.gd
extends Node

var saved_states = []  # Array of saved states: { "label": String, "timestamp": String, "rules": Array }

const SAVE_FILE_PATH = "user://ai_saved_states.json"

func _ready():
	load_saved_states()

func save_state(label: String, rules: Array, metadata: Dictionary = {}):
	var timestamp = Time.get_datetime_string_from_system()
	var state = {
		"label": label,
		"timestamp": timestamp,
		"rules": rules,
		"metadata": metadata  # Add performance metrics, fitness, etc.
	}
	
	# Check if label already exists, then update, else add
	var index = -1
	for i in range(saved_states.size()):
		if saved_states[i]["label"] == label:
			index = i
			break
	
	if index != -1:
		saved_states[index] = state
	else:
		saved_states.append(state)
	
	save_to_file()
	print("AI State Saved: ", label)

func load_state(label: String) -> Array:
	for state in saved_states:
		if state["label"] == label:
			print("AI State Loaded: ", label)
			return state["rules"]
	print("AI State Not Found: ", label)
	return []

func get_saved_state_labels() -> Array:
	var labels = []
	for state in saved_states:
		labels.append(state["label"])
	return labels

func get_state_metadata(label: String) -> Dictionary:
	for state in saved_states:
		if state["label"] == label:
			return state.get("metadata", {})
	return {}

func save_to_file():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(saved_states))
		file.close()
		print("AI states saved to file")
	else:
		print("Error saving AI states to file")

func load_saved_states():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data is Array:
				saved_states = data
				print("Loaded ", saved_states.size(), " AI states")
			file.close()
	else:
		print("No saved AI states file found")

# Debug function to print all saved states
func debug_print_states():
	print("=== AI SAVED STATES ===")
	for state in saved_states:
		print("Label: ", state["label"])
		print("Timestamp: ", state["timestamp"])
		print("Rules Count: ", state["rules"].size())
		print("Metadata: ", state.get("metadata", {}))
		print("---")
