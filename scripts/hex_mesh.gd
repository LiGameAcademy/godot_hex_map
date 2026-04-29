extends MeshInstance3D
class_name HexMesh

## 负责将六边形网格三角化，并生成网格实例

var _surface_tool: SurfaceTool = SurfaceTool.new()

## 网格三角剖分
func triangulate(cells: Array[HexCell]) -> void:
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cell in cells:
		_triangulate_cell(cell)
	_surface_tool.generate_normals()
	mesh = _surface_tool.commit()

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
