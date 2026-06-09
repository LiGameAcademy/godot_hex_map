extends RefCounted
class_name HexHash

var a: float  # 城市阈值
var b: float  # 农田阈值
var c: float  # 植物阈值
var d: float  # 变体选择
var e: float  # 旋转

static func create(rng: RandomNumberGenerator) -> HexHash:
	var h := HexHash.new()
	h.a = rng.randf()
	h.b = rng.randf()
	h.c = rng.randf()
	h.d = rng.randf()
	h.e = rng.randf()
	return h
