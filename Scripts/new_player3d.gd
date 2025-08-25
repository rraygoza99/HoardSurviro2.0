class_name NewPlayer3D
extends CharacterBody3D

@export var stunned : bool = false

const SPEED = 8.0
const MOUSE_SENSITIVITY = 0.002

# Camera pitch limits
var camera_pitch : float = 0.0
const CAMERA_PITCH_MAX = 90.0
const CAMERA_PITCH_MIN = -90.0

# Node references
@onready var camera : Camera3D = $Camera3D

# Get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Set up camera for local player
	if is_multiplayer_authority():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false

@rpc("any_peer", "call_local")
func set_authority(id : int) -> void:
	set_multiplayer_authority(id)
	
	# Update camera settings when authority changes
	if is_multiplayer_authority():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false

func _physics_process(delta : float):
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if is_multiplayer_authority():
		# Handle movement input
		if stunned:
			velocity.x = 0
			velocity.z = 0
		else:
			# Get input direction
			var input_dir = Vector2.ZERO
			if Input.is_action_pressed("move_left"):
				input_dir.x -= 1
			if Input.is_action_pressed("move_right"):
				input_dir.x += 1
			if Input.is_action_pressed("move_up"):
				input_dir.y -= 1
			if Input.is_action_pressed("move_down"):
				input_dir.y += 1
			
			# Normalize input
			input_dir = input_dir.normalized()
			
			# Calculate movement direction based on camera orientation
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED * delta * 10)
				velocity.z = move_toward(velocity.z, 0, SPEED * delta * 10)
			
			# Handle jump
			if Input.is_action_just_pressed("ui_accept") and is_on_floor():
				velocity.y = 12.0
	
	move_and_slide()

func _input(event):
	if not is_multiplayer_authority():
		return
	
	# Handle mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Horizontal rotation (Y-axis)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Vertical rotation (X-axis) - only rotate camera
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY
		camera_pitch = clamp(camera_pitch, deg_to_rad(CAMERA_PITCH_MIN), deg_to_rad(CAMERA_PITCH_MAX))
		camera.rotation.x = camera_pitch
	
	# Handle escape key to toggle mouse capture
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_player_name(value : String):
	$Label3D.text = value

@rpc("any_peer", "call_local")
func teleport(new_position : Vector3) -> void:
	global_position = new_position

@rpc("any_peer", "call_local")
func stun_player(_by_who):
	# If we're already stunned, ignore
	if stunned:
		return
	
	# Otherwise, stun us
	stunned = true
	print("Player ", name, " was stunned!")
	
	# Simple stun duration without animation player
	await get_tree().create_timer(2.0).timeout
	stunned = false
	print("Player ", name, " recovered from stun!")
    