#res://Scripts/ui/BarChart.gd
extends Control
class_name BarChart

# Configuration
var title: String = ""
var x_axis_label: String = "Categories"
var y_axis_label: String = "Values"
var show_values: bool = true
var animation_speed: float = 0.5

# Data
var categories: Array = []
var values: Array = []
var colors: Array = []
var max_value: float = 0.0

# Modern theme colors
var theme_colors = {
	"background": Color(0.12, 0.12, 0.15, 0.95),
	"grid": Color(0.3, 0.3, 0.35, 0.6),
	"text": Color(0.9, 0.9, 0.9, 1.0),
	"title": Color(1.0, 1.0, 1.0, 1.0),
	"axis": Color(0.6, 0.6, 0.7, 1.0)
}

# Animation
var current_values: Array = []
var target_values: Array = []
var animation_progress: float = 0.0
var is_animating: bool = false

func _ready():
	set_process(true)

func _process(delta):
	if is_animating:
		animation_progress = min(animation_progress + delta / animation_speed, 1.0)
		
		# Smoothly interpolate toward target values
		for i in range(current_values.size()):
			if i < target_values.size():
				current_values[i] = lerp(current_values[i], target_values[i], 0.2)
		
		if animation_progress >= 1.0:
			is_animating = false
			# Snap to target values when animation completes
			for i in range(min(current_values.size(), target_values.size())):
				current_values[i] = target_values[i]
		
		queue_redraw()

func set_data(category_labels: Array, data_values: Array, bar_colors: Array = []):
	categories = category_labels.duplicate()
	target_values = []
	
	# Convert all values to float
	for value in data_values:
		target_values.append(float(value))
	
	# Initialize or update current values for animation
	if current_values.size() != target_values.size():
		current_values.resize(target_values.size())
		for i in range(current_values.size()):
			current_values[i] = 0.0
	
	# Calculate max value for scaling
	max_value = 0.0
	for value in target_values:
		if value > max_value:
			max_value = value
	max_value = max(1.0, max_value * 1.1)  # Add 10% padding
	
	# Set colors
	if bar_colors.size() == categories.size():
		colors = bar_colors.duplicate()
	else:
		generate_colors()
	
	# Start animation
	animation_progress = 0.0
	is_animating = true
	queue_redraw()

func generate_colors():
	colors.clear()
	var base_hues = [0.0, 0.1, 0.3, 0.6, 0.8]  # Red, orange, green, blue, purple
	
	for i in range(categories.size()):
		var hue = base_hues[i % base_hues.size()]
		var saturation = 0.7 + fmod(i * 0.05, 0.3)
		var value = 0.8 + fmod(i * 0.03, 0.2)
		colors.append(Color.from_hsv(hue, saturation, value))

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
	draw_bars()
	draw_axes()
	draw_labels()

func draw_background():
	var background_rect = Rect2(Vector2.ZERO, size)
	draw_rect(background_rect, theme_colors.background, true)

func draw_grid():
	var margin_left = 60.0
	var margin_right = 30.0
	var margin_top = 50.0
	var margin_bottom = 60.0
	
	var chart_width = size.x - margin_left - margin_right
	var chart_height = size.y - margin_top - margin_bottom
	
	# Horizontal grid lines
	var grid_steps = 5
	for i in range(grid_steps + 1):
		var y = margin_top + (chart_height * i / grid_steps)
		var value = max_value * (1.0 - float(i) / grid_steps)
		
		# Grid line
		draw_line(
			Vector2(margin_left, y),
			Vector2(size.x - margin_right, y),
			theme_colors.grid,
			1.0
		)
		
		# Value label
		var font = ThemeDB.fallback_font
		var font_size = ThemeDB.fallback_font_size
		var value_text = str(int(value))
		var text_size = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		
		draw_string(
			font,
			Vector2(margin_left - text_size.x - 8, y + font_size / 3),
			value_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			theme_colors.text
		)

func draw_bars():
	if categories.size() == 0:
		return
	
	var margin_left = 60.0
	var margin_right = 30.0
	var margin_top = 50.0
	var margin_bottom = 60.0
	
	var chart_width = size.x - margin_left - margin_right
	var chart_height = size.y - margin_top - margin_bottom
	
	var bar_width = chart_width / categories.size() * 0.7
	var bar_spacing = chart_width / categories.size() * 0.3
	
	for i in range(categories.size()):
		var x = margin_left + (bar_width + bar_spacing) * i + bar_spacing / 2
		
		# Use animated current value
		var current_value = current_values[i] if i < current_values.size() else 0.0
		var bar_height = (current_value / max_value) * chart_height
		
		# Draw bar with gradient effect
		var bar_rect = Rect2(x, margin_top + chart_height - bar_height, bar_width, bar_height)
		draw_rect(bar_rect, colors[i], true)
		
		# Draw bar highlight (lighter top)
		var highlight_rect = Rect2(x, margin_top + chart_height - bar_height, bar_width, min(bar_height, 10.0))
		draw_rect(highlight_rect, colors[i].lightened(0.3), true)
		
		# Draw bar outline
		draw_rect(bar_rect, theme_colors.axis, false, 1.0)
		
		# Draw category label (x-axis)
		var font = ThemeDB.fallback_font
		var font_size = ThemeDB.fallback_font_size
		var category_text = categories[i]
		var text_size = font.get_string_size(category_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
		
		# Rotate text if too many categories
		if categories.size() > 8:
			# Draw vertical text
			for j in range(category_text.length()):
				var char_text = category_text[j]
				draw_string(
					font,
					Vector2(x + bar_width / 2 - 4, size.y - margin_bottom + 15 + j * 12),
					char_text,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					font_size - 4,
					theme_colors.text
				)
		else:
			draw_string(
				font,
				Vector2(x + bar_width / 2 - text_size.x / 2, size.y - margin_bottom + 20),
				category_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size - 2,
				theme_colors.text
			)
		
		# Draw value on top of bar
		if show_values and bar_height > 25:
			var value_text = "%.1f" % current_value
			var value_text_size = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
			
			draw_string(
				font,
				Vector2(x + bar_width / 2 - value_text_size.x / 2, margin_top + chart_height - bar_height - 8),
				value_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size - 2,
				theme_colors.text
			)

func draw_axes():
	var margin_left = 60.0
	var margin_right = 30.0
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
	
	# Y-axis label
	if y_axis_label != "":
		var y_label_size = font.get_string_size(y_axis_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
		draw_string(
			font,
			Vector2(15, size.y / 2 + y_label_size.x / 2),
			y_axis_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size - 2,
			theme_colors.text
		)
