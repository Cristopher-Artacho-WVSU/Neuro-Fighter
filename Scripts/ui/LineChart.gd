# res://Scripts/UI/LineChart.gd
extends Control

class_name LineChart

# Configuration
var title: String = ""
var x_axis_label: String = "Time"
var y_axis_label: String = "Value"
var show_grid: bool = true
var show_points: bool = true
var animation_speed: float = 0.8

# Data
var data_sets: Array = []  # Array of dictionaries: {label, values, color, visible}
var x_labels: Array = []
var current_data_set: int = 0

# Theme
var theme_colors = {
	"background": Color(0.05, 0.05, 0.08, 0.9),
	"grid": Color(0.3, 0.3, 0.4),
	"text": Color(0.9, 0.9, 0.9),
	"title": Color(1.0, 1.0, 1.0),
	"axis": Color(0.6, 0.6, 0.7)
}

# Animation
var animation_progress: float = 0.0
var is_animating: bool = false

func _ready():
	set_process(true)

func _process(delta):
	if is_animating:
		animation_progress = min(animation_progress + delta / animation_speed, 1.0)
		if animation_progress >= 1.0:
			is_animating = false
		queue_redraw()

func add_data_set(label: String, color: Color = Color.WHITE):
	var new_set = {
		"label": label,
		"values": [],
		"color": color,
		"visible": true
	}
	data_sets.append(new_set)
	return data_sets.size() - 1

func set_data(data_set_index: int, values: Array, x_axis_labels: Array = []):
	if data_set_index >= 0 and data_set_index < data_sets.size():
		data_sets[data_set_index]["values"] = values.duplicate()
		if x_axis_labels.size() > 0:
			x_labels = x_axis_labels.duplicate()
		else:
			# Generate default labels
			x_labels.clear()
			for i in range(values.size()):
				x_labels.append(str(i))
		
		# Start animation
		animation_progress = 0.0
		is_animating = true
		queue_redraw()

func set_title(chart_title: String):
	title = chart_title
	queue_redraw()

func set_axis_labels(x_label: String, y_label: String):
	x_axis_label = x_label
	y_axis_label = y_label
	queue_redraw()

func _draw():
	draw_background()
	if show_grid:
		draw_grid()
	draw_lines()
	draw_axes()
	draw_labels()
	draw_legend()

func draw_background():
	var background_rect = Rect2(Vector2.ZERO, size)
	draw_rect(background_rect, theme_colors.background, true)

func draw_grid():
	var margin_left = 60.0
	var margin_right = 40.0
	var margin_top = 50.0
	var margin_bottom = 60.0
	
	var chart_width = size.x - margin_left - margin_right
	var chart_height = size.y - margin_top - margin_bottom
	
	# Horizontal grid lines
	var h_steps = 5
	for i in range(h_steps + 1):
		var y = margin_top + (chart_height * i / h_steps)
		draw_line(
			Vector2(margin_left, y),
			Vector2(size.x - margin_right, y),
			theme_colors.grid,
			1.0
		)
	
	# Vertical grid lines
	if x_labels.size() > 1:
		for i in range(x_labels.size()):
			var x = margin_left + (chart_width * i / (x_labels.size() - 1))
			draw_line(
				Vector2(x, margin_top),
				Vector2(x, size.y - margin_bottom),
				theme_colors.grid,
				0.5
			)

func draw_lines():
	if data_sets.size() == 0:
		return
	
	var margin_left = 60.0
	var margin_right = 40.0
	var margin_top = 50.0
	var margin_bottom = 60.0
	
	var chart_width = size.x - margin_left - margin_right
	var chart_height = size.y - margin_top - margin_bottom
	
	for data_set in data_sets:
		if not data_set.visible or data_set.values.size() < 2:
			continue
		
		# Find min and max values for scaling
		var min_val = data_set.values.min()
		var max_val = data_set.values.max()
		var value_range = max_val - min_val
		if value_range == 0:
			value_range = 1.0
		
		var points = []
		
		# Create points with animation
		for i in range(data_set.values.size()):
			var x = margin_left + (chart_width * i / max(1, data_set.values.size() - 1))
			var normalized_value = (data_set.values[i] - min_val) / value_range
			var target_y = size.y - margin_bottom - (chart_height * normalized_value)
			var current_y = margin_top + (target_y - margin_top) * (1.0 - animation_progress)
			
			points.append(Vector2(x, current_y))
			
			# Draw data points
			if show_points:
				draw_circle(Vector2(x, current_y), 3.0, data_set.color)
				draw_circle(Vector2(x, current_y), 1.5, Color.WHITE)
		
		# Draw line
		if points.size() >= 2:
			for i in range(points.size() - 1):
				draw_line(points[i], points[i + 1], data_set.color, 2.0)

func draw_axes():
	var margin_left = 60.0
	var margin_right = 40.0
	var margin_top = 50.0
	var margin_bottom = 60.0
	
	# Y-axis
	draw_line(
		Vector2(margin_left, margin_top),
		Vector2(margin_left, size.y - margin_bottom),
		theme_colors.axis,
		2.0
	)
	
	# X-axis
	draw_line(
		Vector2(margin_left, size.y - margin_bottom),
		Vector2(size.x - margin_right, size.y - margin_bottom),
		theme_colors.axis,
		2.0
	)

func draw_labels():
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	
	# Title
	if title != "":
		var title_size = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(
			font,
			Vector2(size.x / 2 - title_size.x / 2, 25),
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			theme_colors.title
		)
	
	# X-axis label
	var x_label_size = font.get_string_size(x_axis_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(
		font,
		Vector2(size.x / 2 - x_label_size.x / 2, size.y - 15),
		x_axis_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		theme_colors.text
	)
	
	# Y-axis label (rotated)
	# Note: Godot 4 doesn't have built-in rotated text drawing, so we'll skip rotation for now
	var y_label_size = font.get_string_size(y_axis_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(
		font,
		Vector2(10, size.y / 2 + y_label_size.x / 2),
		y_axis_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		theme_colors.text
	)

func draw_legend():
	if data_sets.size() == 0:
		return
	
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	var legend_x = size.x - 150
	var legend_y = 60
	var line_height = 20
	
	for i in range(data_sets.size()):
		if not data_sets[i].visible:
			continue
		
		var y = legend_y + i * line_height
		
		# Color indicator
		draw_rect(Rect2(legend_x, y, 15, 10), data_sets[i].color, true)
		draw_rect(Rect2(legend_x, y, 15, 10), theme_colors.text, false, 1.0)
		
		# Label
		draw_string(
			font,
			Vector2(legend_x + 20, y + 8),
			data_sets[i].label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size - 2,
			theme_colors.text
		)
