extends Control
class_name HorizontalBarChart

# Configuration
var title: String = ""
var subtitle: String = ""
var x_axis_label: String = ""
var y_axis_label: String = ""
var show_values: bool = true
var animation_speed: float = 0.5

# Data
var categories: Array = []
var values: Array = []
var colors: Array = []
var max_value: float = 0.0

# Theme colors
var theme_colors = {
	"background": Color(0.95, 0.95, 0.96),
	"grid": Color(0.8, 0.8, 0.85),
	"text": Color(0.2, 0.2, 0.2),
	"title": Color(0.1, 0.1, 0.3),
	"axis": Color(0.4, 0.4, 0.5)
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

func set_data(category_labels: Array, data_values: Array, bar_colors: Array = []):
	categories = category_labels
	values = data_values
	colors = bar_colors
	
	# Calculate max value with some padding
	max_value = 0.0
	for value in values:
		if value > max_value:
			max_value = value
	max_value = max_value * 1.1  # 10% padding
	
	# Generate colors if not provided
	if colors.size() != categories.size():
		generate_colors()
	
	# Start animation
	animation_progress = 0.0
	is_animating = true
	queue_redraw()

func generate_colors():
	colors.clear()
	var hue_step = 1.0 / categories.size()
	for i in range(categories.size()):
		var hue = i * hue_step
		colors.append(Color.from_hsv(hue, 0.7, 0.8, 1.0))

func set_title(chart_title: String, chart_subtitle: String = ""):
	title = chart_title
	subtitle = chart_subtitle
	queue_redraw()

func set_axis_labels(x_label: String, y_label: String):
	x_axis_label = x_label
	y_axis_label = y_label
	queue_redraw()

func _draw():
	draw_background()
	draw_grid_lines()
	draw_bars()
	draw_axes()
	draw_labels()

func draw_background():
	var background_rect = Rect2(Vector2.ZERO, size)
	draw_rect(background_rect, theme_colors.background, true)

func draw_grid_lines():
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	
	# Calculate chart area (with margins)
	var margin_left = 80.0
	var margin_right = 40.0
	var margin_top = 60.0
	var margin_bottom = 60.0
	
	var chart_width = size.x - margin_left - margin_right
	var chart_height = size.y - margin_top - margin_bottom
	
	# Draw vertical grid lines
	var grid_steps = 5
	for i in range(grid_steps + 1):
		var x = margin_left + (chart_width * i / grid_steps)
		var value = max_value * i / grid_steps
		
		# Grid line
		draw_line(
			Vector2(x, margin_top),
			Vector2(x, size.y - margin_bottom),
			theme_colors.grid,
			1.0
		)
		
		# Value label
		var value_text = str(int(value))
		var text_size = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(
			font,
			Vector2(x - text_size.x / 2, size.y - margin_bottom + 20),
			value_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			theme_colors.text
		)

func draw_bars():
	if categories.size() == 0:
		return
	
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	
	# Calculate chart area
	var margin_left = 80.0
	var margin_right = 40.0
	var margin_top = 60.0
	var margin_bottom = 60.0
	
	var chart_width = size.x - margin_left - margin_right
	var chart_height = size.y - margin_top - margin_bottom
	
	var bar_height = min(30.0, chart_height / categories.size() * 0.8)
	var bar_spacing = (chart_height / categories.size()) - bar_height
	
	for i in range(categories.size()):
		var y = margin_top + (bar_height + bar_spacing) * i + bar_spacing / 2
		
		# Calculate bar width with animation
		var target_width = (values[i] / max_value) * chart_width
		var current_width = target_width * animation_progress
		
		# Draw bar
		var bar_rect = Rect2(margin_left, y, current_width, bar_height)
		draw_rect(bar_rect, colors[i], true)
		
		# Draw bar outline
		draw_rect(bar_rect, theme_colors.axis, false, 1.0)
		
		# Draw category label
		draw_string(
			font,
			Vector2(10, y + bar_height / 2 + font_size / 3),
			categories[i],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			theme_colors.text
		)
		
		# Draw value label on bar
		if show_values and current_width > 50:  # Only show if bar is wide enough
			var value_text = "%.1f%%" % values[i]
			var text_size = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var text_x = margin_left + current_width - text_size.x - 5
			var text_y = y + bar_height / 2 + font_size / 3
			
			# Ensure text stays within bar
			text_x = max(margin_left + 5, text_x)
			
			draw_string(
				font,
				Vector2(text_x, text_y),
				value_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				Color.WHITE
			)

func draw_axes():
	var margin_left = 80.0
	var margin_right = 40.0
	var margin_top = 60.0
	var margin_bottom = 60.0
	
	# Y-axis line
	draw_line(
		Vector2(margin_left, margin_top),
		Vector2(margin_left, size.y - margin_bottom),
		theme_colors.axis,
		2.0
	)
	
	# X-axis line
	draw_line(
		Vector2(margin_left, size.y - margin_bottom),
		Vector2(size.x - margin_right, size.y - margin_bottom),
		theme_colors.axis,
		2.0
	)

func draw_labels():
	var font = ThemeDB.fallback_font
	var font_size = ThemeDB.fallback_font_size
	var title_font_size = font_size + 4
	
	# Draw title
	if title != "":
		var title_size = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)
		draw_string(
			font,
			Vector2(size.x / 2 - title_size.x / 2, 30),
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			title_font_size,
			theme_colors.title
		)
	
	# Draw subtitle
	if subtitle != "":
		var subtitle_size = font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(
			font,
			Vector2(size.x / 2 - subtitle_size.x / 2, 50),
			subtitle,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			theme_colors.text
		)
	
	# Draw x-axis label
	if x_axis_label != "":
		var x_label_size = font.get_string_size(x_axis_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(
			font,
			Vector2(size.x / 2 - x_label_size.x / 2, size.y - 20),
			x_axis_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			theme_colors.text
		)
