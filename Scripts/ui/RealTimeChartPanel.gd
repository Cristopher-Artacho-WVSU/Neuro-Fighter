# res://Scripts/UI/RealTimeChartPanel.gd
extends CanvasLayer

@onready var line_chart = $Panel/MarginContainer/VBoxContainer/LineChart
@onready var bar_chart = $Panel/MarginContainer/VBoxContainer/BarChart
@onready var panel = $Panel
@onready var chart_toggle = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ChartToggle
@onready var close_button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CloseButton
@onready var stats_label = $Panel/MarginContainer/VBoxContainer/StatsLabel

var is_visible: bool = false
var current_player = null
var chart_update_timer: float = 0.0
var chart_update_interval: float = 0.5

# Data tracking
var fitness_history: Array = []
var hp_difference_history: Array = []
var rule_usage_count: Dictionary = {}
var total_rules_used: int = 0
var bar_chart_needs_update: bool = false 
var last_rule_usage_count: Dictionary = {}  

func _ready():
	panel.visible = false
	setup_charts()
	connect_signals()
	
	last_rule_usage_count = rule_usage_count.duplicate()
	
	line_chart.visible = true
	bar_chart.visible = false
	
	chart_toggle.text = "Show Rule Usage"

func _process(delta):
	if not is_visible or not current_player:
		return
	
	chart_update_timer -= delta
	if chart_update_timer <= 0:
		chart_update_timer = chart_update_interval
		update_charts()

func setup_charts():
	# Setup line chart
	line_chart.set_title("AI Learning Progress")
	line_chart.set_axis_labels("Time", "Fitness Score")
	
	# Setup horizontal bar chart
	bar_chart.set_title("Rule Usage Distribution")
	bar_chart.set_axis_labels("Rules", "Usage %")
	bar_chart.show_values = true
	
	# Initial visibility
	line_chart.visible = true
	bar_chart.visible = false

func connect_signals():
	if chart_toggle:
		chart_toggle.connect("pressed", _on_chart_toggle_pressed)
	if close_button:
		close_button.connect("pressed", _on_close_button_pressed)

func set_player_reference(player):
	current_player = player
	reset_rule_tracking()

func reset_rule_tracking():
	rule_usage_count.clear()
	total_rules_used = 0
	
	if current_player and current_player.has_method("get_rule_ids"):
		var rule_ids = current_player.get_rule_ids()
		for rule_id in rule_ids:
			rule_usage_count[rule_id] = 0

func update_charts():
	if not current_player:
		return
	
	# Update fitness data
	update_fitness_data()
	
	# Update HP difference data
	update_hp_difference_data()
	
	# Update rule usage data
	update_rule_usage_data()
	
	update_advanced_metrics()

	# Refresh charts
	refresh_line_chart()
	
	if bar_chart_needs_update:
		refresh_bar_chart()
		bar_chart_needs_update = false

func update_fitness_data():
	if current_player.has_method("calculateFitness"):
		var current_fitness = current_player.calculateFitness()
		fitness_history.append(current_fitness)
		
		# Keep only last 50 data points
		if fitness_history.size() > 50:
			fitness_history.pop_front()

func update_hp_difference_data():
	# Calculate HP difference (Player 1 HP - Player 2 HP)
	var game_scene = get_parent()
	if game_scene and game_scene.has_method("get_player_hp"):
		var p1_hp = game_scene.P1_CurrentHP
		var p2_hp = game_scene.P2_CurrentHP
		var hp_difference = p1_hp - p2_hp
		hp_difference_history.append(hp_difference)
		
		# Keep only last 50 data points
		if hp_difference_history.size() > 50:
			hp_difference_history.pop_front()

func update_rule_usage_data():
	if current_player.has_method("get_recent_used_rules"):
		var recent_rules = current_player.get_recent_used_rules()
		var had_changes = false
		
		for rule_id in recent_rules:
			if rule_id in rule_usage_count:
				rule_usage_count[rule_id] += 1
				total_rules_used += 1
				had_changes = true
		
		if had_changes:
			bar_chart_needs_update = true
				
func update_advanced_metrics():
	if not current_player or not stats_label:
		return
	
	if current_player.has_method("get_advanced_metrics"):
		var metrics = current_player.get_advanced_metrics()
		var stats_text = "Advanced Metrics:\n"
		stats_text += "Aggression: %.1f%%\n" % (metrics.get("aggression_score", 0.0) * 100)
		stats_text += "Defense: %.1f%%\n" % (metrics.get("defense_score", 0.0) * 100)
		stats_text += "Efficiency: %.1f%%\n" % (metrics.get("efficiency_score", 0.0) * 100)
		stats_text += "Adaptability: %.1f%%" % (metrics.get("adaptability_score", 0.0) * 100)
		
		stats_label.text = stats_text

func refresh_line_chart():
	if fitness_history.size() == 0:
		return
	
	# Convert fitness values to percentages for the heart monitor
	var fitness_values = []
	for fitness in fitness_history:
		fitness_values.append(fitness * 100)
	
	line_chart.set_data(fitness_values)

func refresh_bar_chart():
	if total_rules_used == 0:
		return
	
	var labels = []
	var values = []
	var colors = []
	
	var sorted_rules = []
	for rule_id in rule_usage_count:
		if rule_usage_count[rule_id] > 0:
			sorted_rules.append({"id": rule_id, "count": rule_usage_count[rule_id]})
	
	sorted_rules.sort_custom(func(a, b): return a.count > b.count)
	
	for i in range(min(10, sorted_rules.size())):
		var rule = sorted_rules[i]
		var usage_percentage = (float(rule.count) / total_rules_used) * 100
		
		labels.append("R" + str(rule.id))
		values.append(usage_percentage)
	
	bar_chart.set_data(labels, values)
	
	last_rule_usage_count = rule_usage_count.duplicate()

func toggle_visibility():
	is_visible = !is_visible
	panel.visible = is_visible
	
	if is_visible:
		# Reset data when showing charts
		fitness_history.clear()
		hp_difference_history.clear()
		reset_rule_tracking()

func _on_chart_toggle_pressed():
	# Switch between line and bar chart
	if line_chart.visible:
		line_chart.visible = false
		bar_chart.visible = true
		chart_toggle.text = "Show Learning Progress"
	else:
		line_chart.visible = true
		bar_chart.visible = false
		chart_toggle.text = "Show Rule Usage"

func _on_close_button_pressed():
	toggle_visibility()

# Public method to record rule usage from external
func record_rule_usage(rule_id: int):
	if rule_id in rule_usage_count:
		rule_usage_count[rule_id] += 1
		total_rules_used += 1

# Public method to get learning metrics
func get_learning_metrics() -> Dictionary:
	var metrics = {
		"current_fitness": fitness_history[-1] if fitness_history.size() > 0 else 0.0,
		"fitness_trend": get_fitness_trend(),
		"most_used_rule": get_most_used_rule(),
		"learning_rate": calculate_learning_rate()
	}
	return metrics

func get_fitness_trend() -> float:
	if fitness_history.size() < 2:
		return 0.0
	return fitness_history[-1] - fitness_history[0]

func get_most_used_rule() -> int:
	var max_usage = 0
	var most_used_rule = -1
	
	for rule_id in rule_usage_count:
		if rule_usage_count[rule_id] > max_usage:
			max_usage = rule_usage_count[rule_id]
			most_used_rule = rule_id
	
	return most_used_rule

func calculate_learning_rate() -> float:
	if fitness_history.size() < 10:
		return 0.0
	
	# Calculate slope of last 10 fitness values
	var recent_fitness = fitness_history.slice(-10, -1)
	var x_sum = 0.0
	var y_sum = 0.0
	var xy_sum = 0.0
	var x2_sum = 0.0
	
	for i in range(recent_fitness.size()):
		x_sum += i
		y_sum += recent_fitness[i]
		xy_sum += i * recent_fitness[i]
		x2_sum += i * i
	
	var n = recent_fitness.size()
	var slope = (n * xy_sum - x_sum * y_sum) / (n * x2_sum - x_sum * x_sum)
	return slope
