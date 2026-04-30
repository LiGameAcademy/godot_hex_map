@tool
extends MeshInstance3D
class_name HexMesh

## 负责将六边形网格三角化，并生成网格实例

@onready var wireframe_mesh: MeshInstance3D = $WireframeMesh

@export var show_wireframe: bool = false

var _surface_tool: SurfaceTool = SurfaceTool.new()
var _wireframe_vertices: PackedVector3Array = []

## 网格三角剖分
func triangulate(cells: Array[HexCell]) -> void:
	_wireframe_vertices.clear()
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cell in cells:
		_triangulate_cell(cell)
	_surface_tool.generate_normals()
	mesh = _surface_tool.commit()

	if show_wireframe and _wireframe_vertices.size() >= 2:
		_build_wireframe_mesh()
	else:
		_clear_wireframe_mesh()

## 三角化单个六边形网格
func _triangulate_cell(cell: HexCell) -> void:
	for i in range(6):
		_triangulate_cell_part(cell, i)

func _triangulate_cell_part(cell: HexCell, direction: int) -> void:
	var center := cell.position
	var v1 := center + HexMetrics.get_first_solid_corner(direction)
	var v2 := center + HexMetrics.get_second_solid_corner(direction)
	
	#var e1 := v1.lerp(v2, 1.0 / 3.0)
	#var e2 := v1.lerp(v2, 2.0 / 3.0)

	#_add_triangle([center, v1, e1], [cell.color, cell.color, cell.color])
	#_add_triangle([center, e1, e2], [cell.color, cell.color, cell.color])
	#_add_triangle([center, e2, v2], [cell.color, cell.color, cell.color])
	var edge := _make_edge(v1, v2)
	_triangulate_fan(center, edge, cell.color)

	#_add_quad([v1, v2, v3, v4], [cell.color, cell.color, bridge_color, bridge_color])
	if direction <= HexCell.HexDirection.SE:
		_triangulate_connection(cell, direction as HexCell.HexDirection, edge)

func _triangulate_connection(cell: HexCell, dir_index: HexCell.HexDirection, edge: PackedVector3Array) -> void:
	var neighbor := cell.get_neighbor(dir_index as HexCell.HexDirection)
	if neighbor == null:
		return
	var bridge := HexMetrics.get_bridge(dir_index)
	bridge.y = neighbor.position.y - cell.position.y
	
	var v3 := edge[0] + bridge
	var v4 := edge[-1] + bridge

	var edge2 := _make_edge(v3, v4)
	if cell.get_edge_type(dir_index as HexCell.HexDirection) == HexMetrics.HexEdgeType.SLOPE:
		_triangulate_edge_terraces(edge, edge2, cell, neighbor)
	else:
		_triangulate_strip(edge, edge2, cell.color, neighbor.color)
	
	var next_dir := cell.next_direction(dir_index)
	var next_neighbor = cell.get_neighbor(next_dir)
	if is_instance_valid(next_neighbor) and dir_index < HexCell.HexDirection.SE:
		var v5 := edge[-1] + HexMetrics.get_bridge(next_dir)
		v5.y = next_neighbor.position.y
		#_add_triangle([v2, v4, v5], [cell.color, neighbor.color, next_neighbor.color])
		if cell.elevation <= neighbor.elevation:
			if cell.elevation <= next_neighbor.elevation:
				_triangulate_corner(edge[-1], v4, v5, cell, neighbor, next_neighbor)
			else:
				_triangulate_corner(v5, edge[-1], v4, next_neighbor, cell, neighbor)
		elif neighbor.elevation <= next_neighbor.elevation:
			_triangulate_corner(v4, v5, edge[-1], neighbor, next_neighbor, cell)
		else:
			_triangulate_corner(v5, edge[-1], v4, next_neighbor, cell, neighbor)

func _triangulate_edge_terraces(edge: PackedVector3Array, edge2: PackedVector3Array, begin_cell: HexCell, end_cell: HexCell) -> void:
	var begin_color := begin_cell.color
	var end_color := end_cell.color

	var e2 := _terrace_lerp_edge(edge, edge2, 1)
	var c2 := HexMetrics.terrace_lerp_color(begin_color, end_color, 1)

	_triangulate_strip(edge, e2, begin_cell.color, c2)
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var e1 := e2
		var c1 = c2
		e2 = _terrace_lerp_edge(edge, edge2, i)
		c2 = HexMetrics.terrace_lerp_color(begin_color, end_color, i)
		_triangulate_strip(e1, e2, c1, c2)
	_triangulate_strip(e2, edge2, c2, end_color)

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
		_add_triangle([bottom_v, left_v, right_v], [bottom_cell.color, left_cell.color, right_cell.color])

func _triangulate_corner_terraces(
		begin_v: Vector3, left_v: Vector3, right_v: Vector3, 
		begin_cell: HexCell, left_cell: HexCell, right_cell: HexCell) -> void:
	var v3 = HexMetrics.terrace_lerp(begin_v, left_v, 1);
	var v4 = HexMetrics.terrace_lerp(begin_v, right_v, 1)
	var c3 = HexMetrics.terrace_lerp_color(begin_cell.color, left_cell.color, 1)
	var c4 = HexMetrics.terrace_lerp_color(begin_cell.color, right_cell.color, 1)

	_add_triangle([begin_v, v3, v4], [begin_cell.color, c3, c4])
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1 = v3; var v2 = v4
		var c1 = c3; var c2 = c4
		v3 = HexMetrics.terrace_lerp(begin_v, left_v, i)
		v4 = HexMetrics.terrace_lerp(begin_v, right_v, i)
		c3 = HexMetrics.terrace_lerp_color(begin_cell.color, left_cell.color, i)
		c4 = HexMetrics.terrace_lerp_color(begin_cell.color, right_cell.color, i)
		_add_quad([v1, v2, v3, v4], [c1, c2, c3, c4])
	_add_quad([v3, v4, left_v, right_v], [c3, c4, left_cell.color, right_cell.color])

func _triangulate_corner_terraces_cliff(
		begin_v: Vector3, left_v: Vector3, right_v: Vector3, 
		begin_cell: HexCell, left_cell: HexCell, right_cell: HexCell) -> void:
	var b : float = absf(1.0 / (right_cell.elevation - begin_cell.elevation))
	var boundary : Vector3 = _perturb(begin_v).lerp(_perturb(right_v), b)
	var boundary_color : Color = begin_cell.color.lerp(right_cell.color, b)
	
	_triangulate_boundary_triangle(begin_v, left_v, boundary, begin_cell.color, left_cell.color, boundary_color)
	if left_cell.get_edge_type_by_cell(right_cell) == HexMetrics.HexEdgeType.SLOPE:
		_triangulate_boundary_triangle(left_v, right_v, boundary, left_cell.color, right_cell.color, boundary_color)
	else:
		#_add_triangle([left_v, right_v, boundary], [left_cell.color, right_cell.color, boundary_color])
		_add_triangle([_perturb(left_v), _perturb(right_v), boundary], [left_cell.color, right_cell.color, boundary_color], false)

func _triangulate_corner_cliff_terraces(
		begin_v: Vector3, left_v: Vector3, right_v: Vector3, 
		begin_cell: HexCell, left_cell: HexCell, right_cell: HexCell) -> void:
	var b : float = abs(1.0 / (left_cell.elevation - begin_cell.elevation))
	var boundary : Vector3 = _perturb(begin_v).lerp(_perturb(left_v), b)
	var boundary_color : Color = begin_cell.color.lerp(left_cell.color, b)
	
	_triangulate_boundary_triangle(right_v, begin_v, boundary, right_cell.color, begin_cell.color, boundary_color)
	if left_cell.get_edge_type_by_cell(right_cell) == HexMetrics.HexEdgeType.SLOPE:
		_triangulate_boundary_triangle(left_v, right_v, boundary, left_cell.color, right_cell.color, boundary_color)
	else:
		_add_triangle([_perturb(left_v), _perturb(right_v), boundary], [left_cell.color, right_cell.color, boundary_color], false)

func _triangulate_boundary_triangle(
		begin_v: Vector3, left_v: Vector3, boundary_v: Vector3, 
		begin_color: Color, left_color: Color, boundary_color: Color) -> void:
	var v2 := HexMetrics.terrace_lerp(begin_v, left_v, 1)
	var c2 := HexMetrics.terrace_lerp_color(begin_color, left_color, 1)
	_add_triangle([_perturb(begin_v), _perturb(v2), boundary_v], [begin_color, c2, boundary_color], false)
	
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1 = v2; var c1 = c2
		v2 = HexMetrics.terrace_lerp(begin_v, left_v, i)
		c2 = HexMetrics.terrace_lerp_color(begin_color, left_color, i)
		_add_triangle([_perturb(v1), _perturb(v2), boundary_v], [c1, c2, boundary_color], false)
	
	_add_triangle([_perturb(v2), _perturb(left_v), boundary_v], [c2, left_color, boundary_color], false)

func _triangulate_fan(center: Vector3, edge: PackedVector3Array, color: Color) -> void:
	var colors := [color, color, color]
	for i in range(edge.size() - 1):
		_add_triangle([center, edge[i], edge[i + 1]], colors)

func _triangulate_strip(from: PackedVector3Array, to: PackedVector3Array, c1: Color, c2: Color) -> void:
	var colors := [c1, c1, c2, c2]
	for i in range(from.size() - 1):
		_add_quad([from[i], from[i + 1], to[i], to[i + 1]], colors)

func _make_edge(a: Vector3, b: Vector3, outer_step: float = 0.25) -> PackedVector3Array:
	var vs : PackedVector3Array
	var count := 1 / outer_step
	for i in range(count):
		vs.append(a.lerp(b, i / (count - 1)))
	return vs

func _terrace_lerp_edge(a: PackedVector3Array, b: PackedVector3Array, step: int) -> PackedVector3Array:
	var o: PackedVector3Array = []
	o.resize(a.size())
	for i in range(a.size()):
		o[i] = HexMetrics.terrace_lerp(a[i], b[i], step)
	return o

func _add_quad(vertices: PackedVector3Array, colors: PackedColorArray, perturb: bool = true) -> void:
	_add_triangle([vertices[0], vertices[2], vertices[3]], [colors[0], colors[2], colors[3]], perturb)
	_add_triangle([vertices[1], vertices[0], vertices[3]], [colors[1], colors[0], colors[3]], perturb)

func _add_triangle(vertices: PackedVector3Array, colors: PackedColorArray, perturb: bool = true) -> void:
	var vs : PackedVector3Array
	if perturb:
		for v in vertices:
			vs.append(_perturb(v))
	else:
		vs = vertices
	for i in range(3):
		_surface_tool.set_color(colors[i])
		_surface_tool.add_vertex(vs[i])
		#_wireframe_vertices.append(vertices[i])
	_wireframe_vertices.append(vs[0]); _wireframe_vertices.append(vs[1])
	_wireframe_vertices.append(vs[1]); _wireframe_vertices.append(vs[2])
	_wireframe_vertices.append(vs[2]); _wireframe_vertices.append(vs[0])

## 使用 HexMetrics 的噪声对顶点进行扰动
func _perturb(p: Vector3) -> Vector3:
	var noise := HexMetrics.sample_noise(p)
	var q := p
	q.x += noise.x * HexMetrics.CELL_PERTURB_STRENGTH
	#q.y += noise.y * HexMetrics.CELL_PERTURB_STRENGTH
	q.z += noise.z * HexMetrics.CELL_PERTURB_STRENGTH
	print("noise: ", noise, " q: ", q)
	return q

func _build_wireframe_mesh() -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _wireframe_vertices
	var wire_mesh := ArrayMesh.new()
	wire_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	if wireframe_mesh == null:
		push_warning("HexMesh: WireframeMesh 节点未配置，跳过线框构建。")
		return
	wireframe_mesh.mesh = wire_mesh
	wireframe_mesh.visible = true

func _clear_wireframe_mesh() -> void:
	if wireframe_mesh == null:
		return
	wireframe_mesh.mesh = null
	wireframe_mesh.visible = false
