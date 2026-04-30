extends Node3D
class_name HexGridChunk

## 本块内的格子（由 HexGrid 通过 add_cell 填入）
var _cells: Array[HexCell] = []

@onready var _hex_mesh: HexMesh = $HexMesh

func _ready() -> void:
	var size := HexMetrics.CHUNK_SIZE_X * HexMetrics.CHUNK_SIZE_Z
	_cells.resize(size)
	# 初始不三角化，等所有格子加入后再统一刷新
	set_process(false)

func _process(_delta: float) -> void:
	if is_instance_valid(_hex_mesh) and _cells.size() > 0:
		_hex_mesh.triangulate(_cells)
	set_process(false)

## 将格子加入本块（HexGrid 在 create_cell 后调用）
func add_cell(index: int, cell: HexCell) -> void:
	_cells[index] = cell
	cell.chunk = self

## 标记需要重算网格；实际三角化延迟到 _process，避免一帧内多次刷新同一块
func refresh() -> void:
	set_process(true)
