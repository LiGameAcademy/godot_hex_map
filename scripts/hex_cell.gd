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
		_validate_river_constraints()
		_refresh()

## 河流状态：是否有河流流入 / 流出当前格子
var has_incoming_river: bool = false
var has_outgoing_river: bool = false

## 入河 / 出河方向（沿着六边形 6 个方向之一）
var incoming_river: HexDirection
var outgoing_river: HexDirection

var chunk : HexGridChunk

#region 邻居海拔
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

#endregion

#region 河流相关
func set_outgoing_river(direction: HexDirection) -> void:
	# 1. 如果本来就有同向的 outgoing river，没必要重复设置
	if has_outgoing_river and outgoing_river == direction:
		return
	var neighbor := get_neighbor(direction)
	if neighbor == null:
		return
	# 2. 河流只能往低处流（允许平流，禁止往高处）
	if elevation < neighbor.elevation:
		return
	# 3. 清理旧的 outgoing / 重叠的 incoming
	remove_outgoing_river()
	if has_incoming_river and incoming_river == direction:
		remove_incoming_river()

	# 4. 设置新的 outgoing / 对应邻居的 incoming
	has_outgoing_river = true
	outgoing_river = direction
	_refresh()

	neighbor.remove_incoming_river()
	neighbor.has_incoming_river = true
	neighbor.incoming_river = opposite_direction(direction)
	neighbor.refresh()

## 移除出河
func remove_outgoing_river() -> void:
	if not has_outgoing_river:
		return
	has_outgoing_river = false
	_refresh()

	var neighbor := get_neighbor(outgoing_river)
	if neighbor == null:
		return
	if not neighbor.has_incoming_river:
		return
	if neighbor.incoming_river != opposite_direction(outgoing_river):
		return
	neighbor.has_incoming_river = false
	neighbor.refresh()

## 移除入河
func remove_incoming_river() -> void:
	if not has_incoming_river:
		return
	has_incoming_river = false
	_refresh()
	var neighbor := get_neighbor(incoming_river)
	if neighbor == null:
		return
	if not neighbor.has_outgoing_river:
		return
	if neighbor.outgoing_river != opposite_direction(incoming_river):
		return
	neighbor.has_outgoing_river = false
	neighbor.refresh()

func remove_river() -> void:
	remove_outgoing_river()
	remove_incoming_river()

## 是否有河（不关心是入是出）
func has_river() -> bool:
	return has_incoming_river or has_outgoing_river

## 是否是河流的“起点或终点”
func has_river_begin_or_end() -> bool:
	return has_incoming_river != has_outgoing_river

## 某个边上是否有河流经过（入/出都算）
func has_river_through_edge(direction: HexDirection) -> bool:
	return (has_incoming_river and incoming_river == direction) \
		or (has_outgoing_river and outgoing_river == direction)
#endregion

func refresh() -> void:
	_refresh()

func _validate_river_constraints() -> void:
	if has_outgoing_river and elevation < get_neighbor(outgoing_river).elevation:
		remove_outgoing_river()
	if has_incoming_river and elevation > get_neighbor(incoming_river).elevation:
		remove_incoming_river()

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
