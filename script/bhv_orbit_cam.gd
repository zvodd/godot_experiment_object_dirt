extends Node3D

@onready var camera_3d: Camera3D = $Camera3D

#signal mouse_lock(value:bool)
var mouse_lock:bool = false

# Sensitivity for mouse movement
@export var sensitivity := 0.005

func _input(event: InputEvent) -> void:
	# Right click to capture mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				#mouse_lock.emit(true)
				mouse_lock = true
			else: 
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				#mouse_lock.emit(false)
				mouse_lock = false

	# Handle rotation only when mouse is captured
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.relative)

func _rotate_camera(relative: Vector2) -> void:
	# 1. Create the Yaw Quaternion (Rotation around Global Y)
	# We use Vector3.UP so it always rotates around the world's horizon
	var q_yaw = Quaternion(Vector3.UP, -relative.x * sensitivity)

	# 2. Create the Pitch Quaternion (Rotation around Local X)
	# We use Vector3.RIGHT because local X is always the object's right side
	var q_pitch = Quaternion(Vector3.RIGHT, -relative.y * sensitivity)

	# 3. Apply the rotation using multiplication
	# Order matters: (Global_Rot * Current_Rot * Local_Rot)
	quaternion = q_yaw * quaternion * q_pitch

	# 4. Normalize to prevent floating-point drift over time
	quaternion = quaternion.normalized()
