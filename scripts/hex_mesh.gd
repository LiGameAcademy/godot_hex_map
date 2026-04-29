extends MeshInstance3D
class_name HexMesh

## 负责将六边形网格三角化，并生成网格实例

@onready var wireframe_mesh: MeshInstance3D = $WireframeMesh

@export var show_wireframe: bool = false

var _surface_tool: SurfaceTool = SurfaceTool.new()
var _wireframe_vertices: PackedVector3Array = []

## 网格三角剖分
func triangulate(cells: Array[HexCell]) -> void:
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
	var v1 := center + HexMetrics.CORNERS[direction + 1]
	var v2 := center + HexMetrics.CORNERS[direction]
	_add_triangle([center, v1, v2], [cell.color, cell.color, cell.color])

func _add_triangle(vertices: PackedVector3Array, colors: PackedColorArray) -> void:
	for i in range(3):
		_surface_tool.set_color(colors[i])
		_surface_tool.add_vertex(vertices[i])
		_wireframe_vertices.append(vertices[i])

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
