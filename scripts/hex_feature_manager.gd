extends Node3D
class_name HexFeatureManager

@export var feature_prefab: PackedScene
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
	if not is_instance_valid(feature_prefab) or not is_instance_valid(_container):
		push_error("Feature prefab or container is not set")
		return
	var hex_hash : HexHash = HexMetrics.sample_hash_grid(pos)
	if hex_hash.a >= cell.urban_level * 0.25:
		return
	var instance: Node3D = feature_prefab.instantiate()
	_container.add_child(instance)
	#instance.position = pos
	instance.position = HexMetrics.perturb(pos + Vector3(0.0, instance.scale.y * 0.5, 0.0))
	instance.rotation.y = TAU * hex_hash.b
