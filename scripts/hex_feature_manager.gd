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

func add_wall(near_edge: PackedVector3Array, near_cell: HexCell, far_edge: PackedVector3Array, far_cell: HexCell, has_river: bool, has_road: bool) -> void:
	if near_cell.walled != far_cell.walled:
		if near_cell.is_underwater or far_cell.is_underwater:
			return
		if near_cell.get_edge_type_by_cell(far_cell) == HexMetrics.HexEdgeType.CLIFF:
			return
		add_wall_segment(near_edge[0], far_edge[0], near_edge[1], far_edge[1])
		if not has_river and not has_road:
			add_wall_segment(near_edge[1], far_edge[1], near_edge[2], far_edge[2])
			add_wall_segment(near_edge[2], far_edge[2], near_edge[3], far_edge[3])
		else:
			add_wall_cap(near_edge[1], far_edge[1])
			add_wall_cap(far_edge[3], near_edge[3])
		add_wall_segment(near_edge[3], far_edge[3], near_edge[4], far_edge[4])

func add_corner_wall(cell1: HexCell, cell2: HexCell, cell3: HexCell, v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	if cell1.walled:
		if cell2.walled:
			if not cell3.walled:
				add_corner_wall_segment(v3, cell3, v2, cell2, v1, cell1)
		elif cell3.walled:
			add_corner_wall_segment(v2, cell2, v1, cell1, v3, cell3)
		else:
			add_corner_wall_segment(v1, cell1, v3, cell3, v2, cell2)
	elif cell2.walled:
		if cell3.walled:
			add_corner_wall_segment(v1, cell1, v3, cell3, v2, cell2)
		else:
			add_corner_wall_segment(v2, cell2, v1, cell1, v3, cell3)
	elif cell3.walled:
		add_corner_wall_segment(v3, cell3, v2, cell2, v1, cell1)

func add_wall_segment(near_left: Vector3, far_left: Vector3, near_right: Vector3,far_right: Vector3) -> void:
	near_left = HexMetrics.perturb(near_left)
	far_left = HexMetrics.perturb(far_left)
	near_right = HexMetrics.perturb(near_right)
	far_right = HexMetrics.perturb(far_right)

	var left := HexMetrics.wall_lerp(near_left, far_left)
	var right := HexMetrics.wall_lerp(near_right, far_right)

	#var wall_top_y := left.y + HexMetrics.WALL_HEIGHT
	var left_top_y := left.y + HexMetrics.WALL_HEIGHT
	var right_top_y := right.y + HexMetrics.WALL_HEIGHT

	var left_thickness_offset := HexMetrics.wall_thickness_offset(near_left, far_left)
	var right_thickness_offset := HexMetrics.wall_thickness_offset(near_right, far_right)

	var v1 := left - left_thickness_offset
	var v2 := right - right_thickness_offset
	var v3 := v1; v3.y = left_top_y
	var v4 := v2; v4.y = right_top_y
	walls.add_quad([v1, v2, v3, v4], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE], false)
	var t1 := v3; var t2 := v4
	
	v1 = left + left_thickness_offset
	v2 = right + right_thickness_offset
	v3 = v1; v3.y = left_top_y
	v4 = v2; v4.y = right_top_y
	walls.add_quad([v2, v1, v4, v3], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE], false)

	walls.add_quad([t1, t2, v3, v4], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE], false)

func add_corner_wall_segment(
	pivot: Vector3, pivot_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell
) -> void:
	if pivot_cell.is_underwater:
		return
	var has_left_wall := not left_cell.is_underwater and pivot_cell.get_edge_type_by_cell(left_cell) != HexMetrics.HexEdgeType.CLIFF
	var has_right_wall := not right_cell.is_underwater and pivot_cell.get_edge_type_by_cell(right_cell) != HexMetrics.HexEdgeType.CLIFF
	if has_left_wall:
		if has_right_wall:
			add_wall_segment(left, pivot, right, pivot)
		elif left_cell.elevation < right_cell.elevation:
			add_wall_wedge(pivot, left, right)
		else:
			add_wall_cap(left, pivot)
	elif has_right_wall:
		if right_cell.elevation < left_cell.elevation:
			add_wall_wedge(right, pivot, left)
		else:
			add_wall_cap(pivot, right)

func add_wall_cap(near: Vector3, far: Vector3) -> void:
	near = HexMetrics.perturb(near)
	far = HexMetrics.perturb(far)
	var center: Vector3 = near.lerp(far, 0.5)
	var thickness: Vector3 = HexMetrics.wall_thickness_offset(near, far)
	var v1: Vector3 = center - thickness
	var v2: Vector3 = center + thickness
	var v3: Vector3 = Vector3(v1.x, center.y + HexMetrics.WALL_HEIGHT, v1.z)
	var v4: Vector3 = Vector3(v2.x, center.y + HexMetrics.WALL_HEIGHT, v2.z)
	walls.add_quad([v1, v2, v3, v4], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE], false)

func add_wall_wedge(near: Vector3, far: Vector3, point: Vector3) -> void:
	near = HexMetrics.perturb(near)
	far = HexMetrics.perturb(far)
	point = HexMetrics.perturb(point)

	var center: Vector3 = HexMetrics.wall_lerp(near, far)
	var thickness: Vector3 = HexMetrics.wall_thickness_offset(near, far)
	var point_top := point
	point.y = center.y

	var v1: Vector3 = center - thickness
	var v2: Vector3 = center + thickness
	var v3: Vector3 = v1; var v4: Vector3 = v2
	point_top.y = center.y + HexMetrics.WALL_HEIGHT
	v3.y = point_top.y; v4.y = point_top.y

	walls.add_quad([v3, point_top, v1, point], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE], false)
	walls.add_quad([v2, point, v4, point_top], [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE], false)
	walls.add_triangle([v3, point_top, v4], [Color.WHITE, Color.WHITE, Color.WHITE], false)

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
