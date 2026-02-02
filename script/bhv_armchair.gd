extends StaticBody3D

@onready var ov_mat :ShaderMaterial = $Armchairmesh.material_overlay
const initial_dirt_tex = preload("uid://ig8fhjrpppdy")
var imagetex

func _ready() -> void:
	var img :Image = initial_dirt_tex.get_image()
	#img.convert(Image.FORMAT_LA8)
	img.convert(Image.FORMAT_RGBA8)
	print(img)
	imagetex = ImageTexture.create_from_image(img)
	ov_mat.set_shader_parameter("texture_albedo", imagetex)
