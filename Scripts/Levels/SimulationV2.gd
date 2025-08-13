extends Node2D



#ONREADY NODE VARIABLES
@onready var timer = $MainUI/Timer
@onready var player1HP = $MainUI/Player1_HPBar
@onready var player2HP = $MainUI/Player2_HPBar
@onready var timerLabel = $MainUI/Timer/TimerLabel
@onready var player2 = $NPCCharacter1
@onready var player1 = $PlayerCharacter1
#REFERENCE THE PLAYER 2 AI

#OTHER VARIABLES
var totalTimerAmount = 99
var timer_running := true
var max_hp = 100
var P2_CurrentHP = 100
var P1_CurrentHP = 100


func _ready():
	timerLabel.text = str(int(totalTimerAmount))
	timer.start()
	init_HPBar()

func _physics_process(delta):
	monitorHP()
#	RUN THE TIMER
	if timer_running:
		totalTimerAmount -= delta
		if totalTimerAmount <= 0:
			timer_running = false
			get_tree().quit()
	

		timerLabel.text = str(int(totalTimerAmount))

func _on_timer_timeout():
	print("Timer stops after 4 seconds")
	player2.generate_script()

#FUNCTION FOR INITIALIZING THE INITIAL HP
func init_HPBar():
	player1HP.max_value = max_hp
	player2HP.max_value = max_hp
	
#FUNCTION FOR MONITORING THE CURRENT HP. IF 0, GAME ENDS
func monitorHP():
	player1HP.max_value = max_hp
	player2HP.max_value = max_hp
	player1HP.value = P1_CurrentHP
	player2HP.value = P2_CurrentHP
	
	if player2HP.value <= 0:
		print("Player 1 Wins")
		get_tree().quit()
	if player1HP.value <= 0:
		print("Player 2 Wins")
		get_tree().quit()

#APPLIES DAMAGE TO PLAYER 2 REFERENCING THE amount GIVEN FROM on_hurt_finished of DS
func apply_damage_to_player2(amount):
	P2_CurrentHP = max(0, P2_CurrentHP - amount)
	player2HP.value = P2_CurrentHP
	print("Player 2 HP:", P2_CurrentHP)

	if P2_CurrentHP <= 0:
		player2.KO()
		print("Player 2 KO!")
		
#APPLIES DAMAGE TO PLAYER 2 REFERENCING THE amount GIVEN FROM on_hurt_finished of PLAYER1
func apply_damage_to_player1(amount):
	P1_CurrentHP = max(0, P1_CurrentHP - amount)
	player1HP.value = P1_CurrentHP
	print("Player 2 HP:", P1_CurrentHP)
	
	if P2_CurrentHP <= 0:
		player1.KO()
		print("Player 2 KO!")
