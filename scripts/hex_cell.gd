extends RefCounted
class_name HexCell

## 六边形网格（逻辑层）

enum HexDirection { NE, E, SE, SW, W, NW }

# 逻辑坐标（立方体坐标）
var coordinates: HexCoordinates
var position : Vector3
var label : Label3D

var neighbors: Array[HexCell] = [null, null, null, null, null, null]

## 颜色，用于整张 Mesh 的顶点色
var color: Color = Color.WHITE:
	set(value):
		color = value
		_refresh()
## 海拔高度
var elevation : int = 0:
	set(value):
		elevation = value
		var base_y := float(elevation) * HexMetrics.ELEVATION_STEP
		var n := HexMetrics.sample_noise(position)
		base_y += n.y * HexMetrics.ELEVATION_PERTURB_STRENGTH
		position.y = base_y
		_refresh()

var chunk : HexGridChunk

## 获取邻居
func get_neighbor(direction: HexDirection) -> HexCell:
	return neighbors[direction]
	
## 获取上一个邻居
func get_previous_neighbor(direction: HexDirection) -> HexCell:
	return get_neighbor(previous_direction(direction))

## 获取下一个邻居
func get_next_neighbor(direction: HexDirection) -> HexCell:
	return get_neighbor(next_direction(direction))

## 设置邻居
func set_neighbor(direction: HexDirection, cell: HexCell) -> void:
	neighbors[direction] = cell
	# 互相认识：如果我认你做东边邻居，你也要认我做相反方向的邻居
	cell.neighbors[opposite_direction(direction)] = self

## 获取相反方向
func opposite_direction(direction: HexDirection) -> HexDirection:
	return (direction + 3) % 6 as HexDirection

## 下一个方向
func next_direction(direction: HexDirection) -> HexDirection:
	return (direction + 1) % 6 as HexDirection

## 上一个方向
func previous_direction(direction: HexDirection) -> HexDirection:
	return (direction - 1) % 6 as HexDirection

func get_edge_type(direction: HexDirection) -> HexMetrics.HexEdgeType:
	var neighbor = get_neighbor(direction)
	if neighbor == null:
		return HexMetrics.HexEdgeType.FLAT
	return HexMetrics.get_edge_type(elevation, neighbor.elevation)

func get_edge_type_by_cell(other_cell: HexCell) -> HexMetrics.HexEdgeType:
	if not is_instance_valid(other_cell):
		return HexMetrics.HexEdgeType.FLAT
	return HexMetrics.get_edge_type(elevation, other_cell.elevation)

func _refresh() -> void:
	if not is_instance_valid(chunk):
		push_error("HexCell: chunk is not valid")
		return

	# 1. 刷新自己所在的 Chunk
	chunk.refresh()

	# 2. 如果边在 Chunk 之间共享，再顺带刷新相邻 Chunk
	for neighbor in neighbors:
		if neighbor == null:
			continue
		if neighbor.chunk != chunk and is_instance_valid(neighbor.chunk):
			neighbor.chunk.refresh()
