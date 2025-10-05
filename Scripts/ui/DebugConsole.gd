# res://Scripts/UI/DebugConsole.gd
extends CanvasLayer

@onready var console_panel = $ConsolePanel
@onready var command_input = $ConsolePanel/CommandInput
@onready var output_display = $ConsolePanel/OutputDisplay

var commands = {
	"help": "Show available commands",
	"stats": "Show AI statistics",
	"save [label]": "Save current AI state",
	"load [label]": "Load AI state",
	"performance": "Show performance data",
	"rules": "Show current rules"
}

func _ready():
	console_panel.visible = false

func _input(event):
	if event.is_action_pressed("toggle_console"):
		console_panel.visible = not console_panel.visible
		if console_panel.visible:
			command_input.grab_focus()

func _on_command_input_text_submitted(new_text):
	process_command(new_text)
	command_input.text = ""

func process_command(command: String):
	var parts = command.split(" ")
	var cmd = parts[0].to_lower()
	var args = parts.slice(1)
	
	match cmd:
		"help":
			show_help()
		"stats":
			show_stats()
		"save":
			if args.size() > 0:
				save_ai_state(args[0])
			else:
				output_display.text += "Usage: save [label]\n"
		"load":
			if args.size() > 0:
				load_ai_state(args[0])
			else:
				output_display.text += "Usage: load [label]\n"
		"performance":
			show_performance()
		"rules":
			show_rules()
		_:
			output_display.text += "Unknown command: " + cmd + "\n"

func show_help():
	output_display.text += "Available commands:\n"
	for cmd in commands:
		output_display.text += "  " + cmd + " - " + commands[cmd] + "\n"
