extends RefCounted
class_name HexCell

## 六边形网格（逻辑层）

# 逻辑坐标（立方体坐标）
var coordinates: HexCoordinates
# 颜色，用于整张 Mesh 的顶点色
var color: Color = Color.WHITE
var position : Vector3
var label : Label3D
