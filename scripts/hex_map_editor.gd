extends Node
class_name HexMapEditor

enum RiverMode { IGNORE, ADD, REMOVE }
enum RoadMode { 
	IGNORE,		## 忽略
	ADD, 		## 添加
	REMOVE,		## 移除
}
enum WalledMode { 
	IGNORE,		## 忽略
	ADD, 		## 添加
	REMOVE,		## 移除
}
@export var hex_grid: HexGrid
# 可以在编辑器中编辑颜色
#@export var colors : Dictionary[StringName, Color] = {
	#"红色": Color.RED,
	#"绿色": Color.GREEN,
	#"蓝色": Color.BLUE
#}

#@export var active_color: int = 0 # 默认画笔红色
#@export var disable_color : bool = false
@export var active_terrain_type_index: int = 0
@export var apply_terrain_type_index : bool = true
## 当前海拔等级
@export var active_elevation: int = 0  
@export var disable_elevation : bool = false
@export var brush_radius: int = 0
@export var river_mode: RiverMode = RiverMode.IGNORE
@export var road_mode: RoadMode = RoadMode.IGNORE
@export var active_water_level := 0
@export var disable_water_level : bool = false
## 城镇密度等级（0～3，与 HexCell.urban_level 一致）
@export var active_urban_level: int = 0
## 为 true 时，笔刷点击会写入格子的城镇等级
@export var apply_urban_level: bool = true
@export var active_farm_level: int = 0
@export var apply_farm_level: bool = true
@export var active_plant_level: int = 0
@export var apply_plant_level: bool = true
@export var walled_mode: WalledMode = WalledMode.IGNORE
@export var active_special_index: int = 0
@export var apply_special_index: bool = true

var _previous_cell: HexCell = null
var _is_drag: bool = false
var _drag_direction: HexCell.HexDirection

#signal active_color_changed(color: Color)
#signal color_disable_changed()
signal active_terrain_type_changed(index: int)
signal apply_terrain_type_changed()
signal active_elevation_changed(elevation: int)
signal elevation_disable_changed()
signal brush_radius_changed(radius: int)
signal river_mode_changed(mode: RiverMode)
signal road_mode_changed(mode: RoadMode)
signal water_level_changed(water_level: int)
signal water_disable_chanegd()
signal active_urban_level_changed(level: int)
signal apply_urban_level_changed(enabled: bool)
signal active_farm_level_changed(level: int)
signal apply_farm_level_changed(enabled: bool)
signal active_plant_level_changed(level: int)
signal apply_plant_level_changed(enabled: bool)
signal walled_mode_changed(mode: WalledMode)
signal active_special_index_changed(index: int)
signal apply_special_index_changed(enabled: bool)

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(hex_grid):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 按下时：视为新一次操作，不当作拖拽；只刷当前格（颜色/海拔），河流不生效
			_is_drag = false
			_handle_click_or_drag(event.position, false)
		else:
			_previous_cell = null
			_is_drag = false
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		# 左键按住并移动：才可能算作拖拽，此时再根据 _previous_cell 与当前格判断是否画河
		_handle_click_or_drag(event.position, true)
	# 按 1、2、3 切换颜色
	#elif event is InputEventKey and event.pressed:
		#match event.keycode:
			#KEY_1: active_color = 0
			#KEY_2: active_color = 1
			#KEY_3: active_color = 2
			#KEY_Q: active_elevation -= 1
			#KEY_E: active_elevation += 1

#func set_active_color(color: int) -> void:
	#if active_color == color:
		#return
	#active_color = color
	#active_color_changed.emit(color)
#
#func set_disable_color(disable: bool) -> void:
	#if disable_color == disable:
		#return
	#disable_color = disable
	#color_disable_changed.emit()

func set_terrain_type_index(index: int) -> void:
	if active_terrain_type_index == index:
		return
	active_terrain_type_index = index
	active_terrain_type_changed.emit(index)

func set_apply_terrain_type_index(enabled : bool) -> void:
	if apply_terrain_type_index == enabled:
		return
	apply_terrain_type_index = enabled
	apply_terrain_type_changed.emit()

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

func set_river_mode(mode: int) -> void:
	var m := mode as RiverMode
	if m != RiverMode.IGNORE and road_mode != RoadMode.IGNORE:
		road_mode = RoadMode.IGNORE
		road_mode_changed.emit(road_mode)
	if river_mode == m:
		return
	river_mode = m
	river_mode_changed.emit(river_mode)

func set_road_mode(mode: int) -> void:
	var m := mode as RoadMode
	if m != RoadMode.IGNORE and river_mode != RiverMode.IGNORE:
		river_mode = RiverMode.IGNORE
		river_mode_changed.emit(river_mode)
	if road_mode == m:
		return
	road_mode = m
	road_mode_changed.emit(road_mode)

func set_water_level(water_level: int) -> void:
	if active_water_level == water_level:
		return
	active_water_level = water_level
	water_level_changed.emit(water_level)

func set_disable_water_level(disable: bool) -> void:
	if disable_water_level == disable:
		return
	disable_water_level = disable
	water_disable_chanegd.emit()

func set_active_urban_level(level: int) -> void:
	level = clampi(level, 0, 3)
	if active_urban_level == level:
		return
	active_urban_level = level
	active_urban_level_changed.emit(level)

func set_apply_urban_level(enabled: bool) -> void:
	if apply_urban_level == enabled:
		return
	apply_urban_level = enabled
	apply_urban_level_changed.emit(enabled)

func set_active_farm_level(level: int) -> void:
	level = clampi(level, 0, 3)
	if active_farm_level == level:
		return
	active_farm_level = level
	active_farm_level_changed.emit(level)

func set_apply_farm_level(enabled: bool) -> void:
	if apply_farm_level == enabled:
		return
	apply_farm_level = enabled
	apply_farm_level_changed.emit(enabled)

func set_active_plant_level(level: int) -> void:
	level = clampi(level, 0, 3)
	if active_plant_level == level:
		return
	active_plant_level = level
	active_plant_level_changed.emit(level)

func set_apply_plant_level(enabled: bool) -> void:
	if apply_plant_level == enabled:
		return
	apply_plant_level = enabled
	apply_plant_level_changed.emit(enabled)

func set_walled_mode(mode: int) -> void:
	var m := clampi(mode, 0, 2) as WalledMode
	if walled_mode == m:
		return
	walled_mode = m
	walled_mode_changed.emit(walled_mode)

func set_active_special_index(index: int) -> void:
	index = clampi(index, 0, 3)
	if active_special_index == index:
		return
	active_special_index = index
	active_special_index_changed.emit(index)

func set_apply_special_index(enabled : bool) -> void:
	if apply_special_index == enabled:
		return
	apply_special_index = enabled
	apply_special_index_changed.emit(enabled)

func refresh() -> void:
	hex_grid.refresh()

func save_map() -> void:
	var path := "user://test.map"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: ", path)
		return
	hex_grid.save(file)
	file.close()

func load_map() -> void:
	var path := "user://test.map"
	if not FileAccess.file_exists(path):
		push_warning("Map file not found: ", path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading")
		return

	hex_grid.load(file)
	file.close()

func _handle_click_or_drag(mouse_pos: Vector2, from_motion: bool = false) -> void:
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
	var current_cell : HexCell = hex_grid.get_cell(coords)
	if not is_instance_valid(current_cell):
		#push_error("HexMapEditor: cell is not valid!")
		_previous_cell = null
		_is_drag = false
		return
	
	# 只有“按住左键并移动”时，才把“从上一格拖到当前格”当作拖拽并校验河流方向；单纯点击不触发河流
	if from_motion and _previous_cell != null and _previous_cell != current_cell:
		_validate_drag(current_cell)
	else:
		_is_drag = false
		
	_edit_cells(current_cell)
	_previous_cell = current_cell

func _edit_cells(center: HexCell) -> void:
	if not is_instance_valid(center):
		push_error("HexMapEditor: center is null")
		return

	# 半径 0：只改中心格子
	if brush_radius <= 0:
		_edit_cell(center, center)
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
				_edit_cell(cell, center)

func _edit_cell(cell: HexCell, drag_center: HexCell = null) -> void:
	if not is_instance_valid(cell):
		push_error("HexMapEditor: cell is null")
		return

	match river_mode:
		RiverMode.IGNORE:
			pass
		RiverMode.REMOVE:
			cell.remove_river()
		RiverMode.ADD:
			if _is_drag and _previous_cell != null and cell == drag_center:
				_previous_cell.set_outgoing_river(_drag_direction)

	if road_mode == RoadMode.REMOVE:
		cell.remove_roads()
	elif road_mode == RoadMode.ADD:
		if _is_drag and _previous_cell != null and cell == drag_center:
			var other_cell := cell.get_neighbor(cell.opposite_direction(_drag_direction))
			if other_cell != null:
				other_cell.add_road(_drag_direction)

	#if not disable_color:
		#cell.color = colors.values()[active_color]
	if apply_terrain_type_index:
		cell.terrain_type_index = active_terrain_type_index
	if not disable_elevation:
		cell.elevation = active_elevation
	if not disable_water_level:
		cell.water_level = active_water_level
	if apply_urban_level:
		cell.urban_level = active_urban_level
	if apply_farm_level:
		cell.farm_level = active_farm_level
	if apply_plant_level:
		cell.plant_level = active_plant_level

	if walled_mode != WalledMode.IGNORE:
		cell.walled = walled_mode == WalledMode.ADD

	if apply_special_index:
		cell.special_index = active_special_index

func _validate_drag(current_cell: HexCell) -> void:
	_is_drag = false
	for d in HexCell.HexDirection.values():
		var neighbor := _previous_cell.get_neighbor(d)
		if neighbor == current_cell:
			_is_drag = true
			_drag_direction = d
			return
