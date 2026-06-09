@tool
extends Resource
class_name HexFeatureCollection

@export var prefabs: Array[PackedScene] = []

func pick(choice: float) -> PackedScene:
	if prefabs.is_empty():
		return null
	var n := prefabs.size()
	var idx := int(choice * n)
	return prefabs[clampi(idx, 0, n - 1)]
