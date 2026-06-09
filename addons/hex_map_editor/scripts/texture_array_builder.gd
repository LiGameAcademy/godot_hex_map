@tool
extends EditorScript

var texture_paths: Array[String] = [
	"res://assets/textures/terrain/sand.png",
	"res://assets/textures/terrain/grass.png",
	"res://assets/textures/terrain/mud.png",
	"res://assets/textures/terrain/stone.png",
	"res://assets/textures/terrain/snow.png",
]
var save_path := "res://resources/terrain/terrain_texture_array.tres"

func _run() -> void:
	var images: Array[Image] = []
	for p in texture_paths:
		var img := Image.load_from_file(p)
		if img == null or img.is_empty():
			push_error("加载纹理失败: %s" % p)
			return
		images.append(img)

	# Godot 要求 Texture2DArray 的每层图像尺寸、格式、mipmap 设置一致
	var base_size := images[0].get_size()
	var base_format := images[0].get_format()

	for i in range(1, images.size()):
		if images[i].get_size() != base_size:
			push_error("纹理尺寸不一致: %s" % texture_paths[i])
			return
		if images[i].get_format() != base_format:
			push_error("纹理格式不一致: %s" % texture_paths[i])
			return

	var texture_array := Texture2DArray.new()
	texture_array.create_from_images(images)

	var err := ResourceSaver.save(texture_array, save_path)
	if err != OK:
		push_error("保存 Texture2DArray 失败，错误码: %d" % err)
		return

	print("Texture2DArray 构建成功: %s" % save_path)
