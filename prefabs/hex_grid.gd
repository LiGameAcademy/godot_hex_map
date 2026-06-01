@tool
extends Node3D
class_name HexGrid

@export var chunk_prefab: PackedScene = preload("res://prefabs/hex_grid_chunk.tscn")

@export var cell_count_x: int = 20
@export var cell_count_z: int = 15
@export var noise: FastNoiseLite

@export var hash_seed: int = 0
@export var color_config: HexColorConfig

var cells: Array[HexCell] = []
var chunks: Array[HexGridChunk] = []
var chunk_count_x : int
var chunk_count_z : int

func _ready() -> void:
	HexMetrics.noise = noise
	HexMetrics.initialize_hash_grid(hash_seed)
	if is_instance_valid(color_config) and color_config.colors.size() > 0:
		HexMetrics.colors = color_config.colors.duplicate()
	else:
		push_error("color_config is not set")
	create_map(cell_count_x, cell_count_z)
	#cell_count_x = chunk_count_x * HexMetrics.CHUNK_SIZE_X
	#cell_count_z = chunk_count_z * HexMetrics.CHUNK_SIZE_Z

	refresh()

func create_map(x: int, z: int) -> bool:
	if x <= 0 or x % HexMetrics.CHUNK_SIZE_X != 0 or z <= 0 or z % HexMetrics.CHUNK_SIZE_Z != 0:
		push_error("Unsupported map size.")
		return false

	for chunk in chunks:
		chunk.queue_free()
	chunks.clear()
	
	cell_count_x = x
	cell_count_z = z
	chunk_count_x = int(float(cell_count_x) / HexMetrics.CHUNK_SIZE_X)
	chunk_count_z = int(float(cell_count_z) / HexMetrics.CHUNK_SIZE_Z)

	_create_chunks()
	_create_cells()
	
	return true

func get_cell(coords: HexCoordinates) -> HexCell:
	return cells.filter(
		func(c: HexCell) -> bool: return c.coordinates.x == coords.x and c.coordinates.z == coords.z
	).pop_front()
	
func refresh() -> void:
	#hex_mesh.triangulate(cells)
	for chunk in chunks:
		chunk.refresh()

func save(file: FileAccess) -> void:
	for cell in cells:
		cell.save(file)

func load(file: FileAccess, header: int) -> void:
	for cell in cells:
		cell.load(file)
	refresh()

func _create_chunks() -> void:
	chunks.resize(chunk_count_x * chunk_count_z)
	for z in chunk_count_z:
		for x in chunk_count_x:
			var idx := x + z * chunk_count_x
			var chunk := chunk_prefab.instantiate() as HexGridChunk
			chunk.name = "Chunk_%d_%d" % [x, z]
			add_child(chunk)
			chunks[idx] = chunk
	refresh()

func _create_cells() -> void:
	cells.resize(cell_count_x * cell_count_z)
	for z in cell_count_z:
		for x in cell_count_x:
			var i := x + z * cell_count_x
			_create_cell(x, z, i)

func _create_cell(x: int, z: int, index: int) -> void:
	var cell : HexCell = HexCell.new()
	cell.coordinates = HexCoordinates.from_offset(x, z)
	_add_cell_to_chunk(x, z, cell)

	#cell.color = Color.WHITE  # 默认白色，后续可改为可配置的 default_color
	cell.terrain_type_index = 0

	var pos := Vector3.ZERO
	pos.x = (cell.coordinates.x + cell.coordinates.z * 0.5) * (HexMetrics.INNER_RADIUS * 2.0)
	pos.z = cell.coordinates.z * (HexMetrics.OUTER_RADIUS * 1.5)
	cell.position = pos
	cell.label = _create_coordinates_label(cell)
	add_child(cell.label)
	
	# 1. 认领西边 (W) 的邻居
	if x > 0:
		cell.set_neighbor(HexCell.HexDirection.W, cells[index - 1])
	# 2. 认领北边 (NW 和 NE) 的邻居（第一行没有北边邻居）
	if z > 0:
		var i_north := index - cell_count_x
		if z % 2 == 0:
			if x > 0:
				cell.set_neighbor(HexCell.HexDirection.NW, cells[i_north - 1])
			cell.set_neighbor(HexCell.HexDirection.NE, cells[i_north])
		else:
			cell.set_neighbor(HexCell.HexDirection.NW, cells[i_north])
			if x < cell_count_x - 1:
				cell.set_neighbor(HexCell.HexDirection.NE, cells[i_north + 1])
	cells[index] = cell

func _add_cell_to_chunk(x: int, z: int, cell: HexCell) -> void:
	var chunk_x := int(float(x) / HexMetrics.CHUNK_SIZE_X)
	var chunk_z := int(float(z) / HexMetrics.CHUNK_SIZE_Z)
	var chunk_index := chunk_x + chunk_z * chunk_count_x
	var chunk := chunks[chunk_index]

	var local_x := x - chunk_x * HexMetrics.CHUNK_SIZE_X
	var local_z := z - chunk_z * HexMetrics.CHUNK_SIZE_Z
	var local_index := local_x + local_z * HexMetrics.CHUNK_SIZE_X
	chunk.add_cell(local_index, cell)

func _create_coordinates_label(cell: HexCell) -> Label3D:
	var label := Label3D.new()
	label.pixel_size = 0.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = str(cell.coordinates)
	label.position = cell.position
	label.position.y += 1
	label.name = "cell_" + str(cell.coordinates)
	label.set_meta("cell", cell)
	label.hide()
	return label
