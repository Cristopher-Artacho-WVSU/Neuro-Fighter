# res://Scripts/Controllers/AI_StateManager.gd
extends Node

var saved_states_ds = []  # Dynamic Scripting states
var saved_states_nds = []  # Array of saved states: { "label": String, "timestamp": String, "rules": Array, "metadata": Dictionary }

const DS_SAVE_FILE_PATH = "res://ai_saved_states_ds.json"
const NDS_SAVE_FILE_PATH = "res://ai_saved_states_nds.json"
const AUTOSAVE_PREFIX = "autosave_"

func _ready():
	load_all_saved_states()

func save_state(label: String, rules: Array, metadata: Dictionary = {}):
	var algorithm_type = metadata.get("type", "DynamicScripting")
	var state_array = get_state_array(algorithm_type)
	var file_path = get_save_file_path(algorithm_type)
	
	var timestamp = Time.get_datetime_string_from_system()
	var state = {
		"label": label,
		"timestamp": timestamp,
		"rules": rules,
		"metadata": metadata
	}
	
	# Check if label already exists, then update, else add
	var index = -1
	for i in range(state_array.size()):
		if state_array[i]["label"] == label:
			index = i
			break
	
	if index != -1:
		state_array[index] = state
	else:
		state_array.append(state)
	
	save_to_file(algorithm_type, file_path, state_array)
	print("AI State Saved [%s]: %s" % [algorithm_type, label])
	return true

func load_state(label: String, algorithm_type: String = "DynamicScripting") -> Array:
	var state_array = get_state_array(algorithm_type)
	
	for state in state_array:
		if state["label"] == label:
			print("AI State Loaded [%s]: %s" % [algorithm_type, label])
			return state["rules"]
	
	print("AI State Not Found [%s]: %s" % [algorithm_type, label])
	return []

func get_saved_state_labels(algorithm_type: String = "DynamicScripting") -> Array:
	var state_array = get_state_array(algorithm_type)
	var labels = []
	for state in state_array:
		labels.append(state["label"])
	return labels

func get_state_metadata(label: String, algorithm_type: String = "DynamicScripting") -> Dictionary:
	var state_array = get_state_array(algorithm_type)
	for state in state_array:
		if state["label"] == label:
			return state.get("metadata", {})
	return {}

func get_saved_states_for_algorithm(algorithm_type: String) -> Array:
	return get_state_array(algorithm_type).duplicate()

func save_to_file(algorithm_type: String, file_path: String, state_array: Array):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state_array))
		file.close()
		print("%s states saved to file: %s" % [algorithm_type, file_path])
		return true
	else:
		print("Error saving %s states to file: %s" % [algorithm_type, file_path])
		return false

#func load_saved_states():
	#if FileAccess.file_exists(SAVE_FILE_PATH):
		#var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		#if file:
			#var data = JSON.parse_string(file.get_as_text())
			#if data is Array:
				#saved_states = data
				#print("Loaded ", saved_states.size(), " AI states from file")
			#file.close()
	#else:
		#print("No saved AI states file found, starting with empty states")

func create_autosave_name(algorithm_type: String) -> String:
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	return "autosave_%s_%s" % [algorithm_type.to_lower(), timestamp]

func auto_save_state(rules: Array, algorithm_type: String, performance: float = 0.5) -> String:
	var label = create_autosave_name(algorithm_type)
	var metadata = {
		"type": algorithm_type,
		"performance": performance,
		"description": "Auto-saved after match",
		"is_autosave": true
	}
	save_state(label, rules, metadata)
	return label

# Debug function to print all saved states
func debug_print_all_states():
	print("=== ALL SAVED AI STATES ===")
	print("DynamicScripting (%d states):" % saved_states_ds.size())
	for state in saved_states_ds:
		print("  - %s" % state["label"])
	
	print("NDS (%d states):" % saved_states_nds.size())
	for state in saved_states_nds:
		print("  - %s" % state["label"])
	
func get_save_file_path(algorithm_type: String) -> String:
	match algorithm_type:
		"DynamicScripting":
			return DS_SAVE_FILE_PATH
		"NDS":
			return NDS_SAVE_FILE_PATH
		_:
			return DS_SAVE_FILE_PATH  # Default

func get_state_array(algorithm_type: String) -> Array:
	match algorithm_type:
		"DynamicScripting":
			return saved_states_ds
		"NDS":
			return saved_states_nds
		_:
			return saved_states_ds  # Default
			
func load_all_saved_states():
	load_saved_states_for_type("DynamicScripting", DS_SAVE_FILE_PATH, saved_states_ds)
	load_saved_states_for_type("NDS", NDS_SAVE_FILE_PATH, saved_states_nds)

func load_saved_states_for_type(algorithm_type: String, file_path: String, state_array: Array):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data is Array:
				state_array.clear()
				state_array.append_array(data)
				print("Loaded %d %s states from file" % [state_array.size(), algorithm_type])
			file.close()
	else:
		print("No saved %s states file found, starting with empty states" % algorithm_type)
