extends RefCounted
class_name HexCoordinates

## 六边形坐标系统：Offset → Axial → Cube

var x: int
var y: int:
	get:
		return -x - z
var z: int

func _init(p_x: int, p_z: int) -> void:
	x = p_x
	z = p_z

# 从“行列”Offset 坐标构造
static func from_offset(offset_x: int, offset_z: int) -> HexCoordinates:
	return HexCoordinates.new(offset_x - int(float(offset_z) / 2.0), offset_z)

# 从世界 3D 位置反推所在格子的立方体坐标（用于点击检测）
static func from_position(position: Vector3) -> HexCoordinates:
	# 1. 先把世界坐标投影到六边形坐标系
	var local_x := position.x / (HexMetrics.INNER_RADIUS * 2.0)
	var local_y := -local_x
	var offset := position.z / (HexMetrics.OUTER_RADIUS * 3.0)
	local_x -= offset
	local_y -= offset
	# 2. 把浮点坐标粗略四舍五入到整数格子
	var i_x := roundi(local_x)
	var i_y := roundi(local_y)
	var i_z := roundi(-local_x - local_y)
	# 3. 用 `X+Y+Z=0` 做合法化修正
	if i_x + i_y + i_z != 0:
		var d_x := absf(local_x - i_x)
		var d_y := absf(local_y - i_y)
		var d_z := absf(-local_x - local_y - i_z)
		if d_x > d_y and d_x > d_z:
			i_x = -i_y - i_z
		elif d_z > d_y:
			i_z = -i_x - i_y

	# 4. 返回我们项目真正存储的坐标
	return HexCoordinates.new(i_x, i_z)

func _to_string() -> String:
	return "(" + str(x) + "," + str(y) + "," + str(z) + ")"
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
