extends Node3D
class_name HexFeatureManager

@export var urban_collections: Array[HexFeatureCollection] = []
var _container: Node3D

func clear() -> void:
	if is_instance_valid(_container):
		_container.queue_free()
	_container = Node3D.new()
	_container.name = "Features"
	add_child(_container)

func apply() -> void:
	pass

func add_feature(cell : HexCell, pos: Vector3) -> void:
	if not is_instance_valid(_container):
		push_error("Container is not set")
		return
	var hex_hash : HexHash = HexMetrics.sample_hash_grid(pos)
	#if hex_hash.a >= cell.urban_level * 0.25:
		#return
	#if cell.urban_level <= 0 or cell.urban_level  > urban_prefabs.size():
		#push_error("cell urban level <= 0 or cell urban level > urban_prefabs size!")
		#return
	var prefab : PackedScene = _pick_prefab(cell.urban_level, hex_hash.a, hex_hash.b)
	if not is_instance_valid(prefab):
		return
	var instance: Node3D = prefab.instantiate()
	_container.add_child(instance)
	#instance.position = pos
	instance.position = HexMetrics.perturb(pos + Vector3(0.0, instance.scale.y * 0.5, 0.0))
	instance.rotation.y = TAU * hex_hash.c

func _pick_prefab(level: int, hex_hash: float, choice: float) -> PackedScene:
	if level <= 0:
		return null
	if urban_collections.is_empty():
		push_error("urban_collections is empty")
		return null
	var thresholds := HexMetrics.get_feature_thresholds(level)
	if thresholds.is_empty():
		return null
	if urban_collections.size() != thresholds.size():
		push_error(
			"urban_collections size (%d) must match thresholds size (%d) for level %d"
			% [urban_collections.size(), thresholds.size(), level]
		)
		return null
	for i in range(thresholds.size()):
		if hex_hash < thresholds[i]:
			return urban_collections[i].pick(choice)
	return null
