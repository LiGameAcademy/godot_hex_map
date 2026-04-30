@tool
extends Node3D
class_name HexGrid

@export var width := 6
@export var height := 6
@export var noise: FastNoiseLite

@onready var hex_mesh: MeshInstance3D = $HexMesh

var cells: Array[HexCell] = []

func _ready() -> void:
	HexMetrics.noise = noise

	for z in height:
		for x in width:
			create_cell(x, z)
	hex_mesh.triangulate(cells)
	#print(cells[0].coordinates)
	#for i in range(6):
		#var neighbor := cells[0].get_neighbor(i)
		#print(neighbor.coordinates if is_instance_valid(neighbor) else null)

func create_cell(x: int, z: int) -> void:
	var cell : HexCell = HexCell.new()
	cell.coordinates = HexCoordinates.from_offset(x, z)
	cell.color = Color.WHITE  # 默认白色，后续可改为可配置的 default_color
	var pos := Vector3.ZERO
	pos.x = (cell.coordinates.x + cell.coordinates.z * 0.5) * (HexMetrics.INNER_RADIUS * 2.0)
	pos.z = cell.coordinates.z * (HexMetrics.OUTER_RADIUS * 1.5)
	cell.position = pos
	cell.label = _create_coordinates_label(cell)
	add_child(cell.label)
	
	# 1. 认领西边 (W) 的邻居
	if x > 0:
		cell.set_neighbor(HexCell.HexDirection.W, cells[cells.size() - 1])
	# 2. 认领北边 (NW 和 NE) 的邻居（第一行没有北边邻居）
	if z > 0:
		if z % 2 == 0:
			if x > 0:
				cell.set_neighbor(HexCell.HexDirection.NW, cells[cells.size() - width - 1])
			cell.set_neighbor(HexCell.HexDirection.NE, cells[cells.size() - width])
		else:
			cell.set_neighbor(HexCell.HexDirection.NW, cells[cells.size() - width])
			if x < width - 1:
				cell.set_neighbor(HexCell.HexDirection.NE, cells[cells.size() - width + 1])
	cells.append(cell)
	cell.elevation = 0

func get_cell(coords: HexCoordinates) -> HexCell:
	return cells.filter(
		func(c: HexCell) -> bool: return c.coordinates.x == coords.x and c.coordinates.z == coords.z
	).pop_front()
	
func refresh() -> void:
	hex_mesh.triangulate(cells)

func _create_coordinates_label(cell: HexCell) -> Label3D:
	var label := Label3D.new()
	label.pixel_size = 0.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = str(cell.coordinates)
	label.position = cell.position
	label.position.y += 1
	label.name = "cell_" + str(cell.coordinates)
	label.set_meta("cell", cell)
	return label
