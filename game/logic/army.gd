class_name Army
extends RefCounted
## The gnome army: its size, its centre on the lane and its formation.

signal count_changed(new_count: int, old_count: int)

const GOLDEN_ANGLE := PI * (3.0 - sqrt(5.0))
const DEFAULT_SPACING := 0.5

var count: int
var center_x := 0.0
var lane_half_width: float


func _init(p_count: int, p_lane_half_width: float) -> void:
	count = maxi(p_count, 0)
	lane_half_width = p_lane_half_width


func set_center_x(x: float) -> void:
	center_x = clampf(x, -lane_half_width, lane_half_width)


func pass_gate_pair(pair: GatePair) -> void:
	_set_count(pair.apply(count, center_x))


func is_defeated() -> bool:
	return count <= 0


func _set_count(new_count: int) -> void:
	var old := count
	count = maxi(new_count, 0)
	if count != old:
		count_changed.emit(count, old)


## Sunflower (Vogel) layout: compact, round, deterministic, and gnome i keeps
## its offset when the army grows, so the swarm never reshuffles.
static func formation(n: int, spacing := DEFAULT_SPACING) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(maxi(n, 0))
	for i in points.size():
		var r := spacing * sqrt(float(i))
		var a := i * GOLDEN_ANGLE
		points[i] = Vector2(cos(a), sin(a)) * r
	return points


static func formation_radius(n: int, spacing := DEFAULT_SPACING) -> float:
	return spacing * sqrt(float(maxi(n - 1, 0)))
