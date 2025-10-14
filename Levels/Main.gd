# res://Scripts/UI/MainMenuEnhanced.gd
extends Control

# UI elements
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
@onready var performance_chart = $MarginContainer/VBoxContainer/PreviewPanel/PerformanceChart

# State variables
var current_left_type = "Human"
var current_right_type = "DecisionTree"
var current_left_state = null
var current_right_state = null

# Colors for UI feedback
var selected_color = Color(0.2, 0.6, 1.0)
var normal_color = Color(0.3, 0.3, 0.3)

func _ready():
	print("Enhanced Main Menu Initialized")
	setup_algorithm_buttons()
	setup_load_sections()
	update_display()
	setup_nds_ai_section()

func setup_algorithm_buttons():
	# Left side buttons
	left_algorithm_panel.get_node("HumanButton").connect("pressed", _on_left_algorithm_selected.bind("Human"))
	left_algorithm_panel.get_node("DecisionTreeButton").connect("pressed", _on_left_algorithm_selected.bind("DecisionTree"))
	left_algorithm_panel.get_node("DynamicScriptingButton").connect("pressed", _on_left_algorithm_selected.bind("DynamicScripting"))
	left_algorithm_panel.get_node("NDSButton").connect("pressed", _on_left_algorithm_selected.bind("NDS"))
	
	# Right side buttons
	right_algorithm_panel.get_node("HumanButton").connect("pressed", _on_right_algorithm_selected.bind("Human"))
	right_algorithm_panel.get_node("DecisionTreeButton").connect("pressed", _on_right_algorithm_selected.bind("DecisionTree"))
	right_algorithm_panel.get_node("DynamicScriptingButton").connect("pressed", _on_right_algorithm_selected.bind("DynamicScripting"))
	right_algorithm_panel.get_node("NDSButton").connect("pressed", _on_right_algorithm_selected.bind("NDS"))

func setup_load_sections():
	# Clear existing buttons
	for child in left_load_panel.get_children():
		child.queue_free()
	for child in right_load_panel.get_children():
		child.queue_free()
	
	# Create load buttons for saved states
	for state_name in Global.get_saved_state_names():
		var state = Global.load_ai_state(state_name)
		
		# Left side load button
		var left_button = Button.new()
		left_button.text = "%s - %d%%" % [state_name, state.get("performance", 0.5) * 100]
		left_button.connect("pressed", _on_left_load_pressed.bind(state_name))
		left_button.tooltip_text = state.get("description", "No description")
		left_load_panel.add_child(left_button)
		
		# Right side load button
		var right_button = Button.new()
		right_button.text = "%s - %d%%" % [state_name, state.get("performance", 0.5) * 100]
		right_button.connect("pressed", _on_right_load_pressed.bind(state_name))
		right_button.tooltip_text = state.get("description", "No description")
		right_load_panel.add_child(right_button)

func setup_nds_ai_section():
	nds_ai_input.placeholder_text = "Enter NDS AI parameters..."
	nds_ai_input.text = "Learning Rate: 0.1, Exploration: 0.3"
	nds_ai_description.text = "Configure Neuro-Dynamic System parameters"

func _on_left_algorithm_selected(algorithm):
	current_left_type = algorithm
	current_left_state = null  # Reset saved state when changing algorithm
	update_display()
	update_button_styles()

func _on_right_algorithm_selected(algorithm):
	current_right_type = algorithm
	current_right_state = null  # Reset saved state when changing algorithm
	update_display()
	update_button_styles()

func _on_left_load_pressed(state_name):
	current_left_state = Global.load_ai_state(state_name)
	current_left_type = current_left_state.get("type", current_left_type)
	update_display()
	update_button_styles()

func _on_right_load_pressed(state_name):
	current_right_state = Global.load_ai_state(state_name)
	current_right_type = current_right_state.get("type", current_right_type)
	update_display()
	update_button_styles()

func update_display():
	# Update percentage displays
	var left_percent = calculate_ai_percentage(current_left_type, current_left_state)
	var right_percent = calculate_ai_percentage(current_right_type, current_right_state)
	
	left_percentage_value.text = "%d%%" % (left_percent * 100)
	right_percentage_value.text = "%d%%" % (right_percent * 100)
	
	# Update NDS AI section visibility and content
	update_nds_ai_section()
	
	# Update play button state
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
	nds_panel.visible = (current_left_type == "NDS" or current_right_type == "NDS")
	
	if current_left_type == "NDS" or current_right_type == "NDS":
		var params = Global.get_nds_ai_parameters()
		nds_ai_input.text = "LR: %.2f, Explore: %.2f, Layers: %s" % [
			params.get("learning_rate", 0.1),
			params.get("exploration_rate", 0.3),
			str(params.get("network_layers", []))
		]

func update_performance_preview():
	# Create a simple performance chart visualization
	# This is a placeholder - you can replace with actual chart rendering
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
	update_algorithm_button_style(left_algorithm_panel, current_left_type)
	
	# Update right algorithm buttons  
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
	# Apply NDS AI parameters if NDS is selected
	if current_left_type == "NDS" or current_right_type == "NDS":
		apply_nds_ai_parameters()
	
	Global.set_controllers(current_left_type, current_right_type, current_left_state, current_right_state)
	print("Starting game with controllers: P1=%s, P2=%s" % [current_left_type, current_right_type])
	
	# Transition to game scene
	get_tree().change_scene_to_file("res://Levels/Simulationv2.0.tscn")

func _on_save_button_pressed():
	show_save_dialog()

func _on_back_button_pressed():
	get_tree().quit()  # Or go back to previous menu

func show_save_dialog():
	# Create a simple save dialog
	var save_dialog = AcceptDialog.new()
	save_dialog.title = "Save AI State"
	save_dialog.dialog_text = "Enter a name for this AI state:"
	
	var input_container = VBoxContainer.new()
	var name_input = LineEdit.new()
	name_input.placeholder_text = "e.g., My Trained AI"
	var desc_input = LineEdit.new()
	desc_input.placeholder_text = "Description (optional)"
	
	input_container.add_child(name_input)
	input_container.add_child(desc_input)
	save_dialog.add_child(input_container)
	
	save_dialog.add_button("Save", true, "save")
	save_dialog.add_button("Cancel", true, "cancel")
	
	add_child(save_dialog)
	save_dialog.popup_centered(Vector2(300, 200))
	
	# Connect to handle the result
	save_dialog.connect("custom_action", _on_save_dialog_action.bind(name_input, desc_input, save_dialog))

func _on_save_dialog_action(action: String, name_input: LineEdit, desc_input: LineEdit, dialog: AcceptDialog):
	if action == "save" and name_input.text.strip_edges() != "":
		var state_name = name_input.text.strip_edges()
		var description = desc_input.text.strip_edges()
		
		# Determine which AI to save (prioritize right side for now)
		var ai_to_save = current_right_type if current_right_type != "Human" else current_left_type
		var performance = calculate_ai_percentage(ai_to_save, current_right_state if current_right_type != "Human" else current_left_state)
		
		# For now, save empty weights - in practice, you'd get these from the AI controller
		Global.save_ai_state(state_name, ai_to_save, {}, performance, description)
		
		# Refresh load sections
		setup_load_sections()
		
		print("AI state saved: %s" % state_name)
	
	dialog.queue_free()

func apply_nds_ai_parameters():
	# Parse and apply NDS AI parameters from input
	var input_text = nds_ai_input.text
	# This would parse the input and set parameters in Global
	# For now, we'll use defaults
	print("Applying NDS AI parameters: ", input_text)

# Handle NDS AI input changes
func _on_nds_input_text_changed(new_text):
	# You can add real-time validation here
	pass

func _on_nds_input_text_submitted(new_text):
	apply_nds_ai_parameters()
