extends Node
class_name HexMapEditor

@export var hex_grid: HexGrid
# 可以在编辑器中编辑颜色
@export var colors : Dictionary[StringName, Color] = {
	"红色": Color.RED,
	"绿色": Color.GREEN,
	"蓝色": Color.BLUE
}

@export var active_color: int = 0 # 默认画笔红色
## 当前海拔等级
@export var active_elevation: int = 0  
@export var brush_radius: int = 0

@export var disable_color : bool = false
@export var disable_elevation : bool = false

signal active_color_changed(color: Color)
signal color_disable_changed()
signal active_elevation_changed(elevation: int)
signal elevation_disable_changed()
signal brush_radius_changed(radius: int)

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(hex_grid):
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)

	# 按 1、2、3 切换颜色
	#elif event is InputEventKey and event.pressed:
		#match event.keycode:
			#KEY_1: active_color = 0
			#KEY_2: active_color = 1
			#KEY_3: active_color = 2
			#KEY_Q: active_elevation -= 1
			#KEY_E: active_elevation += 1

func set_active_color(color: int) -> void:
	if active_color == color:
		return
	active_color = color
	active_color_changed.emit(color)

func set_disable_color(disable: bool) -> void:
	if disable_color == disable:
		return
	disable_color = disable
	color_disable_changed.emit()

func set_active_elevation(elevation: int) -> void:
	if active_elevation == elevation:
		return
	active_elevation = elevation
	active_elevation_changed.emit(elevation)

func set_disable_elevation(disable: bool) -> void:
	if disable_elevation == disable:
		return
	disable_elevation = disable
	elevation_disable_changed.emit()

func set_brush_radius(radius: int) -> void:
	radius = max(radius, 0)
	if brush_radius == radius:
		return
	brush_radius = radius
	brush_radius_changed.emit(radius)

func refresh() -> void:
	hex_grid.refresh()

func _handle_click(mouse_pos: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	if not is_instance_valid(camera):
		push_error("HexMapEditor: camera is null")
		return

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, 0.0)
	var hit_position = plane.intersects_ray(ray_origin, ray_dir)
	if hit_position == null:
		push_error("HexMapEditor: hit_position is null")
		return

	var coords := HexCoordinates.from_position(hit_position)
	var center_cell : HexCell = hex_grid.get_cell(coords)
	if not is_instance_valid(center_cell):
		push_error("HexMapEditor: cell is not valid!")
		return
	
	_edit_cells(center_cell)

func _edit_cells(center: HexCell) -> void:
	if not is_instance_valid(center):
		push_error("HexMapEditor: center is null")
		return

	# 半径 0：只改中心格子
	if brush_radius <= 0:
		_edit_cell(center)
		return

	var center_coords := center.coordinates
	var r: int = brush_radius

	# 使用立方体坐标的“六边形半径”算法
	for dx in range(-r, r + 1):
		var min_dz: int = max(-r, -dx - r)
		var max_dz: int = min(r, -dx + r)
		for dz in range(min_dz, max_dz + 1):
			var nx := center_coords.x + dx
			var nz := center_coords.z + dz
			var coords := HexCoordinates.new(nx, nz)
			var cell := hex_grid.get_cell(coords)
			if is_instance_valid(cell):
				_edit_cell(cell)

func _edit_cell(cell: HexCell) -> void:
	if not is_instance_valid(cell):
		push_error("HexMapEditor: cell is null")
		return
	if not disable_color:
		cell.color = colors.values()[active_color]
	if not disable_elevation:
		cell.elevation = active_elevation
