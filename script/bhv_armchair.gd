extends StaticBody3D

@onready var ov_mat : ShaderMaterial = $Armchairmesh.material_overlay
const init_dirt_img = preload("res://materials/perlin15 _250.png")
const init_brush_img = preload("res://materials/GradientBrushCircl_16x16.png")

var image : Image = Image.new()
var imagetex : ImageTexture
var brush_mask : Image = Image.new()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ev = event as InputEventKey
		if ev.keycode == KEY_SPACE:
			var dims : Vector2 = imagetex.get_size()
			var rloc =  Vector2i(randi_range(0, dims.x), randi_range(0, dims.y))
			erase_dirt(rloc)

func _ready() -> void:
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

## pos: Center of the brush in pixel coordinates
func erase_dirt(pos: Vector2i):
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
func erase_dirt_from_global_pos(pos:Vector3):
	pass
