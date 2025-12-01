#res://Scripts/ui/LineChart.gd
extends Control
class_name LineChart

# Configuration
var title: String = ""
var x_axis_label: String = "Time"
var y_axis_label: String = "Value"
var show_grid: bool = true
var animation_speed: float = 0.3

# Data
var data_points: Array = []
var max_data_points: int = 50
var current_max_value: float = 0.0
var current_min_value: float = 0.0
var value_range: float = 1.0

# Heart monitor theme
var theme_colors = {
	"background": Color(0.02, 0.05, 0.02, 0.95),  # Very dark green/black
	"grid": Color(0.1, 0.3, 0.1, 0.5),           # Dark green grid
	"heart_line": Color(0.0, 1.0, 0.2, 1.0),     # Bright green heart line
	"grid_bright": Color(0.2, 0.6, 0.2, 0.3),    # Brighter grid for major lines
	"text": Color(0.4, 0.8, 0.4, 1.0),           # Green text
	"title": Color(0.6, 1.0, 0.6, 1.0)           # Bright green title
}

# Animation
var pulse_effect: float = 0.0
var is_animating: bool = true

func _ready():
	set_process(true)

func _process(delta):
	# Continuous pulse animation for the heart monitor effect
	pulse_effect = fmod(pulse_effect + delta * 3.0, 1.0)
	queue_redraw()

func add_data_point(value: float):
	data_points.append(value)
	
	# Keep only the last max_data_points
	if data_points.size() > max_data_points:
		data_points.pop_front()
	
	# Update min/max for scaling
	update_value_range()
	queue_redraw()

func set_data(values: Array):
	data_points = values.duplicate()
	
	# Keep only the last max_data_points
	while data_points.size() > max_data_points:
		data_points.pop_front()
	
	update_value_range()
	queue_redraw()

func update_value_range():
	if data_points.size() == 0:
		current_max_value = 1.0
		current_min_value = 0.0
		value_range = 1.0
		return
	
	current_max_value = data_points.max()
	current_min_value = data_points.min()
	value_range = current_max_value - current_min_value
	
	# Ensure some range for display
	if value_range == 0:
		current_max_value += 1.0
		current_min_value = max(0.0, current_min_value - 0.5)
		value_range = current_max_value - current_min_value

func set_title(chart_title: String):
	title = chart_title
	queue_redraw()

func set_axis_labels(x_label: String, y_label: String):
	x_axis_label = x_label
	y_axis_label = y_label
	queue_redraw()

func _draw():
	draw_background()
	draw_grid()
	draw_heart_line()
	draw_labels()

func draw_background():
	var background_rect = Rect2(Vector2.ZERO, size)
	draw_rect(background_rect, theme_colors.background, true)
	
	# Draw subtle scan lines for authentic monitor look
	var scan_line_spacing = 4.0
	for y in range(0, int(size.y), int(scan_line_spacing)):
		draw_line(
			Vector2(0, y),
			Vector2(size.x, y),
			Color(0.05, 0.15, 0.05, 0.3),
			1.0
		)

func draw_grid():
	if not show_grid or data_points.size() == 0:
		return
	
	var margin_left = 50.0
	var margin_right = 20.0
	var margin_top = 40.0
	var margin_bottom = 40.0
	
	var chart_width = size.x - margin_left - margin_right
	var chart_height = size.y - margin_top - margin_bottom
	
	# Horizontal grid lines (like EKG paper)
	var major_grid_steps = 5
	var minor_grid_steps = major_grid_steps * 5  # More detailed grid
	
	for i in range(minor_grid_steps + 1):
		var y = margin_top + (chart_height * i / minor_grid_steps)
		var is_major = i % 5 == 0
		
		var grid_color = theme_colors.grid_bright if is_major else theme_colors.grid
		var line_width = 1.5 if is_major else 0.8
		
		draw_line(
			Vector2(margin_left, y),
			Vector2(size.x - margin_right, y),
			grid_color,
			line_width
		)
	
	# Vertical grid lines (time markers)
	if data_points.size() > 1:
		for i in range(data_points.size()):
			if i % 5 == 0:  # Show every 5th vertical line
				var x = margin_left + (chart_width * i / (data_points.size() - 1))
				draw_line(
					Vector2(x, margin_top),
					Vector2(x, size.y - margin_bottom),
					theme_colors.grid,
					0.5
				)

func draw_heart_line():
	if data_points.size() < 2:
		return
	
	var margin_left = 50.0
	var margin_right = 20.0
	var margin_top = 40.0
	var margin_bottom = 40.0
	
	var chart_width = size.x - margin_left - margin_right
	var chart_height = size.y - margin_top - margin_bottom
	#var value_range = current_max_value - current_min_value
	
	if value_range == 0:
		value_range = 1.0
	
	var points = []
	
	# Create points
	for i in range(data_points.size()):
		var x = margin_left + (chart_width * i / (data_points.size() - 1))
		var normalized_value = (data_points[i] - current_min_value) / value_range
		var y = size.y - margin_bottom - (chart_height * normalized_value)
		points.append(Vector2(x, y))
	
	# Draw the heart line with pulse effect
	if points.size() >= 2:
		for i in range(points.size() - 1):
			var from_point = points[i]
			var to_point = points[i + 1]
			
			# Add subtle pulse effect to the line
			var pulse_width = 2.5 + sin(pulse_effect * PI * 2.0) * 0.5
			
			draw_line(from_point, to_point, theme_colors.heart_line, pulse_width)
			
			# Draw small dots at data points for EKG look
			if i % 2 == 0:  # Every other point
				draw_circle(from_point, 1.5, theme_colors.heart_line)
	
	# Draw a "blip" at the end for real-time effect
	if points.size() > 0:
		var last_point = points[-1]
		draw_circle(last_point, 3.0, Color(1.0, 1.0, 1.0, 0.8))
		draw_circle(last_point, 1.5, theme_colors.heart_line)

func draw_labels():
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	
	# Title with glow effect
	if title != "":
		var title_size = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		
		# Title glow
		draw_string(
			font,
			Vector2(size.x / 2 - title_size.x / 2 + 1, 26),
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Color(0.1, 0.3, 0.1, 0.8)
		)
		
		# Main title
		draw_string(
			font,
			Vector2(size.x / 2 - title_size.x / 2, 25),
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			theme_colors.title
		)
	
	# Y-axis value labels
	if data_points.size() > 0:
		var margin_left = 50.0
		var margin_top = 40.0
		var margin_bottom = 40.0
		var chart_height = size.y - margin_top - margin_bottom
		
		var value_steps = 5
		for i in range(value_steps + 1):
			var y = margin_top + (chart_height * i / value_steps)
			var value = current_max_value - (value_range * i / value_steps)
			var value_text = "%.1f" % value
			var text_size = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
			
			draw_string(
				font,
				Vector2(margin_left - text_size.x - 5, y + 4),
				value_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size - 2,
				theme_colors.text
			)
	
	# X-axis label
	if x_axis_label != "":
		var x_label_size = font.get_string_size(x_axis_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
		draw_string(
			font,
			Vector2(size.x / 2 - x_label_size.x / 2, size.y - 15),
			x_axis_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size - 2,
			theme_colors.text
		)
