class_name Player
extends CharacterBody3D


@export var speed: float = 8.0
@export var zoom_multiplier: float = 0.3

# how far from the center the player can walk
@export var player_max_distance: float = 25.0

# center of the play area (the Crowd node sits at the origin by default)
@export var limit_center: Vector3 = Vector3.ZERO

var mouse_motion: Vector2 = Vector2.ZERO
var camera_zoom_speed: float = 20.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var smooth_camera: Camera3D = %SmoothCamera3D
@onready var smooth_camera_fov := smooth_camera.fov
@onready var ray_cast_3d: RayCast3D = $CameraPivot/RayCast3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var target_fov := smooth_camera_fov
	var rate := 40.0 # zooming out
	if Input.is_action_pressed("zoom"):
		target_fov = smooth_camera_fov * zoom_multiplier
		rate = 24.0 # zooming in

	var weight := 1.0 - exp(-rate * delta)
	smooth_camera.fov = clampf(lerpf(smooth_camera.fov, target_fov, weight), 1.0, 179.0)


func _physics_process(delta: float) -> void:
	handle_camera_rotation()
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		#if Input.is_action_pressed("zoom"):
			#velocity.x *= zoom_multiplier
			#velocity.y *= zoom_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# keep the player inside the circle
	var offset := global_position - limit_center
	offset.y = 0.0
	if offset.length() > player_max_distance:
		offset = offset.normalized() * player_max_distance
		global_position.x = limit_center.x + offset.x
		global_position.z = limit_center.z + offset.z


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion = -event.relative * 0.001
		if Input.is_action_pressed("zoom"):
			mouse_motion *= zoom_multiplier


func handle_camera_rotation() -> void:
	rotate_y(mouse_motion.x)
	camera_pivot.rotate_x(mouse_motion.y)
	camera_pivot.rotation_degrees.x = clampf(
		camera_pivot.rotation_degrees.x, -90.0, 90.0
	)
	mouse_motion = Vector2.ZERO
