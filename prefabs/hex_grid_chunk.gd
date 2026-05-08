@tool
extends Node3D
class_name HexGridChunk

## 本块内的格子（由 HexGrid 通过 add_cell 填入）
var _cells: Array[HexCell] = []

@onready var _terrain_mesh: HexMesh = %TerrainMesh
@onready var _river_mesh: HexMesh = %RiverMesh
@onready var _road_mesh: HexMesh = %RoadMesh
@onready var _water_mesh: HexMesh = %WaterMesh

func _ready() -> void:
	var size := HexMetrics.CHUNK_SIZE_X * HexMetrics.CHUNK_SIZE_Z
	_cells.resize(size)
	# 初始不三角化，等所有格子加入后再统一刷新
	set_process(false)

func _process(_delta: float) -> void:
	#if is_instance_valid(_hex_mesh) and _cells.size() > 0:
		#_hex_mesh.triangulate(_cells)
	if _cells.is_empty():
		return

	if is_instance_valid(_terrain_mesh):
		_terrain_mesh.begin_triangles()
	if is_instance_valid(_river_mesh):
		_river_mesh.begin_triangles()
	if is_instance_valid(_road_mesh):
		_road_mesh.begin_triangles()
	if is_instance_valid(_water_mesh):
		_water_mesh.begin_triangles()

	for cell in _cells:
		if is_instance_valid(cell):
			_triangulate_cell(cell)

	if is_instance_valid(_terrain_mesh):
		_terrain_mesh.commit_triangles()
	if is_instance_valid(_river_mesh):
		_river_mesh.commit_triangles()
	if is_instance_valid(_road_mesh):
		_road_mesh.commit_triangles()
	if is_instance_valid(_water_mesh):
		_water_mesh.commit_triangles()

	set_process(false)

## 将格子加入本块（HexGrid 在 create_cell 后调用）
func add_cell(index: int, cell: HexCell) -> void:
	_cells[index] = cell
	cell.chunk = self

## 标记需要重算网格；实际三角化延迟到 _process，避免一帧内多次刷新同一块
func refresh() -> void:
	set_process(true)

## 三角化单个六边形网格
func _triangulate_cell(cell: HexCell) -> void:
	var center := cell.position
	for i in range(6):
		var direction = i as HexCell.HexDirection
		var corner1 := center + HexMetrics.get_first_solid_corner(direction)
		var corner2 := center + HexMetrics.get_second_solid_corner(direction)
		var edge := _make_edge(corner1, corner2)
		
		if cell.has_river():
			if cell.has_river_through_edge(direction):
				edge[2].y = cell.stream_bed_y
				if cell.has_river_begin_or_end():
					_triangulate_river_begin_or_end(cell, direction, center, edge)
				else:
					_triangulate_with_river(cell, direction, center, edge)
			else:
				_triangulate_adjacent_to_river(cell, direction, center, edge)
		else:
			_triangulate_without_river(cell, direction, center, edge)

		if direction <= HexCell.HexDirection.SE:
			_triangulate_connection(cell, direction, edge)
		
		if cell.is_underwater:
			_triangulate_water(cell, direction, center)

func _triangulate_without_river(cell: HexCell, direction: int, center: Vector3, edge: PackedVector3Array) -> void:
	_triangulate_fan(center, edge, cell.color)

	if cell.has_roads():
		var interpolators := _get_road_interpolators(direction as HexCell.HexDirection, cell)
		var middle_left := center.lerp(edge[0], interpolators.x)
		var middle_right := center.lerp(edge[4], interpolators.y)
		var has_road_through_edge = cell.has_road_through_edge(direction as HexCell.HexDirection)
		_triangulate_road(center, middle_left, middle_right, edge, has_road_through_edge)

#region 地形相关
func _triangulate_connection(cell: HexCell, dir_index: HexCell.HexDirection, edge: PackedVector3Array) -> void:
	var neighbor := cell.get_neighbor(dir_index as HexCell.HexDirection)
	if neighbor == null:
		return
	var bridge := HexMetrics.get_bridge(dir_index)
	bridge.y = neighbor.position.y - cell.position.y
	
	var v3 := edge[0] + bridge
	var v4 := edge[-1] + bridge

	var edge2 := _make_edge(v3, v4)
	
	# 有河时：只压低中间顶点，形成斜壁沟槽
	if cell.has_river_through_edge(dir_index):
		edge[2].y = cell.stream_bed_y
		edge2[2].y = neighbor.stream_bed_y
		# 河流网格
		var reversed: bool = cell.has_incoming_river and cell.incoming_river == (dir_index as HexCell.HexDirection)
		_triangulate_river_quad([edge[1], edge[3], edge2[1], edge2[3]], cell.river_surface_y, neighbor.river_surface_y, 0.8, reversed)

	var has_road := cell.has_road_through_edge(dir_index as HexCell.HexDirection)
	if cell.get_edge_type(dir_index as HexCell.HexDirection) == HexMetrics.HexEdgeType.SLOPE:
		_triangulate_edge_terraces(edge, edge2, cell, neighbor, has_road)
	else:
		_triangulate_strip(edge, edge2, cell.color, neighbor.color, has_road)
	
	var next_dir := cell.next_direction(dir_index)
	var next_neighbor = cell.get_neighbor(next_dir)
	if is_instance_valid(next_neighbor) and dir_index < HexCell.HexDirection.SE:
		var v5 := edge[-1] + HexMetrics.get_bridge(next_dir)
		v5.y = next_neighbor.position.y
		#_terrain_mesh.add_triangle([v2, v4, v5], [cell.color, neighbor.color, next_neighbor.color])
		if cell.elevation <= neighbor.elevation:
			if cell.elevation <= next_neighbor.elevation:
				_triangulate_corner(edge[-1], v4, v5, cell, neighbor, next_neighbor)
			else:
				_triangulate_corner(v5, edge[-1], v4, next_neighbor, cell, neighbor)
		elif neighbor.elevation <= next_neighbor.elevation:
			_triangulate_corner(v4, v5, edge[-1], neighbor, next_neighbor, cell)
		else:
			_triangulate_corner(v5, edge[-1], v4, next_neighbor, cell, neighbor)

func _triangulate_edge_terraces(edge: PackedVector3Array, edge2: PackedVector3Array, begin_cell: HexCell, end_cell: HexCell, has_road: bool) -> void:
	var begin_color := begin_cell.color
	var end_color := end_cell.color

	var e2 := _terrace_lerp_edge(edge, edge2, 1)
	var c2 := HexMetrics.terrace_lerp_color(begin_color, end_color, 1)

	_triangulate_strip(edge, e2, begin_cell.color, c2, has_road)
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var e1 := e2
		var c1 = c2
		e2 = _terrace_lerp_edge(edge, edge2, i)
		c2 = HexMetrics.terrace_lerp_color(begin_color, end_color, i)
		_triangulate_strip(e1, e2, c1, c2, has_road)
	_triangulate_strip(e2, edge2, c2, end_color, has_road)

func _triangulate_corner(
		bottom_v: Vector3, left_v: Vector3, right_v: Vector3, 
		bottom_cell: HexCell, left_cell: HexCell, right_cell: HexCell) -> void:
	var left_edge_type := bottom_cell.get_edge_type_by_cell(left_cell)
	var right_edge_type := bottom_cell.get_edge_type_by_cell(right_cell)
			
	if left_edge_type == HexMetrics.HexEdgeType.SLOPE:
		if right_edge_type == HexMetrics.HexEdgeType.SLOPE:
			_triangulate_corner_terraces(bottom_v, left_v, right_v, bottom_cell, left_cell, right_cell)
		elif right_edge_type == HexMetrics.HexEdgeType.FLAT:
			_triangulate_corner_terraces(left_v, right_v, bottom_v, left_cell, right_cell, bottom_cell)
		else:
			_triangulate_corner_terraces_cliff(bottom_v, left_v, right_v, bottom_cell, left_cell, right_cell)
	elif right_edge_type == HexMetrics.HexEdgeType.SLOPE:
		if left_edge_type == HexMetrics.HexEdgeType.FLAT:
			_triangulate_corner_terraces(right_v, bottom_v, left_v, right_cell, bottom_cell, left_cell)
		else:
			_triangulate_corner_cliff_terraces(bottom_v, left_v, right_v, bottom_cell, left_cell, right_cell)
	elif left_cell.get_edge_type_by_cell(right_cell) == HexMetrics.HexEdgeType.SLOPE:
		if left_cell.elevation <= right_cell.elevation:
			_triangulate_corner_cliff_terraces(right_v, bottom_v, left_v, right_cell, bottom_cell, left_cell)
		else:
			_triangulate_corner_terraces_cliff(left_v, right_v, bottom_v, left_cell, right_cell, bottom_cell)
	else:
		# 涵盖了我们尚未讨论过的所有剩余情况，包括 FFF、CCF、CCCR 和 CCCL。它们都用一个三角形表示
		_terrain_mesh.add_triangle([bottom_v, left_v, right_v], [bottom_cell.color, left_cell.color, right_cell.color])

func _triangulate_corner_terraces(
		begin_v: Vector3, left_v: Vector3, right_v: Vector3, 
		begin_cell: HexCell, left_cell: HexCell, right_cell: HexCell) -> void:
	var v3 = HexMetrics.terrace_lerp(begin_v, left_v, 1);
	var v4 = HexMetrics.terrace_lerp(begin_v, right_v, 1)
	var c3 = HexMetrics.terrace_lerp_color(begin_cell.color, left_cell.color, 1)
	var c4 = HexMetrics.terrace_lerp_color(begin_cell.color, right_cell.color, 1)

	_terrain_mesh.add_triangle([begin_v, v3, v4], [begin_cell.color, c3, c4])
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1 = v3; var v2 = v4
		var c1 = c3; var c2 = c4
		v3 = HexMetrics.terrace_lerp(begin_v, left_v, i)
		v4 = HexMetrics.terrace_lerp(begin_v, right_v, i)
		c3 = HexMetrics.terrace_lerp_color(begin_cell.color, left_cell.color, i)
		c4 = HexMetrics.terrace_lerp_color(begin_cell.color, right_cell.color, i)
		_terrain_mesh.add_quad([v1, v2, v3, v4], [c1, c2, c3, c4])
	_terrain_mesh.add_quad([v3, v4, left_v, right_v], [c3, c4, left_cell.color, right_cell.color])

func _triangulate_corner_terraces_cliff(
		begin_v: Vector3, left_v: Vector3, right_v: Vector3, 
		begin_cell: HexCell, left_cell: HexCell, right_cell: HexCell) -> void:
	var b : float = absf(1.0 / (right_cell.elevation - begin_cell.elevation))
	var boundary : Vector3 = HexMetrics.perturb(begin_v).lerp(HexMetrics.perturb(right_v), b)
	var boundary_color : Color = begin_cell.color.lerp(right_cell.color, b)
	
	_triangulate_boundary_triangle(begin_v, left_v, boundary, begin_cell.color, left_cell.color, boundary_color)
	if left_cell.get_edge_type_by_cell(right_cell) == HexMetrics.HexEdgeType.SLOPE:
		_triangulate_boundary_triangle(left_v, right_v, boundary, left_cell.color, right_cell.color, boundary_color)
	else:
		#_terrain_mesh.add_triangle([left_v, right_v, boundary], [left_cell.color, right_cell.color, boundary_color])
		_terrain_mesh.add_triangle([HexMetrics.perturb(left_v), HexMetrics.perturb(right_v), boundary], [left_cell.color, right_cell.color, boundary_color], false)

func _triangulate_corner_cliff_terraces(
		begin_v: Vector3, left_v: Vector3, right_v: Vector3, 
		begin_cell: HexCell, left_cell: HexCell, right_cell: HexCell) -> void:
	var b : float = abs(1.0 / (left_cell.elevation - begin_cell.elevation))
	var boundary : Vector3 = HexMetrics.perturb(begin_v).lerp(HexMetrics.perturb(left_v), b)
	var boundary_color : Color = begin_cell.color.lerp(left_cell.color, b)
	
	_triangulate_boundary_triangle(right_v, begin_v, boundary, right_cell.color, begin_cell.color, boundary_color)
	if left_cell.get_edge_type_by_cell(right_cell) == HexMetrics.HexEdgeType.SLOPE:
		_triangulate_boundary_triangle(left_v, right_v, boundary, left_cell.color, right_cell.color, boundary_color)
	else:
		_terrain_mesh.add_triangle([HexMetrics.perturb(left_v), HexMetrics.perturb(right_v), boundary], [left_cell.color, right_cell.color, boundary_color], false)

func _triangulate_boundary_triangle(
		begin_v: Vector3, left_v: Vector3, boundary_v: Vector3, 
		begin_color: Color, left_color: Color, boundary_color: Color) -> void:
	var v2 := HexMetrics.terrace_lerp(begin_v, left_v, 1)
	var c2 := HexMetrics.terrace_lerp_color(begin_color, left_color, 1)
	_terrain_mesh.add_triangle([HexMetrics.perturb(begin_v), HexMetrics.perturb(v2), boundary_v], [begin_color, c2, boundary_color], false)
	
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1 = v2; var c1 = c2
		v2 = HexMetrics.terrace_lerp(begin_v, left_v, i)
		c2 = HexMetrics.terrace_lerp_color(begin_color, left_color, i)
		_terrain_mesh.add_triangle([HexMetrics.perturb(v1), HexMetrics.perturb(v2), boundary_v], [c1, c2, boundary_color], false)
	
	_terrain_mesh.add_triangle([HexMetrics.perturb(v2), HexMetrics.perturb(left_v), boundary_v], [c2, left_color, boundary_color], false)

#endregion

#region 河流相关
func _triangulate_with_river(cell: HexCell, direction: int, center: Vector3, edge: PackedVector3Array) -> void:
	var opposite_direction := cell.opposite_direction(direction)
	var next_direction := cell.next_direction(direction)
	var previous_direction := cell.previous_direction(direction)

	var center_left : Vector3; var center_right : Vector3

	if cell.has_river_through_edge(opposite_direction):
		# 直河
		center_left = center + HexMetrics.get_first_solid_corner(cell.previous_direction(direction)) * 0.25
		center_right = center + HexMetrics.get_second_solid_corner(cell.next_direction(direction)) * 0.25
	elif cell.has_river_through_edge(next_direction):
		center_left = center
		center_right = center.lerp(edge[4], 2.0 / 3.0)
	elif cell.has_river_through_edge(previous_direction):
		center_left = center.lerp(edge[0], 2.0 / 3.0)
		center_right = center
	elif cell.has_river_through_edge(cell.next2_direction(direction)):
		# 钝角
		center_left = center
		center_right = center + HexMetrics.get_solid_edge_middle(next_direction) * (HexMetrics.INNER_TO_OUTER * 0.5)
	elif cell.has_river_through_edge(cell.previous2_direction(direction)):
		# 钝角
		center_left = center + HexMetrics.get_solid_edge_middle(previous_direction) * (HexMetrics.INNER_TO_OUTER * 0.5)
		center_right = center
	else:
		center_left = center
		center_right = center
	center = center_left.lerp(center_right, 0.5)

	var m1 : Vector3 = center_left.lerp(edge[0], 0.5)
	var m2 : Vector3 = center_right.lerp(edge[-1], 0.5)
	var ms : PackedVector3Array = _make_edge(m1, m2, 1.0 / 6.0)
	center.y = cell.stream_bed_y
	ms[2].y = cell.stream_bed_y

	_triangulate_strip(ms, edge, cell.color, cell.color)

	_terrain_mesh.add_triangle([center_left, ms[0], ms[1]], [cell.color, cell.color, cell.color])
	_terrain_mesh.add_triangle([center_right, ms[3], ms[4]], [cell.color, cell.color, cell.color])
	_terrain_mesh.add_quad([center_left, center, ms[1], ms[2]], [cell.color, cell.color, cell.color, cell.color])
	_terrain_mesh.add_quad([center, center_right, ms[2], ms[3]], [cell.color, cell.color, cell.color, cell.color])

	var reversed: bool = cell.incoming_river == direction
	_triangulate_river_quad([center_left, center_right, ms[1], ms[3]], cell.river_surface_y, cell.river_surface_y, 0.4, reversed)
	_triangulate_river_quad([ms[1], ms[3], edge[1], edge[3]], cell.river_surface_y, cell.river_surface_y, 0.6, reversed)

func _triangulate_river_begin_or_end(cell: HexCell, _direction: int, center: Vector3, edge: PackedVector3Array) -> void:
	var ms := _make_edge(center.lerp(edge[0], 0.5), center.lerp(edge[-1], 0.5))
	ms[2].y = edge[2].y
	_triangulate_strip(ms, edge, cell.color, cell.color)
	_triangulate_fan(center, ms, cell.color)

	var reversed: bool = cell.has_incoming_river
	_triangulate_river_quad([ms[1], ms[3], edge[1], edge[3]], cell.river_surface_y, cell.river_surface_y, 0.6, reversed)
	var river_center: Vector3 = center
	river_center.y = cell.river_surface_y
	var river_left := ms[1] ; var river_right := ms[3]
	river_left.y = cell.river_surface_y ; river_right.y = cell.river_surface_y 
	
	var uvs: PackedVector2Array = [Vector2(0.5, 0.4), Vector2(0.0, 0.6), Vector2(1.0, 0.6)]
	if reversed:
		uvs = [Vector2(0.5, 0.4), Vector2(1.0, 0.2), Vector2(0.0, 0.2)]
	_river_mesh.add_triangle_uv([river_center, river_left, river_right], uvs)

func _triangulate_adjacent_to_river(cell: HexCell, direction: HexCell.HexDirection, center: Vector3, edge: Array[Vector3]) -> void:
	if cell.has_roads():
		_triangulate_road_adjacent_to_river(cell, direction, center, edge)
		
	var next_direction := cell.next_direction(direction)
	var previous_direction := cell.previous_direction(direction)
	if cell.has_river_through_edge(next_direction):
		if cell.has_river_through_edge(previous_direction):
			center += HexMetrics.get_solid_edge_middle(direction) * (0.5 * HexMetrics.INNER_TO_OUTER)
		elif cell.has_river_through_edge(cell.previous2_direction(direction)):
			center += HexMetrics.get_first_solid_corner(direction) * 0.25
	elif cell.has_river_through_edge(previous_direction) and cell.has_river_through_edge(cell.next2_direction(direction)):
			center += HexMetrics.get_second_solid_corner(direction) * 0.25
	var ms := _make_edge(center.lerp(edge[0], 0.5), center.lerp(edge[-1], 0.5))
	_triangulate_strip(ms, edge, cell.color, cell.color)
	_triangulate_fan(center, ms, cell.color)

func _triangulate_river_quad(vertices: PackedVector3Array, y1: float, y2: float, v_anchor: float, reversed: bool = false) -> void:
	var vs: PackedVector3Array = vertices.duplicate()
	for i in range(vs.size()):
		vs[i].y = y1 if i <= 1 else y2
	var uv_rect : PackedFloat32Array = [0.0, 1.0, v_anchor, v_anchor + 0.2]
	if reversed:
		uv_rect = [1.0, 0.0, 0.8 - v_anchor, 0.6 - v_anchor]
	_river_mesh.add_quad_uv_rect(vs, uv_rect)
#endregion

#region 道路相关
func _triangulate_road(center: Vector3, middle_left: Vector3, middle_right: Vector3, edge: PackedVector3Array, has_road_through_edge: bool) -> void:
	if has_road_through_edge:
		var middle_center = middle_left.lerp(middle_right, 0.5)
		_triangulate_road_quad([middle_left, middle_center, middle_right, edge[1], edge[2], edge[3]])
		# 补齐剩余两个三角形
		_road_mesh.add_triangle_uv([center, middle_left, middle_center], [Vector2(1.0, 0.0), Vector2(0.0, 0.0), Vector2(1.0, 0.0)])
		_road_mesh.add_triangle_uv([center, middle_center, middle_right], [Vector2(1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 0.0)])
	else:
		_triangulate_road_edge(center, middle_left, middle_right)

func _triangulate_road_edge(center: Vector3, middle_left: Vector3, middle_right: Vector3) -> void:
	_road_mesh.add_triangle_uv([center, middle_left, middle_right], [Vector2(1.0, 0.0), Vector2(0.0, 0.0), Vector2(0.0, 0.0)])

func _triangulate_road_quad(vertices: PackedVector3Array) -> void:
	_road_mesh.add_quad_uv_rect([vertices[0], vertices[1], vertices[3], vertices[4]], [0.0, 1.0, 0.0, 0.0])
	_road_mesh.add_quad_uv_rect([vertices[1], vertices[2], vertices[4], vertices[5]], [1.0, 0.0, 0.0, 0.0])

func _get_road_interpolators(direction: HexCell.HexDirection, cell: HexCell) -> Vector2:
	var interpolators: Vector2 = Vector2(0.0, 0.0)
	if cell.has_road_through_edge(direction):
		interpolators.x = 0.5
		interpolators.y = 0.5
	else:
		interpolators.x = 0.5 if cell.has_road_through_edge(cell.previous_direction(direction)) else 0.25
		interpolators.y = 0.5 if cell.has_road_through_edge(cell.next_direction(direction)) else 0.25
	return interpolators

func _triangulate_road_adjacent_to_river(cell: HexCell, direction: HexCell.HexDirection, center: Vector3, edge: PackedVector3Array) -> void:
	var has_road_through_edge = cell.has_road_through_edge(direction as HexCell.HexDirection)
	var interpolators = _get_road_interpolators(direction as HexCell.HexDirection, cell)
	var road_center := center

	var previous_has_river := cell.has_river_through_edge(cell.previous_direction(direction as HexCell.HexDirection))
	var next_has_river := cell.has_river_through_edge(cell.next_direction(direction as HexCell.HexDirection))

	if cell.has_river_begin_or_end():
		var opposite_direction = cell.opposite_direction(cell.river_enter_or_exit_direction)
		road_center += HexMetrics.get_solid_edge_middle(opposite_direction) * (1.0 / 3.0)
	elif cell.incoming_river == cell.opposite_direction(cell.outgoing_river):
		# 直河
		var corner: Vector3 = Vector3.ZERO
		if previous_has_river:
			if not has_road_through_edge and not cell.has_road_through_edge(cell.next_direction(direction as HexCell.HexDirection)):
				return
			corner = HexMetrics.get_second_solid_corner(direction as HexCell.HexDirection)
		else:
			if not has_road_through_edge and not cell.has_road_through_edge(cell.previous_direction(direction as HexCell.HexDirection)):
				return
			corner = HexMetrics.get_first_solid_corner(direction as HexCell.HexDirection)
		road_center += corner * 0.5
		center += corner * 0.25
	# 锐角弯河道
	elif cell.incoming_river == cell.previous_direction(cell.outgoing_river):
		road_center -= HexMetrics.get_second_corner(cell.incoming_river) * 0.2
	elif cell.incoming_river == cell.next_direction(cell.outgoing_river):
		road_center -= HexMetrics.get_first_corner(cell.incoming_river) * 0.2
	elif previous_has_river and next_has_river:
		# 钝角弯内侧
		if not has_road_through_edge:
			# 移除孤立的道路路段
			return
		var offset := HexMetrics.get_solid_edge_middle(direction) * HexMetrics.INNER_TO_OUTER
		road_center += offset * 0.7
		center += offset * 0.5
	else:
		# 钝角弯外侧
		var middle_direction : HexCell.HexDirection = direction as HexCell.HexDirection
		if previous_has_river:
			middle_direction = cell.next_direction(direction as HexCell.HexDirection)
		elif next_has_river:
			middle_direction = cell.previous_direction(direction as HexCell.HexDirection)
		var middle_previous_direction := cell.previous_direction(middle_direction)
		var middle_next_direction := cell.next_direction(middle_direction)
		if not cell.has_road_through_edge(middle_direction) and not cell.has_road_through_edge(middle_previous_direction) and not cell.has_road_through_edge(middle_next_direction):
			return
		road_center += HexMetrics.get_solid_edge_middle(middle_direction) * 0.25
		center += HexMetrics.get_solid_edge_middle(middle_direction) * 0.25

	var middle_left := road_center.lerp(edge[0], interpolators.x)
	var middle_right := road_center.lerp(edge[4], interpolators.y)
	_triangulate_road(road_center, middle_left, middle_right, edge, has_road_through_edge)

	if cell.has_river_through_edge(cell.previous_direction(direction as HexCell.HexDirection)):
		_triangulate_road_edge(road_center, center, middle_left)
	if cell.has_river_through_edge(cell.next_direction(direction as HexCell.HexDirection)):
		_triangulate_road_edge(road_center, middle_right, center)

#endregion

func _triangulate_water(cell: HexCell, direction: int, center: Vector3) -> void:
	var water_center := center
	water_center.y = cell.water_surface_y
	var v1 := water_center + HexMetrics.get_first_solid_corner(direction)
	var v2 := water_center + HexMetrics.get_second_solid_corner(direction)
	_water_mesh.add_triangle([center, v1, v2], [Color.WHITE, Color.WHITE, Color.WHITE])

	if direction <= HexCell.HexDirection.SE:
		var neighbor := cell.get_neighbor(direction)
		if neighbor == null or not neighbor.is_underwater:
			return
		var bridge := HexMetrics.get_bridge(direction)
		var e1 := v1 + bridge
		var e2 := v2 + bridge
		_water_mesh.add_quad([v1, v2, e1, e2], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
		if direction < HexCell.HexDirection.SE:
			var next_direction := cell.next_direction(direction)
			var next_neighbor := cell.get_neighbor(next_direction)
			if next_neighbor == null or not next_neighbor.is_underwater:
				return
			_water_mesh.add_triangle([v2, e2, v2 + HexMetrics.get_bridge(next_direction)], [Color.WHITE, Color.WHITE, Color.WHITE])

func _triangulate_fan(center: Vector3, edge: PackedVector3Array, color: Color) -> void:
	var colors := [color, color, color]
	for i in range(edge.size() - 1):
		_terrain_mesh.add_triangle([center, edge[i], edge[i + 1]], colors)

func _triangulate_strip(from: PackedVector3Array, to: PackedVector3Array, c1: Color, c2: Color, has_road: bool = false) -> void:
	var colors := [c1, c1, c2, c2]
	for i in range(from.size() - 1):
		_terrain_mesh.add_quad([from[i], from[i + 1], to[i], to[i + 1]], colors)
	if has_road:
		_triangulate_road_quad([from[1], from[2], from[3], to[1], to[2], to[3]])

func _make_edge(a: Vector3, b: Vector3, outer_step: float = 0.25) -> PackedVector3Array:
	var vs : PackedVector3Array = [
		a,
		a.lerp(b, outer_step),
		a.lerp(b, 0.5),
		a.lerp(b, (1 - outer_step)),
		b
	]
	return vs

func _terrace_lerp_edge(a: PackedVector3Array, b: PackedVector3Array, step: int) -> PackedVector3Array:
	var o: PackedVector3Array = []
	o.resize(a.size())
	for i in range(a.size()):
		o[i] = HexMetrics.terrace_lerp(a[i], b[i], step)
	return o
