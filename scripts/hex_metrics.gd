extends Object
class_name HexMetrics

const OUTER_RADIUS := 10.0
# 根号3除以2 约等于 0.866025404
const INNER_RADIUS := OUTER_RADIUS * 0.866025404

const CORNERS: Array[Vector3] = [
	Vector3(0.0, 0.0, -OUTER_RADIUS),					## 上
	Vector3(INNER_RADIUS, 0.0, 0.5 * -OUTER_RADIUS),		## 右上
	Vector3(INNER_RADIUS, 0.0, 0.5 * OUTER_RADIUS),	## 右下
	Vector3(0.0, 0.0, OUTER_RADIUS),					## 下
	Vector3(-INNER_RADIUS, 0.0, 0.5 * OUTER_RADIUS),	## 左下
	Vector3(-INNER_RADIUS, 0.0, 0.5 * -OUTER_RADIUS),	## 左上
	Vector3(0.0, 0.0, -OUTER_RADIUS), # 第7个点回到起点，方便写循环
]

const SOLID_FACTOR := 0.75
const BLEND_FACTOR := 1.0 - SOLID_FACTOR

## 获取第一个混合角点的坐标
static func get_first_corner(index: int) -> Vector3:
	return CORNERS[index]

## 获取第二个混合角点的坐标
static func get_second_corner(index: int) -> Vector3:
	return CORNERS[index + 1]

static func get_first_solid_corner(index: int) -> Vector3:
	return CORNERS[index] * SOLID_FACTOR

static func get_second_solid_corner(index: int) -> Vector3:
	return CORNERS[index + 1] * SOLID_FACTOR

## 获取“从内角点走到边界中点”的偏移向量，用于构建边界桥梁
static func get_bridge(index: int) -> Vector3:
	return (CORNERS[index] + CORNERS[index + 1]) * BLEND_FACTOR
