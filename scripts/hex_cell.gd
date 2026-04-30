extends RefCounted
class_name HexCell

## 六边形网格（逻辑层）

enum HexDirection { NE, E, SE, SW, W, NW }

# 逻辑坐标（立方体坐标）
var coordinates: HexCoordinates
# 颜色，用于整张 Mesh 的顶点色
var color: Color = Color.WHITE
var position : Vector3
var label : Label3D

var neighbors: Array[HexCell] = [null, null, null, null, null, null]

## 海拔高度
var elevation : int = 0:
	set(value):
		elevation = value
		var base_y := float(elevation) * HexMetrics.ELEVATION_STEP
		position.y = base_y

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
