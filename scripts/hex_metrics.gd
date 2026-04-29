extends Object
class_name HexMetrics

const OUTER_RADIUS := 10.0
# 根号3除以2 约等于 0.866025404
const INNER_RADIUS := OUTER_RADIUS * 0.866025404

const CORNERS: Array[Vector3] = [
	Vector3(0.0, 0.0, OUTER_RADIUS),					## 上
	Vector3(INNER_RADIUS, 0.0, 0.5 * OUTER_RADIUS),		## 右上
	Vector3(INNER_RADIUS, 0.0, -0.5 * OUTER_RADIUS),	## 右下
	Vector3(0.0, 0.0, -OUTER_RADIUS),					## 下
	Vector3(-INNER_RADIUS, 0.0, -0.5 * OUTER_RADIUS),	## 左下
	Vector3(-INNER_RADIUS, 0.0, 0.5 * OUTER_RADIUS),	## 左上
	Vector3(0.0, 0.0, OUTER_RADIUS), # 第7个点回到起点，方便写循环
]
