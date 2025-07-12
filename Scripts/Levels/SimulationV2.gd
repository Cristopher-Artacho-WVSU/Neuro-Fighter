extends Node2D



#ONREADY NODE VARIABLES
@onready var timer = $MainUI/Timer
@onready var player1HP = $MainUI/Player1_HPBar
@onready var player2HP = $MainUI/Player2_HPBar
@onready var timerLabel = $MainUI/Timer/TimerLabel

#OTHER VARIABLES
var totalTimerAmount = 99
var timer_running := true

func _ready():
	timerLabel.text = str(int(totalTimerAmount))
	timer.start()


func _physics_process(delta):
#	RUN THE TIMER
	if timer_running:
		totalTimerAmount -= delta
		if totalTimerAmount <= 0:
			timer_running = false
			totalTimerAmount = 0
			print("Timer has ended.")

		timerLabel.text = str(int(totalTimerAmount))

func _on_timer_timeout():
	print("Timer stops after 4 seconds")
