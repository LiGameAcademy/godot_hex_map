extends Node
class_name HexMapEditor

@export var hex_grid: HexGrid
# 可以在编辑器中编辑颜色
@export var colors : PackedColorArray = [
	Color.RED,
	Color.GREEN,
	Color.BLUE
]
var active_color: Color = colors[0] # 默认画笔红色
## 当前海拔等级
var active_elevation: int = 0  

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(hex_grid):
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)

	# 按 1、2、3 切换颜色
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: active_color = colors[0]
			KEY_2: active_color = colors[1]
			KEY_3: active_color = colors[2]
			KEY_Q: active_elevation -= 1
			KEY_E: active_elevation += 1

func _handle_click(mouse_pos: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, 0.0)
	var hit_position = plane.intersects_ray(ray_origin, ray_dir)
	if hit_position != null:
		var coords := HexCoordinates.from_position(hit_position)
		var cell := hex_grid.get_cell(coords)
		if is_instance_valid(cell):
			# 染色
			cell.color = active_color
			cell.elevation = active_elevation
			hex_grid.refresh()
		else:
			push_error("HexMapEditor: cell is not valid!")
