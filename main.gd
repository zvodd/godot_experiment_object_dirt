extends Node3D

@export var ray_length : float = 50

@onready var pivot: Node3D = %Pivot
@onready var camera_3d: Camera3D = %Camera3D
@onready var water_particles: Node3D = %WaterParticles
@onready var cleanable_object: Marker3D = %CleanableObject

var count = 0

func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	var lmb_state = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	match [pivot.mouse_lock, lmb_state]:
		[false, true]:
			proc_mouse_raycast()
			water_particles.visible = true
		[_, _]:
			water_particles.visible = false



func proc_mouse_raycast():
	# get the viewport mouse pos
	var mousePos = get_viewport().get_mouse_position()
	
	# define the start of the ray	
	var rayOrigin = camera_3d.project_ray_origin(Vector2(mousePos.x, mousePos.y))
	
	# define end of the ray by taking the normal direction and multiplying that out by X units
	var rayEnd = rayOrigin + camera_3d.project_ray_normal(mousePos) * ray_length
	# get the current physics state
	var spaceState = get_world_3d().direct_space_state
	var intersection = spaceState.intersect_ray(PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd))
#	print("ray end: ", rayEnd)
	if count == 0:
		print(intersection, get_world_3d().space.get_id())
		count += 1
	if intersection:
		var pos = intersection.get("position")
		var normal = intersection.get("normal")
		#print(pos)
		debug_line(pos, pos + normal * 0.2)
		
		## Water Particles
		water_particles.global_position = pos
		
		#water_particles.rotation = (pos - normal).normalized()
		
		var direction_global = (pos + normal).normalized()    
		# 2. Create a Global Basis looking in that direction
		# Basis.looking_at takes a DIRECTION, not a target position
		var target_global_basis = Basis.looking_at(direction_global, Vector3.UP)
		# 3. Convert to Local Space
		var target_local_basis = target_global_basis
		
		var parent_global_basis = cleanable_object.global_basis
		target_local_basis = parent_global_basis.inverse() * target_global_basis
		
		water_particles.basis = Basis(target_local_basis.get_rotation_quaternion())
		
		## Send to paint
		var target =  %CleanableObject/Armchair
		


func debug_line(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	
	get_tree().get_root().add_child(mesh_instance)
	
	return mesh_instance
