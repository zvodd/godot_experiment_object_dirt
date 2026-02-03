class_name CleanableObjectHolder
extends Node3D

# _onready vars
var objbody : PhysicsBody3D
var mesh_instance: MeshInstance3D 
var ov_mat : ShaderMaterial 

const init_dirt_img = preload("res://materials/perlin15 _250.png")
const init_brush_img = preload("res://materials/GradientBrushCircl_16x16.png")

var mesh_data = MeshDataTool.new()

var image : Image = Image.new()
var imagetex : ImageTexture
var brush_mask : Image = Image.new()

func _onready_vars() -> void:
	for child in get_children():
		if child is PhysicsBody3D:
			objbody = child
			break
	assert(objbody != null, "Missing cleanable body")
	for child in objbody.get_children():
		if child is MeshInstance3D:
			mesh_instance = child
			break
	assert(objbody != null, "Missing cleanable mesh instance")
	ov_mat = mesh_instance.material_overlay
	#cache mesh data
	mesh_data.create_from_surface(mesh_instance.mesh, 0)
	

func _ready() -> void:
	_onready_vars()
	# 1. Setup main texture
	#image = init_dirt_img.get_image()
	image.copy_from(init_dirt_img)
	
	image.convert(Image.FORMAT_RGBA8)
		
	imagetex = ImageTexture.create_from_image(image)
	ov_mat.set_shader_parameter("texture_albedo", imagetex)
	
	# 2. Setup brush: Convert brightness to Alpha
	# We create an image that is fully transparent where the brush was white
	#brush_mask = init_brush_img.get_image()
	brush_mask.copy_from(init_brush_img)
	
	brush_mask.convert(Image.FORMAT_RGBA8)
	
	print(image.get_format())
	print(imagetex.get_format())
	print(brush_mask.get_format())
	
	for x in range(brush_mask.get_width()):
		for y in range(brush_mask.get_height()):
			var p = brush_mask.get_pixel(x, y)
			# Set alpha to the inverse of brightness (white = 0 alpha)
			# This makes the "brush" a patch of transparency
			brush_mask.set_pixel(x, y, Color(0, 0, 0, 1.0 - p.r))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ev = event as InputEventKey
		if ev.keycode == KEY_SPACE:
			var dims : Vector2 = imagetex.get_size()
			var rloc =  Vector2i(randi_range(0, dims.x), randi_range(0, dims.y))
			erase_dirt(rloc)

## pos: Center of the brush in pixel coordinates
func erase_dirt(pos: Vector2i)  -> void:
	var brush_size = brush_mask.get_size()
	var top_left = pos - (brush_size / 2)
	
	# blit_rect_mask(src_image, mask_image, src_rect, dest_point)
	# This replaces the pixels in 'image' with pixels from 'brush_mask'
	image.blit_rect_mask(
		brush_mask, 
		brush_mask, 
		Rect2i(Vector2i.ZERO, brush_size), 
		top_left
	)
	
	# Push update to GPU
	imagetex.update(image)

#TODO
func erase_dirt_from_face(hit_pos:Vector3, face_idx:int) -> void:
	# 3. Get the indices of the 3 vertices making up the hit face
	var v1_idx = mesh_data.get_face_vertex(face_idx, 0)
	var v2_idx = mesh_data.get_face_vertex(face_idx, 1)
	var v3_idx = mesh_data.get_face_vertex(face_idx, 2)
	
	# 4. Get the positions and UVs of those vertices
	# Convert positions to Global Space to match the raycast 'position'
	var xform = mesh_instance.global_transform
	var p1 = xform * mesh_data.get_vertex(v1_idx)
	var p2 = xform * mesh_data.get_vertex(v2_idx)
	var p3 = xform * mesh_data.get_vertex(v3_idx)
	
	var uv1 = mesh_data.get_vertex_uv(v1_idx)
	var uv2 = mesh_data.get_vertex_uv(v2_idx)
	var uv3 = mesh_data.get_vertex_uv(v3_idx)
	
	# 5. Calculate Barycentric Coordinates
	var bary = Geometry3D.get_triangle_barycentric_coords(hit_pos, p1, p2, p3)
	
	# 6. Final UV interpolation
	var final_uv = uv1 * bary.x + uv2 * bary.y + uv3 * bary.z
	print(final_uv)
	erase_dirt (final_uv)
