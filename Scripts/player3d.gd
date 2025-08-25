class_name Player3D
extends CharacterBody3D

# Movement constants
const SPEED = 8.0
const JUMP_VELOCITY = 12.0
const ACCELERATION = 10.0
const FRICTION = 10.0
const AIR_ACCELERATION = 5.0

# Survivor game constants
const MAX_HEALTH = 100.0
const INVINCIBILITY_TIME = 1.5

# Player state
@export var health: float = MAX_HEALTH
@export var level: int = 1
@export var experience: float = 0.0
@export var experience_to_next_level: float = 100.0
@export var stunned: bool = false
@export var invincible: bool = false

# Multiplayer synchronization
@export var synced_position: Vector3
@export var synced_rotation: float
@export var player_name: String = ""

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var name_label: Label3D = $NameLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var invincibility_timer: Timer = $InvincibilityTimer

# Input handling
var movement_input: Vector2 = Vector2.ZERO
var mouse_sensitivity: float = 0.002
var camera_pitch: float = 0.0
var camera_pitch_max: float = 90.0
var camera_pitch_min: float = -90.0

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	print("Player3D spawned: ", name)
	
	# Initialize timers and connections
	if invincibility_timer:
		invincibility_timer.wait_time = INVINCIBILITY_TIME
		invincibility_timer.one_shot = true
		invincibility_timer.timeout.connect(_on_invincibility_timeout)
	
	# Set up camera for local player
	if is_multiplayer_authority():
		camera.current = true
		if name_label:
			name_label.text = player_name
	else:
		camera.current = false
		if name_label:
			name_label.text = player_name
	
	# Initialize health
	_update_health_display()

func _physics_process(delta):
	# Handle input only if this is the local player
	if is_multiplayer_authority():
		_handle_input()
		_handle_movement(delta)
		
		# Sync position for other players
		synced_position = global_position
		synced_rotation = global_rotation.y
	else:
		# Non-authoritative players interpolate to synced position
		global_position = global_position.lerp(synced_position, delta * 10.0)
		global_rotation.y = lerp_angle(global_rotation.y, synced_rotation, delta * 10.0)

func _handle_input():
	# Movement input
	movement_input = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("move_right"):
		movement_input.x += 1
	if Input.is_action_pressed("move_up"):
		movement_input.y -= 1
	if Input.is_action_pressed("move_down"):
		movement_input.y += 1
	
	movement_input = movement_input.normalized()

func _handle_movement(delta):
	if not is_multiplayer_authority() or stunned:
		return
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle horizontal movement
	var transform_basis = global_transform.basis
	var input_dir = Vector3(movement_input.x, 0, movement_input.y)
	var direction = (transform_basis * input_dir).normalized()
	
	if direction != Vector3.ZERO:
		var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, direction.x * SPEED, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, accel * delta)
	else:
		var friction_val = FRICTION if is_on_floor() else AIR_ACCELERATION * 0.1
		velocity.x = move_toward(velocity.x, 0, friction_val * delta)
		velocity.z = move_toward(velocity.z, 0, friction_val * delta)
	
	move_and_slide()

# Multiplayer authority functions
@rpc("any_peer", "call_local")
func set_authority(id: int) -> void:
	set_multiplayer_authority(id)

@rpc("any_peer", "call_local")
func teleport(new_position: Vector3) -> void:
	global_position = new_position
	synced_position = new_position

@rpc("any_peer", "call_local")
func set_player_name(value: String):
	player_name = value
	if name_label:
		name_label.text = value

# Health and damage system
@rpc("any_peer", "call_local")
func take_damage(damage: float, attacker_id: int = -1):
	if invincible or stunned:
		return
	
	health -= damage
	health = max(0, health)
	_update_health_display()
	
	if health <= 0:
		die.rpc(attacker_id)
	else:
		# Become invincible for a short time
		become_invincible()

@rpc("any_peer", "call_local")
func heal(amount: float):
	health += amount
	health = min(MAX_HEALTH, health)
	_update_health_display()

@rpc("any_peer", "call_local")
func die(_killer_id: int = -1):
	if stunned:
		return
	
	stunned = true
	print("Player ", player_name, " died!")
	
	# TODO: Add death animation and respawn logic
	await get_tree().create_timer(3.0).timeout
	respawn.rpc()

@rpc("any_peer", "call_local")
func respawn():
	health = MAX_HEALTH
	stunned = false
	invincible = false
	_update_health_display()
	
	# TODO: Move to spawn point
	print("Player ", player_name, " respawned!")

func become_invincible():
	invincible = true
	if invincibility_timer:
		invincibility_timer.start()
	
	# Visual feedback for invincibility
	_flash_player()

func _on_invincibility_timeout():
	invincible = false

func _flash_player():
	# Simple flashing effect for invincibility
	if mesh_instance:
		var tween = create_tween()
		tween.set_loops(int(INVINCIBILITY_TIME * 4))  # Flash 4 times per second
		tween.tween_property(mesh_instance, "transparency", 0.5, 0.125)
		tween.tween_property(mesh_instance, "transparency", 0.0, 0.125)

func _update_health_display():
	if health_bar:
		health_bar.value = (health / MAX_HEALTH) * 100

# Experience and leveling system
@rpc("any_peer", "call_local")
func gain_experience(amount: float):
	experience += amount
	
	while experience >= experience_to_next_level:
		level_up()

@rpc("any_peer", "call_local")
func level_up():
	experience -= experience_to_next_level
	level += 1
	experience_to_next_level *= 1.2  # Increase XP requirement
	
	print("Player ", player_name, " leveled up to level ", level, "!")
	# TODO: Add level up effects and skill selection

# Weapon and combat system (basic framework)
@rpc("any_peer", "call_local")
func attack(target_position: Vector3):
	if stunned:
		return
	
	# Basic ranged attack implementation
	print("Player ", player_name, " attacks at position: ", target_position)
	
	# Simple raycast attack
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1, 0), target_position)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.has_method("take_damage"):
		# Hit an enemy
		var damage = 25.0  # Base damage
		result.collider.take_damage.rpc(damage, multiplayer.get_unique_id())
		print("Hit enemy for ", damage, " damage!")

func _handle_combat():
	if not is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("attack"):
		# Attack in the direction the camera is facing
		var camera_transform = camera.global_transform
		var attack_range = 20.0
		var target_pos = camera_transform.origin + (-camera_transform.basis.z * attack_range)
		attack.rpc(target_pos)

# Input handling for UI
func _input(event):
	if not is_multiplayer_authority():
		return
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Utility functions
func get_health_percentage() -> float:
	return health / MAX_HEALTH

func is_alive() -> bool:
	return health > 0 and not stunned

func get_level() -> int:
	return level

func get_experience_percentage() -> float:
	return experience / experience_to_next_level

