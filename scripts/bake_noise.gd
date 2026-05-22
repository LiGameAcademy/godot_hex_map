@tool
extends EditorScript

var resource_path := "res://resources/textures/water_noise.tres"
var output_path := "res://resources/textures/packed_water_noise.png"

func _run() -> void:
	var template := load(resource_path) as NoiseTexture2D
	if template == null:
		print("找不到基础噪声文件")
		return

	# 深拷贝：继承检查器里的 Seamless、尺寸、FastNoiseLite 参数等
	var noise_tex := template.duplicate(true) as NoiseTexture2D
	# 若只要灰度噪声进 PNG，不需要 ColorRamp 着色，可取消下一行注释：
	# noise_tex.color_ramp = null

	var noise : FastNoiseLite = noise_tex.noise
	if not is_instance_valid(noise):
		print("NoiseTexture2D.noise 需要为 FastNoiseLite")
		return

	var w := noise_tex.width
	var h := noise_tex.height

	print("使用 NoiseTexture2D（seamless=%s）生成并打包..." % noise_tex.seamless)

	var seeds := [100, 200, 300, 400]
	var imgs: Array[Image] = []

	for s in seeds:
		noise.seed = s
		var img: Image
		if noise_tex.seamless:
			img = noise.get_seamless_image(
				w, h,
				noise_tex.invert,
				noise_tex.in_3d_space,
				noise_tex.seamless_blend_skirt,
				noise_tex.normalize
			)
		else:
			img = noise.get_image(
				w, h,
				noise_tex.invert,
				noise_tex.in_3d_space,
				noise_tex.normalize
			)
		if is_instance_valid(noise_tex.color_ramp):
			img = _apply_color_ramp(img, noise_tex.color_ramp)
		imgs.append(img)

	var img_r: Image = imgs[0]
	var img_g: Image = imgs[1]
	var img_b: Image = imgs[2]
	var img_a: Image = imgs[3]

	var packed_img := Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	for y in range(h):
		for x in range(w):
			packed_img.set_pixel(x, y, Color(
				img_r.get_pixel(x, y).r,
				img_g.get_pixel(x, y).r,
				img_b.get_pixel(x, y).r,
				img_a.get_pixel(x, y).r
			))
			
	if packed_img.save_png(output_path) == OK:
		print("RGBA 通道打包完成：", output_path)
		EditorInterface.get_resource_filesystem().scan()
	else:
		print("打包失败！")

func _apply_color_ramp(src: Image, gradient: Gradient) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var dst := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var lum := src.get_pixel(x, y).r
			dst.set_pixel(x, y, gradient.sample(lum))
	return dst
