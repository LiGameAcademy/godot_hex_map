extends Node3D
class_name HexFeatureManager

@export var urban_collections: Array[HexFeatureCollection] = []
@export var farm_collections: Array[HexFeatureCollection] = []
@export var plant_collections: Array[HexFeatureCollection] = []

@export var walls: HexMesh

var _container: Node3D

func clear() -> void:
	if is_instance_valid(_container):
		_container.queue_free()
	_container = Node3D.new()
	_container.name = "Features"
	add_child(_container)

	if is_instance_valid(walls):
		walls.begin_triangles()

func apply() -> void:
	if is_instance_valid(walls):
		walls.commit_triangles()

func add_feature(cell : HexCell, pos: Vector3) -> void:
	if not is_instance_valid(_container):
		push_error("Container is not set")
		return
	var hex_hash : HexHash = HexMetrics.sample_hash_grid(pos)
	# 城市
	var prefab : PackedScene = _pick_prefab(urban_collections, cell.urban_level, hex_hash.a, hex_hash.d)
	var score : float = hex_hash.a / float(cell.urban_level)
	# 农田
	if hex_hash.b / float(cell.farm_level) < score:
		score = hex_hash.b / float(cell.farm_level)
		prefab = _pick_prefab(farm_collections, cell.farm_level, hex_hash.b, hex_hash.d)
	# 植物
	if hex_hash.c / float(cell.plant_level) < score:
		score = hex_hash.c / float(cell.plant_level)
		prefab = _pick_prefab(plant_collections, cell.plant_level, hex_hash.b, hex_hash.d)
		
	if not is_instance_valid(prefab):
		return

	var instance: Node3D = prefab.instantiate()
	_container.add_child(instance)
	instance.position = HexMetrics.perturb(pos + Vector3(0.0, instance.scale.y * 0.5, 0.0))
	instance.rotation.y = TAU * hex_hash.e

func add_wall(near_edge: PackedVector3Array, near_cell: HexCell, far_edge: PackedVector3Array, far_cell: HexCell) -> void:
	if near_cell.walled != far_cell.walled:
		add_wall_segment(near_edge[0], far_edge[0], near_edge[4], far_edge[4])

func add_wall_segment(near_left: Vector3, far_left: Vector3, near_right: Vector3,far_right: Vector3) -> void:
	var left := near_left.lerp(far_left, 0.5)
	var right := near_right.lerp(far_right, 0.5)

	var wall_top_y := left.y + HexMetrics.WALL_HEIGHT

	var left_thickness_offset := HexMetrics.wall_thickness_offset(near_left, far_left)
	var right_thickness_offset := HexMetrics.wall_thickness_offset(near_right, far_right)

	var v1 := left - left_thickness_offset
	var v2 := right - right_thickness_offset
	var v3 := v1; v3.y = wall_top_y
	var v4 := v2; v4.y = wall_top_y
	walls.add_quad([v1, v2, v3, v4], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	var t1 := v3; var t2 := v4
	
	v1 = left + left_thickness_offset
	v2 = right + right_thickness_offset
	v3 = v1; v3.y = wall_top_y
	v4 = v2; v4.y = wall_top_y
	walls.add_quad([v2, v1, v4, v3], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])

	walls.add_quad([t1, t2, v3, v4], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])

func _pick_prefab(collections: Array[HexFeatureCollection], level: int, hex_hash: float, choice: float) -> PackedScene:
	if level <= 0 or collections.is_empty():
		return null
	var thresholds := HexMetrics.get_feature_thresholds(level)
	if thresholds.is_empty():
		return null
	if collections.size() != thresholds.size():
		push_error(
			"collections size (%d) must match thresholds size (%d) for level %d"
			% [collections.size(), thresholds.size(), level]
		)
		return null
	for i in range(thresholds.size()):
		if hex_hash < thresholds[i]:
			return collections[i].pick(choice)
	return null
