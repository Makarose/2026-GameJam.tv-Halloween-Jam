class_name Player
extends CharacterBody3D


@export var speed: float = 8.0
@export var zoom_multiplier: float = 0.3

var mouse_motion: Vector2 = Vector2.ZERO
var camera_zoom_speed: float = 20.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var smooth_camera: Camera3D = %SmoothCamera3D
@onready var smooth_camera_fov := smooth_camera.fov


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	if Input.is_action_pressed("zoom"):
		smooth_camera.fov = lerp(
			smooth_camera.fov, 
			smooth_camera_fov * zoom_multiplier, 
			delta * camera_zoom_speed
			)
	else:
		smooth_camera.fov = lerp(
			smooth_camera.fov, 
			smooth_camera_fov, 
			delta * camera_zoom_speed * 1.5
			)


func _physics_process(delta: float) -> void:
	handle_camera_rotation()
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if Input.is_action_pressed("zoom"):
			velocity.x *= zoom_multiplier
			velocity.y *= zoom_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
