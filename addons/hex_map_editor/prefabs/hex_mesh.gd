@tool
extends MeshInstance3D
class_name HexMesh

## 负责将六边形网格三角化，并生成网格实例

@onready var wireframe_mesh: MeshInstance3D = $WireframeMesh

@export var show_wireframe: bool = false
@export var persistent_material: Material
@export var _use_terrain_types: bool = false

var _surface_tool: SurfaceTool = null
var _wireframe_vertices: PackedVector3Array = []

func begin_triangles() -> void:
	_wireframe_vertices.clear()
	if not is_instance_valid(_surface_tool):
		_surface_tool = SurfaceTool.new()
	else:
		_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	if _use_terrain_types: 
		_surface_tool.set_custom_format(0, SurfaceTool.CUSTOM_RGB_FLOAT)

func commit_triangles() -> void:
	_surface_tool.generate_normals()
	mesh = _surface_tool.commit()
	if is_instance_valid(persistent_material) and is_instance_valid(mesh) and mesh.get_surface_count() > 0:
		set_surface_override_material(0, persistent_material)
	if show_wireframe and _wireframe_vertices.size() >= 2:
		_build_wireframe_mesh()
	else:
		_clear_wireframe_mesh()

func add_quad(vertices: PackedVector3Array, colors: PackedColorArray, perturb: bool = true, terrain_idx : Vector3 = Vector3(-1, -1, -1)) -> void:
	add_triangle([vertices[0], vertices[2], vertices[3]], [colors[0], colors[2], colors[3]], perturb, terrain_idx)
	add_triangle([vertices[1], vertices[0], vertices[3]], [colors[1], colors[0], colors[3]], perturb, terrain_idx)

func add_triangle(vertices: PackedVector3Array, colors: PackedColorArray, perturb: bool = true, terrain_idx : Vector3 = Vector3(-1, -1, -1)) -> void:
	var vs : PackedVector3Array
	if perturb:
		for v in vertices:
			vs.append(HexMetrics.perturb(v))
	else:
		vs = vertices
	if _use_terrain_types:
		_surface_tool.set_custom(0, Color(terrain_idx.x, terrain_idx.y, terrain_idx.z, 1.0))
	for i in range(3):
		_surface_tool.set_color(colors[i])
		_surface_tool.add_vertex(vs[i])
		#_wireframe_vertices.append(vertices[i])
	_wireframe_vertices.append(vs[0]); _wireframe_vertices.append(vs[1])
	_wireframe_vertices.append(vs[1]); _wireframe_vertices.append(vs[2])
	_wireframe_vertices.append(vs[2]); _wireframe_vertices.append(vs[0])

func add_quad_uv_rect(vertices: PackedVector3Array, uv_rect: PackedFloat32Array, perturb: bool = true) -> void:
	var uv : PackedVector2Array = [
		Vector2(uv_rect[0], uv_rect[2]),
		Vector2(uv_rect[1], uv_rect[2]),
		Vector2(uv_rect[0], uv_rect[3]),
		Vector2(uv_rect[1], uv_rect[3]),
	]
	add_quad_uv(vertices, uv, perturb)

func add_quad_uv(vertices: PackedVector3Array, uvs: PackedVector2Array = PackedVector2Array(), perturb: bool = true, uvs2: PackedVector2Array = []) -> void:
	add_triangle_uv([vertices[0], vertices[2], vertices[3]], [uvs[0], uvs[2], uvs[3]], perturb, [uvs2[0], uvs2[2], uvs2[3]] if uvs2.size() >= 4 else [])
	add_triangle_uv([vertices[1], vertices[0], vertices[3]], [uvs[1], uvs[0], uvs[3]], perturb, [uvs2[1], uvs2[0], uvs2[3]] if uvs2.size() >= 4 else [])

func add_triangle_uv(vertices: PackedVector3Array, uvs: PackedVector2Array, perturb: bool = true, uvs2: PackedVector2Array = []) -> void:
	var vs : PackedVector3Array
	if perturb:
		for v in vertices:
			vs.append(HexMetrics.perturb(v))
	else:
		vs = vertices
	for i in range(3):
		_surface_tool.set_color(Color.WHITE)
		_surface_tool.set_uv(uvs[i])
		if i < uvs2.size():
			_surface_tool.set_uv2(uvs2[i])
		_surface_tool.add_vertex(vs[i])
		#_wireframe_vertices.append(vertices[i])
	_wireframe_vertices.append(vs[0]); _wireframe_vertices.append(vs[1])
	_wireframe_vertices.append(vs[1]); _wireframe_vertices.append(vs[2])
	_wireframe_vertices.append(vs[2]); _wireframe_vertices.append(vs[0])

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
