extends Control

# UI References
@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var health_label: Label = $VBoxContainer/HealthBar/HealthLabel
@onready var level_label: Label = $VBoxContainer/PlayerInfo/LevelLabel
@onready var exp_bar: ProgressBar = $VBoxContainer/PlayerInfo/ExpBar
@onready var wave_label: Label = $VBoxContainer/GameInfo/WaveLabel
@onready var enemies_label: Label = $VBoxContainer/GameInfo/EnemiesLabel
@onready var timer_label: Label = $VBoxContainer/GameInfo/TimerLabel

# Player reference
var local_player: CharacterBody3D = null

func _ready():
	# Connect to survivor game manager signals
	var survivor_manager = get_node_or_null("/root/SurvivorGameManager")
	if survivor_manager:
		survivor_manager.wave_started.connect(_on_wave_started)
		survivor_manager.wave_completed.connect(_on_wave_completed)
	
	# Find the local player
	_find_local_player()

func _process(_delta):
	_update_ui()

func _find_local_player():
	var world = get_tree().get_root().get_node_or_null("World3D")
	if not world:
		return
	
	var players_node = world.get_node_or_null("Players")
	if not players_node:
		return
	
	# Find the player that this client controls
	for player in players_node.get_children():
		if player.is_multiplayer_authority():
			local_player = player
			print("Found local player: ", player.name)
			break

func _update_ui():
	if not local_player or not is_instance_valid(local_player):
		_find_local_player()
		return
	
	# Update health
	if health_bar and health_label:
		var health_pct = local_player.get_health_percentage()
		health_bar.value = health_pct * 100
		health_label.text = str(int(local_player.health)) + "/" + str(int(local_player.MAX_HEALTH))
	
	# Update level and experience
	if level_label:
		level_label.text = "Level: " + str(local_player.get_level())
	
	if exp_bar:
		var exp_pct = local_player.get_experience_percentage()
		exp_bar.value = exp_pct * 100
	
	# Update game info
	var survivor_manager = get_node_or_null("/root/SurvivorGameManager")
	# if survivor_manager:
	# 	if wave_label:
	# 		wave_label.text = "Wave: " + str(survivor_manager.get_current_wave())
		
	# 	if enemies_label:
	# 		enemies_label.text = "Enemies: " + str(survivor_manager.get_enemies_alive())
		
	# 	if timer_label:
	# 		var time_left = survivor_manager.get_wave_time_remaining()
	# 		timer_label.text = "Time: " + str(int(time_left)) + "s"

func _on_wave_started(wave_number: int):
	print("Wave ", wave_number, " started!")
	# TODO: Show wave start notification

func _on_wave_completed(wave_number: int):
	print("Wave ", wave_number, " completed!")
	# TODO: Show wave completion notification
