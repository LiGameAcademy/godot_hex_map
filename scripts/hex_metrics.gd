extends Object
class_name HexMetrics

enum HexEdgeType { 
	FLAT, 	## 平坦
	SLOPE, 	## 斜坡
	CLIFF, 	## 悬崖
}

## 从外半径到内半径的转换因子
const OUTER_TO_INNER: float = 0.866025404
## 从内半径到外半径的转换因子
const INNER_TO_OUTER: float = 1.0 / OUTER_TO_INNER
## 定义外半径为 10 个单位
const OUTER_RADIUS := 10.0
# 根号3除以2 约等于 0.866025404
const INNER_RADIUS := OUTER_RADIUS * OUTER_TO_INNER

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
const WATER_FACTOR = 0.6
const WATER_BLEND_FACTOR = 1 - WATER_FACTOR

## 每个单位高度对应的高度偏移量
const ELEVATION_STEP := 5.0
## 每个斜坡段包含的 Terrace 数量
const TERRACES_PER_SLOPE := 2
## 每个斜坡段包含的 Terrace 总数
const TERRACE_STEPS := TERRACES_PER_SLOPE * 2 + 1
## 水平方向上每个 Terrace 的步长
const HORIZONTAL_TERRACE_STEP_SIZE := 1.0 / TERRACE_STEPS
## 垂直方向上每个 Terrace 的步长
const VERTICAL_TERRACE_STEP_SIZE := 1.0 / float(TERRACES_PER_SLOPE + 1)

const CELL_PERTURB_STRENGTH := 5.0
const ELEVATION_PERTURB_STRENGTH := 1.5

## 大地图分块：每块的格子数（X、Z），网格尺寸需为块尺寸的整数倍
const CHUNK_SIZE_X := 5
const CHUNK_SIZE_Z := 5

## 河床相对格子海拔的高度偏移（负值表示比地面低）
const STREAM_BED_ELEVATION_OFFSET: float = -1.0
#const RIVER_SURFACE_Y_OFFSET: float = -0.1

const WATER_ELEVATION_OFFSET := -0.5

const HASH_GRID_SIZE := 256
const HASH_GRID_SCALE := 0.25

const WALL_HEIGHT: float = 3.0
const WALL_THICKNESS: float = 0.75

static var noise: FastNoiseLite

static var _hash_grid: Array[HexHash] = []

static var _feature_thresholds: Array[PackedFloat32Array] = [
	PackedFloat32Array([0.0, 0.0, 0.4]),
	PackedFloat32Array([0.0, 0.4, 0.6]),
	PackedFloat32Array([0.4, 0.6, 0.8])
]

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

static func get_solid_edge_middle(index: int) -> Vector3:
	return (CORNERS[index] + CORNERS[index + 1]) * SOLID_FACTOR * 0.5

## 获取“从内角点走到边界中点”的偏移向量，用于构建边界桥梁
static func get_bridge(index: int) -> Vector3:
	return (CORNERS[index] + CORNERS[index + 1]) * BLEND_FACTOR

static func get_first_water_corner(index: int) -> Vector3:
	return CORNERS[index] * WATER_FACTOR

static func get_second_water_corner(index: int) -> Vector3:
	return CORNERS[index + 1] * WATER_FACTOR	

static func get_water_bridge(index: int) -> Vector3:
	return (CORNERS[index] + CORNERS[index + 1]) * WATER_BLEND_FACTOR

## 获取台阶插值
static func get_terrace_interpolation(a: float, b: float, step: float) -> float:
	return a + step * (b - a)

## 台阶插值：水平每步都移动，垂直仅在奇数步变化，形成”平台+陡坡”的阶梯
static func terrace_lerp(a: Vector3, b: Vector3, step: int) -> Vector3:
	var h := step * HORIZONTAL_TERRACE_STEP_SIZE
	var v_step: int = (step + 1) >> 1  # 1→1, 2→1, 3→2, 4→2，Y 只在奇数 step 变
	var v := float(v_step) * VERTICAL_TERRACE_STEP_SIZE

	return Vector3(
		a.x + (b.x - a.x) * h,
		a.y + (b.y - a.y) * v,
		a.z + (b.z - a.z) * h
	)

static func terrace_lerp_color(a: Color, b: Color, step: int) -> Color:
	var h := step * HORIZONTAL_TERRACE_STEP_SIZE
	return a.lerp(b, h)

static func get_edge_type(elevation_a: int, elevation_b: int) -> HexEdgeType:
	if elevation_a == elevation_b:
		return HexEdgeType.FLAT
	var delta : int = absi(elevation_b - elevation_a)
	if delta == 1:
		return HexEdgeType.SLOPE
	return HexEdgeType.CLIFF

static func sample_noise(position: Vector3) -> Vector3:
	if noise == null:
		return Vector3.ZERO

	var x := position.x
	var y := position.y
	var z := position.z

	var nx := noise.get_noise_3d(x, y, z)
	var ny := noise.get_noise_3d(x + 100.0, y + 200.0, z + 300.0)
	var nz := noise.get_noise_3d(x - 100.0, y - 200.0, z - 300.0)
	return Vector3(nx, ny, nz)

## 使用噪声对顶点进行扰动
static func perturb(p: Vector3) -> Vector3:
	var noise_value := sample_noise(p)
	var q := p
	q.x += noise_value.x * HexMetrics.CELL_PERTURB_STRENGTH
	q.z += noise_value.z * HexMetrics.CELL_PERTURB_STRENGTH
	return q

static func initialize_hash_grid(seed_value: int) -> void:
	_hash_grid.clear()
	_hash_grid.resize(HASH_GRID_SIZE * HASH_GRID_SIZE)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(_hash_grid.size()):
		_hash_grid[i] = HexHash.create(rng)

static func sample_hash_grid(pos: Vector3) -> HexHash:
	var x := int(pos.x * HASH_GRID_SCALE) % HASH_GRID_SIZE
	var z := int(pos.z * HASH_GRID_SCALE) % HASH_GRID_SIZE

	if x < 0:
		x += HASH_GRID_SIZE
	if z < 0:
		z += HASH_GRID_SIZE

	return _hash_grid[x + z * HASH_GRID_SIZE]

static func get_feature_thresholds(level: int) -> PackedFloat32Array:
	if level > 0 and level <= _feature_thresholds.size():
		return _feature_thresholds[level - 1]
	return PackedFloat32Array()

static func wall_thickness_offset(near: Vector3, far: Vector3) -> Vector3:
	var offset: Vector3 = far - near
	offset.y = 0.0
	return offset.normalized() * (WALL_THICKNESS * 0.5)
