extends Node3D
class_name HexGrid

@export var width := 6
@export var height := 6

@onready var hex_mesh: MeshInstance3D = $HexMesh

var cells: Array[HexCell] = []

func create_cell(x: int, z: int) -> void:
	var cell : HexCell = HexCell.new()
	cell.coordinates = HexCoordinates.from_offset(x, z)
	cell.color = Color.WHITE  # 默认白色，后续可改为可配置的 default_color
	var pos := Vector3.ZERO
	pos.x = (cell.coordinates.x + cell.coordinates.z * 0.5) * (HexMetrics.INNER_RADIUS * 2.0)
	pos.z = cell.coordinates.z * (HexMetrics.OUTER_RADIUS * 1.5)
	cell.position = pos
	cells.append(cell)
	add_child(cell.label)

func get_cell(coords: HexCoordinates) -> HexCell:
	return cells.filter(
		func(c: HexCell) -> bool: return c.coordinates.x == coords.x and c.coordinates.z == coords.z
	).pop_front()
