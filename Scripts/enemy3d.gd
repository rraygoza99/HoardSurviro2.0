class_name Enemy3D
extends CharacterBody3D

# Enemy properties
@export var max_health: float = 50.0
@export var speed: float = 3.0
@export var damage: float = 20.0
@export var experience_reward: float = 10.0
@export var enemy_type: String = "basic_zombie"

# State
var health: float
var target_player: CharacterBody3D = null
var is_attacking: bool = false
var attack_cooldown: float = 0.0

# Constants
const ATTACK_RANGE = 2.0
const ATTACK_COOLDOWN_TIME = 1.5
const PLAYER_DETECTION_RANGE = 15.0

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $HealthBar

# Get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	health = max_health
	
	# Set up attack timer
	if attack_timer:
		attack_timer.wait_time = ATTACK_COOLDOWN_TIME
		attack_timer.one_shot = true
		attack_timer.timeout.connect(_on_attack_cooldown_finished)
	
	_update_health_display()

func _physics_process(delta):
	# Only server controls enemy behavior
	if not multiplayer.is_server():
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Find and chase the nearest player
	_find_nearest_player()
	
	if target_player and is_instance_valid(target_player):
		_chase_player(delta)
		_try_attack_player()
	else:
		# No target, stop moving
		velocity.x = 0
		velocity.z = 0
	
	move_and_slide()

func _find_nearest_player():
	var world = get_tree().get_root().get_node_or_null("World3D")
	if not world:
		return
	
	var players_node = world.get_node_or_null("Players")
	if not players_node:
		return
	
	var nearest_distance = PLAYER_DETECTION_RANGE
	var nearest_player: CharacterBody3D = null
	
	for player in players_node.get_children():
		if not player.has_method("is_alive") or not player.is_alive():
			continue
			
		var distance = global_position.distance_to(player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_player = player
	
	target_player = nearest_player

func _chase_player(_delta):
	if not target_player or not is_instance_valid(target_player):
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	direction.y = 0  # Don't move vertically
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	# Face the player
	if direction.length() > 0:
		look_at(global_position + direction, Vector3.UP)

func _try_attack_player():
	if not target_player or not is_instance_valid(target_player):
		return
	
	var distance = global_position.distance_to(target_player.global_position)
	
	if distance <= ATTACK_RANGE and attack_cooldown <= 0:
		_attack_player()

func _attack_player():
	if not target_player or is_attacking:
		return
	
	is_attacking = true
	attack_cooldown = ATTACK_COOLDOWN_TIME
	
	# Deal damage to the player
	if target_player.has_method("take_damage"):
		target_player.take_damage.rpc(damage, -1)  # -1 indicates enemy damage
	
	print("Enemy attacked player for ", damage, " damage!")
	
	# Reset attack state
	await get_tree().create_timer(0.5).timeout  # Attack animation time
	is_attacking = false

func _on_attack_cooldown_finished():
	attack_cooldown = 0.0

@rpc("any_peer", "call_local")
func take_damage(damage_amount: float, attacker_id: int = -1):
	health -= damage_amount
	health = max(0, health)
	_update_health_display()
	
	print("Enemy took ", damage_amount, " damage! Health: ", health)
	
	if health <= 0:
		die.rpc(attacker_id)

@rpc("any_peer", "call_local")
func die(killer_id: int = -1):
	print("Enemy died!")
	
	# Notify the survivor game manager
	var survivor_manager = get_node_or_null("/root/SurvivorGameManager")
	if survivor_manager:
		survivor_manager.enemy_killed.rpc(enemy_type, killer_id)
	
	# Create death effect (placeholder)
	_create_death_effect()
	
	# Remove the enemy
	queue_free()

func _create_death_effect():
	# TODO: Add particle effects, sound, etc.
	print("Death effect for enemy at: ", global_position)

func _update_health_display():
	if health_bar:
		health_bar.value = (health / max_health) * 100
		health_bar.visible = health < max_health

# Utility functions
func get_health_percentage() -> float:
	return health / max_health

func is_alive() -> bool:
	return health > 0

func set_enemy_type(type: String):
	enemy_type = type
	_configure_for_type()

func _configure_for_type():
	match enemy_type:
		"basic_zombie":
			max_health = 50.0
			speed = 3.0
			damage = 20.0
			experience_reward = 10.0
		"fast_zombie":
			max_health = 30.0
			speed = 6.0
			damage = 15.0
			experience_reward = 15.0
		"tank_zombie":
			max_health = 150.0
			speed = 1.5
			damage = 40.0
			experience_reward = 25.0
		"boss_zombie":
			max_health = 500.0
			speed = 2.0
			damage = 80.0
			experience_reward = 100.0
	
	health = max_health
	_update_health_display()
