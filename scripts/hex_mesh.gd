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
	_add_triangle([center, v1, v2], [cell.color, cell.color, cell.color])

	#_add_quad([v1, v2, v3, v4], [cell.color, cell.color, bridge_color, bridge_color])
	if direction <= HexCell.HexDirection.SE:
		_triangulate_connection(cell, direction as HexCell.HexDirection, v1, v2)

func _triangulate_connection(cell: HexCell, dir_index: HexCell.HexDirection, v1: Vector3, v2: Vector3) -> void:
	var neighbor := cell.get_neighbor(dir_index as HexCell.HexDirection)
	if neighbor == null:
		#neighbor = cell
		return
	var bridge := HexMetrics.get_bridge(dir_index)
	var v3 := v1 + bridge
	var v4 := v2 + bridge
	v3.y = neighbor.position.y ; v4.y = v3.y

	#_add_quad([v1, v2, v3, v4], [cell.color, cell.color, neighbor.color, neighbor.color])
	_triangulate_edge_terraces([v1, v2, v3, v4], cell, neighbor)
	
	var next_dir := cell.next_direction(dir_index)
	var next_neighbor = cell.get_neighbor(next_dir)
	if is_instance_valid(next_neighbor) and dir_index < HexCell.HexDirection.SE:
		var v5 := v2 + HexMetrics.get_bridge(next_dir)
		v5.y = next_neighbor.position.y
		_add_triangle([v2, v4, v5], [cell.color, neighbor.color, next_neighbor.color])

func _triangulate_edge_terraces(vertices: PackedVector3Array, begin_cell: HexCell, end_cell: HexCell) -> void:
	var begin_color := begin_cell.color
	var end_color := end_cell.color

	var v3 := HexMetrics.terrace_lerp(vertices[0], vertices[2], 1)
	var v4 := HexMetrics.terrace_lerp(vertices[1], vertices[3], 1)
	var c2 := HexMetrics.terrace_lerp_color(begin_color, end_color, 1)

	_add_quad([vertices[0], vertices[1], v3, v4], [begin_color, begin_color, c2, c2])
	for i in range(2, HexMetrics.TERRACE_STEPS):
		var v1 = v3
		var v2 = v4
		var c1 = c2
		v3 = HexMetrics.terrace_lerp(vertices[0], vertices[2], i)
		v4 = HexMetrics.terrace_lerp(vertices[1], vertices[3], i)
		c2 = HexMetrics.terrace_lerp_color(begin_cell.color, end_cell.color, i)
		_add_quad([v1, v2, v3, v4], [c1, c1, c2, c2])
	_add_quad([v3, v4, vertices[2], vertices[3]], [c2, c2, end_color, end_color])

func _add_triangle(vertices: PackedVector3Array, colors: PackedColorArray) -> void:
	for i in range(3):
		_surface_tool.set_color(colors[i])
		_surface_tool.add_vertex(vertices[i])
		#_wireframe_vertices.append(vertices[i])
	_wireframe_vertices.append(vertices[0]); _wireframe_vertices.append(vertices[1])
	_wireframe_vertices.append(vertices[1]); _wireframe_vertices.append(vertices[2])
	_wireframe_vertices.append(vertices[2]); _wireframe_vertices.append(vertices[0])

func _add_quad(vertices: PackedVector3Array, colors: PackedColorArray) -> void:
	_add_triangle([vertices[0], vertices[2], vertices[3]], [colors[0], colors[2], colors[3]])
	_add_triangle([vertices[1], vertices[0], vertices[3]], [colors[1], colors[0], colors[3]])

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
