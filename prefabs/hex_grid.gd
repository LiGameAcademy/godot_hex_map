extends Node3D
class_name HexGrid

@export var width := 6
@export var height := 6

@onready var hex_mesh: MeshInstance3D = $HexMesh

var cells: Array[HexCell] = []

func _ready() -> void:
	for z in height:
		for x in width:
			create_cell(x, z)
	hex_mesh.triangulate(cells)

func create_cell(x: int, z: int) -> void:
	var cell : HexCell = HexCell.new()
	cell.coordinates = HexCoordinates.from_offset(x, z)
	cell.color = Color.WHITE  # 默认白色，后续可改为可配置的 default_color
	var pos := Vector3.ZERO
	pos.x = (cell.coordinates.x + cell.coordinates.z * 0.5) * (HexMetrics.INNER_RADIUS * 2.0)
	pos.z = cell.coordinates.z * (HexMetrics.OUTER_RADIUS * 1.5)
	cell.position = pos
	cell.label = _create_coordinates_label(cell)
	cells.append(cell)
	add_child(cell.label)

func get_cell(coords: HexCoordinates) -> HexCell:
	return cells.filter(
		func(c: HexCell) -> bool: return c.coordinates.x == coords.x and c.coordinates.z == coords.z
	).pop_front()

func _create_coordinates_label(cell: HexCell) -> Label3D:
	var label := Label3D.new()
	label.pixel_size = 0.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = str(cell.coordinates)
	label.position = cell.position
	label.position.y += 1
	label.name = "cell_" + str(cell.coordinates)
	return label
