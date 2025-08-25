extends Node

# 3D Survivor Game State Manager
# This script handles the 3D multiplayer survivor game logic

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal player_leveled_up(player_id: int, new_level: int)
signal enemy_spawned(enemy_type: String, position: Vector3)

# Game configuration
const MAX_WAVES = 50
const WAVE_DURATION = 60.0  # seconds
const ENEMIES_PER_WAVE_MULTIPLIER = 1.5

# Game state
var current_wave: int = 0
var wave_timer: float = 0.0
var is_wave_active: bool = false
var enemies_alive: int = 0
var total_enemies_spawned: int = 0

# Enemy spawning
var enemy_spawn_timer: float = 0.0
var enemy_spawn_interval: float = 2.0
var spawn_points: Array[Vector3] = []

# Player stats tracking
var player_stats: Dictionary = {}

func _ready():
	# Connect to gamestate signals
	gamestate.game_ended.connect(_on_game_ended)

func _process(delta):
	if not gamestate.is_game_in_progress():
		return
	
	if is_wave_active:
		_update_wave(delta)
		_handle_enemy_spawning(delta)

func start_3d_game():
	print("Starting 3D Survivor Game!")
	current_wave = 0
	_setup_spawn_points()
	_start_next_wave()

func _setup_spawn_points():
	# Get spawn points from the world
	var world = get_tree().get_root().get_node_or_null("World3D")
	if not world:
		print("Warning: No World3D found!")
		return
	
	spawn_points.clear()
	var spawn_container = world.get_node_or_null("SpawnPoints")
	if spawn_container:
		for child in spawn_container.get_children():
			if child is Marker3D:
				spawn_points.append(child.global_position)
	
	# Add default spawn points if none found
	if spawn_points.is_empty():
		spawn_points = [
			Vector3(20, 2, 0),
			Vector3(-20, 2, 0),
			Vector3(0, 2, 20),
			Vector3(0, 2, -20),
			Vector3(15, 2, 15),
			Vector3(-15, 2, -15),
			Vector3(15, 2, -15),
			Vector3(-15, 2, 15)
		]

func _start_next_wave():
	current_wave += 1
	
	if current_wave > MAX_WAVES:
		_complete_game()
		return
	
	print("Starting Wave ", current_wave)
	is_wave_active = true
	wave_timer = WAVE_DURATION
	enemies_alive = 0
	total_enemies_spawned = 0
	
	# Calculate enemies to spawn this wave
	var enemies_to_spawn = int(5 * pow(ENEMIES_PER_WAVE_MULTIPLIER, current_wave - 1))
	enemy_spawn_interval = max(0.5, WAVE_DURATION / enemies_to_spawn)
	enemy_spawn_timer = 0.0
	
	wave_started.emit(current_wave)

func _update_wave(delta):
	wave_timer -= delta
	
	# Check if wave should end
	if wave_timer <= 0 and total_enemies_spawned > 0 and enemies_alive <= 0:
		_complete_wave()

func _complete_wave():
	is_wave_active = false
	print("Wave ", current_wave, " completed!")
	wave_completed.emit(current_wave)
	
	# Give players experience for completing the wave
	_reward_players_for_wave()
	
	# Start next wave after a brief delay
	await get_tree().create_timer(3.0).timeout
	_start_next_wave()

func _complete_game():
	print("Congratulations! All waves completed!")
	# TODO: Show victory screen

func _handle_enemy_spawning(delta):
	enemy_spawn_timer -= delta
	
	if enemy_spawn_timer <= 0 and wave_timer > 0:
		_spawn_enemy()
		enemy_spawn_timer = enemy_spawn_interval

func _spawn_enemy():
	if spawn_points.is_empty():
		return
	
	# Choose random spawn point
	var spawn_pos = spawn_points[randi() % spawn_points.size()]
	
	# Determine enemy type based on wave
	var enemy_type = _get_enemy_type_for_wave()
	
	# Actually spawn the enemy (this would call an enemy spawner)
	_create_enemy(enemy_type, spawn_pos)
	
	total_enemies_spawned += 1
	enemies_alive += 1
	
	enemy_spawned.emit(enemy_type, spawn_pos)

func _get_enemy_type_for_wave() -> String:
	# Simple enemy type selection based on wave
	if current_wave <= 5:
		return "basic_zombie"
	elif current_wave <= 15:
		return choose_random(["basic_zombie", "fast_zombie"])
	elif current_wave <= 30:
		return choose_random(["basic_zombie", "fast_zombie", "tank_zombie"])
	else:
		return choose_random(["basic_zombie", "fast_zombie", "tank_zombie", "boss_zombie"])

func choose_random(array: Array) -> String:
	return array[randi() % array.size()]

func _create_enemy(enemy_type: String, position: Vector3):
	# Load and instantiate the enemy
	var enemy_scene = load("res://enemy3d.tscn")
	var enemy = enemy_scene.instantiate()
	
	# Configure the enemy
	enemy.set_enemy_type(enemy_type)
	enemy.global_position = position
	
	# Add to the world
	var world = get_tree().get_root().get_node_or_null("World3D")
	if world:
		var enemies_node = world.get_node_or_null("Enemies")
		if enemies_node:
			enemies_node.add_child(enemy)
			print("Successfully spawned ", enemy_type, " at ", position)
		else:
			print("Warning: No Enemies node found in World3D")
	else:
		print("Warning: No World3D found for enemy spawning")

@rpc("any_peer", "call_local")
func enemy_killed(enemy_type: String, killer_id: int):
	enemies_alive -= 1
	
	# Give experience to the killer
	var exp_amount = _get_experience_for_enemy(enemy_type)
	_give_player_experience(killer_id, exp_amount)

func _get_experience_for_enemy(enemy_type: String) -> float:
	match enemy_type:
		"basic_zombie":
			return 10.0
		"fast_zombie":
			return 15.0
		"tank_zombie":
			return 25.0
		"boss_zombie":
			return 100.0
		_:
			return 10.0

func _give_player_experience(player_id: int, amount: float):
	# Find the player and give them experience
	var world = get_tree().get_root().get_node_or_null("World3D")
	if not world:
		return
	
	var players_node = world.get_node_or_null("Players")
	if not players_node:
		return
	
	for player in players_node.get_children():
		if player.get_multiplayer_authority() == player_id:
			player.gain_experience.rpc(amount)
			break

func _reward_players_for_wave():
	var wave_bonus = current_wave * 50.0
	
	var world = get_tree().get_root().get_node_or_null("World3D")
	if not world:
		return
	
	var players_node = world.get_node_or_null("Players")
	if not players_node:
		return
	
	# Give all living players wave completion bonus
	for player in players_node.get_children():
		if player.has_method("is_alive") and player.is_alive():
			player.gain_experience.rpc(wave_bonus)

func _on_game_ended():
	current_wave = 0
	is_wave_active = false
	enemies_alive = 0
	total_enemies_spawned = 0

# Utility functions
func get_current_wave() -> int:
	return current_wave

func get_wave_time_remaining() -> float:
	return wave_timer

func get_enemies_alive() -> int:
	return enemies_alive

func is_game_active() -> bool:
	return is_wave_active
