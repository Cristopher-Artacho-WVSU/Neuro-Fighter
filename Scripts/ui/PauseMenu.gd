# res://Scripts/ui/PauseMenu.gd
extends CanvasLayer

signal resume_game
signal save_state
signal quit_to_menu

@onready var resume_button = $ColorRect/CenterContainer/VBoxContainer/ResumeButton
@onready var save_button = $ColorRect/CenterContainer/VBoxContainer/SaveButton
@onready var quit_button = $ColorRect/CenterContainer/VBoxContainer/QuitButton

func _ready():
	# Set this node to process even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	resume_button.connect("pressed", _on_resume_pressed)
	save_button.connect("pressed", _on_save_pressed)
	quit_button.connect("pressed", _on_quit_pressed)
	
	resume_button.process_mode = process_mode
	save_button.process_mode = process_mode
	quit_button.process_mode = process_mode
	
	# Hide by default
	hide()
	print("DEBUG: PAUSE MENU INITIALIZED")

func _on_resume_pressed():
	print("DEBUG: RESUME BUTTON IS CLICKED!")
	resume_game.emit()
	hide()

func _on_save_pressed():
	print("DEBUG: SAVE BUTTON IS CLICKED!")
	save_state.emit()
	# Show confirmation
	print("DS AI State Saved!")

func _on_quit_pressed():
	quit_to_menu.emit()

func _input(event):
	if event.is_action_pressed("close") and visible:
		print("ESC pressed in PauseMenu - Visible: ", visible)
		if visible:
			_on_resume_pressed()
