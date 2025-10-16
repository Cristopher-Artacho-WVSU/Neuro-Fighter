# res://Scripts/UI/MainMenuEnhanced.gd
extends Control

# UI elements - Use @onready but with null checks
@onready var left_algorithm_panel = $MarginContainer/VBoxContainer/HBoxContainer/LeftPlayerPanel/AlgorithmPanel
@onready var right_algorithm_panel = $MarginContainer/VBoxContainer/HBoxContainer/RightPlayerPanel/AlgorithmPanel
@onready var left_load_panel = $MarginContainer/VBoxContainer/HBoxContainer/LeftPlayerPanel/LoadPanel/SavedStatesContainer
@onready var right_load_panel = $MarginContainer/VBoxContainer/HBoxContainer/RightPlayerPanel/LoadPanel/SavedStatesContainer
@onready var left_percentage_value = $MarginContainer/VBoxContainer/HBoxContainer/LeftPlayerPanel/PercentageDisplay/PercentageValue
@onready var right_percentage_value = $MarginContainer/VBoxContainer/HBoxContainer/RightPlayerPanel/PercentageDisplay/PercentageValue
@onready var nds_ai_input = $MarginContainer/VBoxContainer/HBoxContainer/NDSAIPanel/NDSInput
@onready var nds_ai_description = $MarginContainer/VBoxContainer/HBoxContainer/NDSAIPanel/NDSDescription
@onready var play_button = $MarginContainer/VBoxContainer/ButtonContainer/PlayButton
@onready var save_button = $MarginContainer/VBoxContainer/ButtonContainer/SaveButton
@onready var back_button = $MarginContainer/VBoxContainer/ButtonContainer/BackButton
@onready var performance_chart = $MarginContainer/VBoxContainer/PreviewPanel/PerformanceChart

# Debug panel elements - with safe access
@onready var debug_panel = $MarginContainer/VBoxContainer/DebugPanel
@onready var debug_toggle = $MarginContainer/VBoxContainer/DebugPanel/DebugToggleButton
@onready var debug_log_display = $MarginContainer/VBoxContainer/DebugPanel/DebugLog
@onready var clear_log_button = $MarginContainer/VBoxContainer/DebugPanel/HBoxContainer/ClearLogButton
@onready var export_log_button = $MarginContainer/VBoxContainer/DebugPanel/HBoxContainer/ExportLogButton

# State variables
var current_left_type = "Human"
var current_right_type = "DecisionTree"
var current_left_state = null
var current_right_state = null

# Colors for UI feedback
var selected_color = Color(0.2, 0.6, 1.0)
var normal_color = Color(0.3, 0.3, 0.3)

# Debug state
var debug_panel_visible = false

func _ready():
	print("Enhanced Main Menu Initialized")
	# Initialize with safe node checking
	if left_algorithm_panel and right_algorithm_panel:
		setup_algorithm_buttons()
	else:
		print("WARNING: Algorithm panels not found!")
	
	if left_load_panel and right_load_panel:
		setup_load_sections()
	else:
		print("WARNING: Load panels not found!")
		
	# Setup main buttons
	setup_main_buttons()
	# Setup NDS input signals
	setup_nds_input_signals()
	
	update_display()
	setup_nds_ai_section()
	setup_debug_panel() 

func setup_load_sections():
	# Clear existing buttons safely
	if left_load_panel:
		for child in left_load_panel.get_children():
			child.queue_free()
	
	if right_load_panel:
		for child in right_load_panel.get_children():
			child.queue_free()
	
	# Show/hide load panels based on algorithm type
	update_load_panel_visibility()
	
	# Create load buttons for saved states specific to each algorithm
	update_load_buttons()

func update_load_panel_visibility():
	if left_load_panel and left_load_panel.get_parent():
		left_load_panel.get_parent().visible = (current_left_type == "DynamicScripting" or current_left_type == "NDS")
	
	if right_load_panel and right_load_panel.get_parent():
		right_load_panel.get_parent().visible = (current_right_type == "DynamicScripting" or current_right_type == "NDS")

# Scan saved states from file and append as button
func update_load_buttons():
	# Get ALL saved states first
	var all_states = Global.get_saved_state_names()
	var ai_state_manager = get_node_or_null("/root/AI_StateManager")
	
	if not ai_state_manager:
		print("WARNING: AI_StateManager not found for loading states")
		return
	
	# Left side load buttons
	if left_load_panel and (current_left_type == "DynamicScripting" or current_left_type == "NDS"):
		for state_name in all_states:
			var metadata = ai_state_manager.get_state_metadata(state_name)
			var state_type = metadata.get("type", "")
			
			# Show state if it matches current algorithm OR if type is not specified (manual saves)
			if state_type == current_left_type or state_type == "":
				var left_button = Button.new()
				var performance = metadata.get("performance", 0.5) * 100
				var description = metadata.get("description", "No description")
				var is_autosave = metadata.get("is_autosave", false)
				
				# Format display text
				var display_text = state_name
				if is_autosave:
					display_text = "[AUTO] " + state_name.replace("autosave_", "")
				display_text += " - %d%%" % performance
				
				left_button.text = display_text
				if not left_button.is_connected("pressed", _on_left_load_pressed.bind(state_name)):
					left_button.connect("pressed", _on_left_load_pressed.bind(state_name))
				left_button.tooltip_text = description
				left_load_panel.add_child(left_button)
	
	# Right side load buttons
	if right_load_panel and (current_right_type == "DynamicScripting" or current_right_type == "NDS"):
		for state_name in all_states:
			var metadata = ai_state_manager.get_state_metadata(state_name)
			var state_type = metadata.get("type", "")
			
			# Show state if it matches current algorithm OR if type is not specified (manual saves)
			if state_type == current_right_type or state_type == "":
				var right_button = Button.new()
				var performance = metadata.get("performance", 0.5) * 100
				var description = metadata.get("description", "No description")
				var is_autosave = metadata.get("is_autosave", false)
				
				# Format display text
				var display_text = state_name
				if is_autosave:
					display_text = "[AUTO] " + state_name.replace("autosave_", "")
				display_text += " - %d%%" % performance
				
				right_button.text = display_text
				if not right_button.is_connected("pressed", _on_right_load_pressed.bind(state_name)):
					right_button.connect("pressed", _on_right_load_pressed.bind(state_name))
				right_button.tooltip_text = description
				right_load_panel.add_child(right_button)
				
	print("Load buttons updated. Left: %d, Right: %d" % [left_load_panel.get_child_count(), right_load_panel.get_child_count()])
	
func setup_main_buttons():
	if play_button:
		if not play_button.is_connected("pressed", _on_play_button_pressed):
			play_button.connect("pressed", _on_play_button_pressed)
		print("PlayButton connected")
	else:
		print("WARNING: PlayButton not found!")
	
	if save_button:
		if not save_button.is_connected("pressed", _on_save_button_pressed):
			save_button.connect("pressed", _on_save_button_pressed)
		print("SaveButton connected")
	else:
		print("WARNING: SaveButton not found!")
	
	if back_button:
		if not back_button.is_connected("pressed", _on_back_button_pressed):
			back_button.connect("pressed", _on_back_button_pressed)
		print("BackButton connected")
	else:
		print("WARNING: BackButton not found!")
		
func setup_nds_input_signals():
	if nds_ai_input:
		if not nds_ai_input.is_connected("text_changed", _on_nds_input_text_changed):
			nds_ai_input.connect("text_changed", _on_nds_input_text_changed)
		if not nds_ai_input.is_connected("text_submitted", _on_nds_input_text_submitted):
			nds_ai_input.connect("text_submitted", _on_nds_input_text_submitted)
		print("NDSInput signals connected")
	else:
		print("WARNING: NDSInput not found!")


func setup_algorithm_buttons():
	# Left side buttons
	var left_human = left_algorithm_panel.get_node_or_null("HumanButton")
	var left_dt = left_algorithm_panel.get_node_or_null("DecisionTreeButton")
	var left_ds = left_algorithm_panel.get_node_or_null("DynamicScriptingButton")
	var left_nds = left_algorithm_panel.get_node_or_null("NDSButton")
	
	if left_human: left_human.connect("pressed", _on_left_algorithm_selected.bind("Human"))
	if left_dt: left_dt.connect("pressed", _on_left_algorithm_selected.bind("DecisionTree"))
	if left_ds: left_ds.connect("pressed", _on_left_algorithm_selected.bind("DynamicScripting"))
	if left_nds: left_nds.connect("pressed", _on_left_algorithm_selected.bind("NDS"))
	
	# Right side buttons
	var right_human = right_algorithm_panel.get_node_or_null("HumanButton")
	var right_dt = right_algorithm_panel.get_node_or_null("DecisionTreeButton")
	var right_ds = right_algorithm_panel.get_node_or_null("DynamicScriptingButton")
	var right_nds = right_algorithm_panel.get_node_or_null("NDSButton")
	
	if right_human: right_human.connect("pressed", _on_right_algorithm_selected.bind("Human"))
	if right_dt: right_dt.connect("pressed", _on_right_algorithm_selected.bind("DecisionTree"))
	if right_ds: right_ds.connect("pressed", _on_right_algorithm_selected.bind("DynamicScripting"))
	if right_nds: right_nds.connect("pressed", _on_right_algorithm_selected.bind("NDS"))

func setup_nds_ai_section():
	if nds_ai_input:
		nds_ai_input.placeholder_text = "Enter NDS AI parameters..."
		nds_ai_input.text = "Learning Rate: 0.1, Exploration: 0.3"
	
	if nds_ai_description:
		nds_ai_description.text = "Configure Neuro-Dynamic System parameters"
		
func setup_debug_panel():
	if debug_panel and debug_toggle and debug_log_display:
		debug_panel.visible = false  # Hidden by default
		
		if not debug_toggle.is_connected("pressed", _on_debug_toggle_pressed):
			debug_toggle.connect("pressed", _on_debug_toggle_pressed)
		
		if clear_log_button and not clear_log_button.is_connected("pressed", _on_clear_log_pressed):
			clear_log_button.connect("pressed", _on_clear_log_pressed)
			
		if export_log_button and not export_log_button.is_connected("pressed", _on_export_log_pressed):
			export_log_button.connect("pressed", _on_export_log_pressed)
		
		update_debug_log()
		print("Debug panel setup complete")
	else:
		print("WARNING: Debug panel nodes not found - debug features disabled")

func _on_debug_toggle_pressed():
	if debug_panel:
		debug_panel_visible = not debug_panel_visible
		debug_panel.visible = debug_panel_visible
		if debug_panel_visible:
			update_debug_log()
			Global.add_log_entry("Debug panel opened", 2)
		else:
			Global.add_log_entry("Debug panel closed", 2)
			
func _on_clear_log_pressed():
	Global.clear_debug_log()
	update_debug_log()
	Global.add_log_entry("Debug log cleared", 1)
	
func _on_export_log_pressed():
	export_debug_log()
	
func export_debug_log():
	var log_entries = Global.get_debug_log()
	var file = FileAccess.open("res://debug_log.txt", FileAccess.WRITE)
	if file:
		for entry in log_entries:
			file.store_string(entry + "\n")
		file.close()
		Global.add_log_entry("Debug log exported to res://debug_log.txt", 1)
		print("Debug log exported")
	else:
		Global.add_log_entry("Failed to export debug log", 0)

func update_debug_log():
	if debug_log_display:
		var log_entries = Global.get_debug_log()
		var log_text = "=== DEBUG LOG ===\n"
		for entry in log_entries:
			log_text += entry + "\n"
		debug_log_display.text = log_text


func _on_left_algorithm_selected(algorithm):
	current_left_type = algorithm
	current_left_state = null  # Reset saved state when changing algorithm
	Global.add_log_entry("Left player algorithm changed to: " + algorithm, 2)
	update_display()
	update_button_styles()
	setup_load_sections()

func _on_right_algorithm_selected(algorithm):
	current_right_type = algorithm
	current_right_state = null  # Reset saved state when changing algorithm
	Global.add_log_entry("Right player algorithm changed to: " + algorithm, 2)
	update_display()
	update_button_styles()
	setup_load_sections()

func _on_left_load_pressed(state_name):
	current_left_state = Global.load_ai_state(state_name)
	if current_left_state and not current_left_state.is_empty():
		current_left_type = current_left_state.get("type", current_left_type)
		Global.add_log_entry("Left player loaded AI state: " + state_name, 1)
	else:
		Global.add_log_entry("Failed to load AI state: " + state_name, 0)
		current_left_state = null
	update_display()
	update_button_styles()

func _on_right_load_pressed(state_name):
	current_right_state = Global.load_ai_state(state_name)
	if current_right_state and not current_right_state.is_empty():
		current_right_type = current_right_state.get("type", current_right_type)
		Global.add_log_entry("Right player loaded AI state: " + state_name, 1)
	else:
		Global.add_log_entry("Failed to load AI state: " + state_name, 0)
		current_right_state = null
	update_display()
	update_button_styles()

func update_display():
	# Update percentage displays
	var left_percent = calculate_ai_percentage(current_left_type, current_left_state)
	var right_percent = calculate_ai_percentage(current_right_type, current_right_state)
	
	if left_percentage_value:
		left_percentage_value.text = "%d%%" % (left_percent * 100)
	if right_percentage_value:
		right_percentage_value.text = "%d%%" % (right_percent * 100)
	
	# Update NDS AI section visibility and content
	update_nds_ai_section()
	
	# Update play button state
	if play_button:
		play_button.disabled = (current_left_type == "Human" and current_right_type == "Human")
	
	# Update performance chart preview
	update_performance_preview()

func calculate_ai_percentage(algorithm_type: String, ai_state) -> float:
	if algorithm_type == "Human":
		return 0.0
	elif ai_state and ai_state.has("performance"):
		return ai_state["performance"]
	else:
		# Base performance for algorithm types
		match algorithm_type:
			"DecisionTree":
				return 0.6
			"DynamicScripting": 
				return 0.7
			"NDS":
				return 0.8
			_:
				return 0.5

func update_nds_ai_section():
	# Show NDS AI section only when NDS is selected
	var nds_panel = $MarginContainer/VBoxContainer/HBoxContainer/NDSAIPanel
	if nds_panel:
		nds_panel.visible = (current_left_type == "NDS" or current_right_type == "NDS")
	
	if current_left_type == "NDS" or current_right_type == "NDS":
		var params = Global.get_nds_ai_parameters()
		if nds_ai_input:
			nds_ai_input.text = "LR: %.2f, Explore: %.2f, Layers: %s" % [
				params.get("learning_rate", 0.1),
				params.get("exploration_rate", 0.3),
				str(params.get("network_layers", []))
			]

func update_performance_preview():
	# Create a simple performance chart visualization
	# This is a placeholder - you can replace with actual chart rendering
	if performance_chart:
		var chart_texture = generate_simple_chart_texture()
		performance_chart.texture = chart_texture

func generate_simple_chart_texture() -> ImageTexture:
	var image = Image.create(300, 150, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.1, 0.1, 0.1, 0.8))
	
	# Draw simple performance lines for each AI type
	var dt_data = Global.get_performance_data("DecisionTree")
	var ds_data = Global.get_performance_data("DynamicScripting")
	var nds_data = Global.get_performance_data("NDS")
	
	# This is a simplified chart - you can enhance this with proper chart rendering
	var texture = ImageTexture.create_from_image(image)
	return texture

func update_button_styles():
	# Update left algorithm buttons
	if left_algorithm_panel:
		update_algorithm_button_style(left_algorithm_panel, current_left_type)
	
	# Update right algorithm buttons  
	if right_algorithm_panel:
		update_algorithm_button_style(right_algorithm_panel, current_right_type)

func update_algorithm_button_style(panel: Node, selected_algorithm: String):
	for child in panel.get_children():
		if child is Button:
			var algorithm_name = child.name.replace("Button", "")
			if algorithm_name == selected_algorithm:
				child.add_theme_color_override("font_color", selected_color)
				child.disabled = true
			else:
				child.add_theme_color_override("font_color", normal_color)
				child.disabled = false

func _on_play_button_pressed():
	# Log the action
	Global.add_log_entry("Play button pressed - Starting game", 1)
	Global.add_log_entry("Left Player: " + current_left_type, 2)
	Global.add_log_entry("Right Player: " + current_right_type, 2)
	
	# Apply NDS AI parameters if NDS is selected
	if current_left_type == "NDS" or current_right_type == "NDS":
		apply_nds_ai_parameters()
	
	Global.set_controllers(current_left_type, current_right_type, current_left_state, current_right_state)
	print("Starting game with controllers: P1=%s, P2=%s" % [current_left_type, current_right_type])
	
	# Transition to game scene
	get_tree().change_scene_to_file("res://Levels/Simulationv2.0.tscn")

func _on_save_button_pressed():
	Global.add_log_entry("Save button pressed", 2)
	show_save_dialog()

func _on_back_button_pressed():
	Global.add_log_entry("Back button pressed - Exiting game", 1)
	get_tree().quit()  # Or go back to previous menu

func show_save_dialog():
	# Determine which AI to save
	var ai_to_save_type = ""
	var ai_to_save_state = null
	
	if current_right_type != "Human":
		ai_to_save_type = current_right_type
		ai_to_save_state = current_right_state
	elif current_left_type != "Human":
		ai_to_save_type = current_left_type
		ai_to_save_state = current_left_state
	else:
		# Show error - no AI to save
		var error_dialog = AcceptDialog.new()
		error_dialog.title = "Cannot Save"
		error_dialog.dialog_text = "No AI controller selected to save. Please select an AI algorithm for at least one player."
		add_child(error_dialog)
		error_dialog.popup_centered()
		error_dialog.connect("close_requested", error_dialog.queue_free)
		return
		
	# Create a simple save dialog
	var save_dialog = AcceptDialog.new()
	save_dialog.title = "Save AI State"
	save_dialog.dialog_text = "Enter a name for this AI state: " % ai_to_save_type
	
	var input_container = VBoxContainer.new()
	var name_input = LineEdit.new()
	name_input.placeholder_text = "e.g., My Trained AI " + ai_to_save_type
	var desc_input = LineEdit.new()
	desc_input.placeholder_text = "Description (optional)"
	
	input_container.add_child(name_input)
	input_container.add_child(desc_input)
	save_dialog.add_child(input_container)
	
	save_dialog.add_button("Save", true, "save")
	save_dialog.add_button("Cancel", true, "cancel")
	
	add_child(save_dialog)
	save_dialog.popup_centered(Vector2(400, 200))
	
	# Connect to handle the result
	if not save_dialog.is_connected("custom_action", _on_save_dialog_action.bind(name_input, desc_input, save_dialog, ai_to_save_type, ai_to_save_state)):
		save_dialog.connect("custom_action", _on_save_dialog_action.bind(name_input, desc_input, save_dialog, ai_to_save_type, ai_to_save_state))

func _on_save_dialog_action(action: String, name_input: LineEdit, desc_input: LineEdit, dialog: AcceptDialog, ai_type: String, ai_state):
	if action == "save" and name_input.text.strip_edges() != "":
		var state_name = name_input.text.strip_edges()
		var description = desc_input.text.strip_edges()
		
		# Calculate performance based on current state or use default
		var performance = 0.5
		if ai_state and ai_state.has("performance"):
			performance = ai_state["performance"]
		else:
			performance = calculate_ai_percentage(ai_type, null)
			
		var rules = []
		if ai_state and ai_state.has("rules"):
			rules = ai_state["rules"]
		else:
			# If no current rules, we can't save properly
			var error_dialog = AcceptDialog.new()
			error_dialog.title = "Save Error"
			error_dialog.dialog_text = "Cannot save AI state: No current AI rules available. Please load an AI state first or play a game to generate rules."
			add_child(error_dialog)
			error_dialog.popup_centered()
			error_dialog.connect("close_requested", error_dialog.queue_free)
			dialog.queue_free()
			return
			
		# Save the state with proper metadata for manual saves
		var success = Global.save_ai_state(state_name, ai_type, rules, performance, description)
		
		if success:
			# Refresh load sections to show the new save
			setup_load_sections()
			Global.add_log_entry("AI state manually saved: " + state_name, 1)
			print("AI state manually saved: %s" % state_name)
		else:
			Global.add_log_entry("Failed to save AI state: " + state_name, 0)
	
	dialog.queue_free()

func apply_nds_ai_parameters():
	# Parse and apply NDS AI parameters from input
	var input_text = nds_ai_input.text if nds_ai_input else ""
	# This would parse the input and set parameters in Global
	# For now, we'll use defaults
	Global.add_log_entry("Applying NDS AI parameters: " + input_text, 2)
	print("Applying NDS AI parameters: ", input_text)

# Handle NDS AI input changes
func _on_nds_input_text_changed(new_text):
	# You can add real-time validation here
	Global.add_log_entry("NDS parameters changed: " + new_text, 3)
	pass

func _on_nds_input_text_submitted(new_text):
	Global.add_log_entry("NDS parameters submitted: " + new_text, 2)
	apply_nds_ai_parameters()
