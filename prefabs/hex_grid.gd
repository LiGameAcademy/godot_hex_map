@tool
extends Node3D
class_name HexGrid

@export var chunk_prefab: PackedScene = preload("res://prefabs/hex_grid_chunk.tscn")
@export var chunk_count_x := 4
@export var chunk_count_z := 3
@export var noise: FastNoiseLite

var cells: Array[HexCell] = []
var chunks: Array[HexGridChunk] = []

#var width := 6
#var height := 6
var cell_count_x: int
var cell_count_z: int

func _ready() -> void:
	HexMetrics.noise = noise

	cell_count_x = chunk_count_x * HexMetrics.CHUNK_SIZE_X
	cell_count_z = chunk_count_z * HexMetrics.CHUNK_SIZE_Z

	_create_chunks()
	_create_cells()

func get_cell(coords: HexCoordinates) -> HexCell:
	return cells.filter(
		func(c: HexCell) -> bool: return c.coordinates.x == coords.x and c.coordinates.z == coords.z
	).pop_front()
	
func refresh() -> void:
	#hex_mesh.triangulate(cells)
	for chunk in chunks:
		chunk.refresh()

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

	cell.color = Color.WHITE  # 默认白色，后续可改为可配置的 default_color
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
