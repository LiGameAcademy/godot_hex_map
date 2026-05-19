extends RefCounted
class_name HexHash

var a: float
var b: float

static func create(rng: RandomNumberGenerator) -> HexHash:
	var h := HexHash.new()
	h.a = rng.randf()
	h.b = rng.randf()
	return h
