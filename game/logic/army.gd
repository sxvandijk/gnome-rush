class_name Army
extends RefCounted
## The gnome army: its size, its centre on the lane and its formation.

signal count_changed(new_count: int, old_count: int)

const GOLDEN_ANGLE := 2.39996
const SPACING := 0.27
## Only this many gnomes are drawn and count towards the army's size on the
## lane; the label always shows the real number.
const MAX_VISIBLE := 120
const RADIUS_MARGIN := 0.3

var count: int
var center_x := 0.0
var x_limit: float


func _init(p_count: int, p_x_limit: float) -> void:
	count = maxi(p_count, 0)
	x_limit = p_x_limit


func set_center_x(x: float) -> void:
	center_x = clampf(x, -x_limit, x_limit)


func pass_gate_pair(pair: GatePair, time := 0.0) -> void:
	_set_count(pair.apply(count, center_x, time))


func add(n: int) -> void:
	_set_count(count + n)


func remove(n: int) -> void:
	_set_count(count - n)


func is_defeated() -> bool:
	return count <= 0


## Collision radius on the lane.
func radius() -> float:
	return radius_for(count)


func _set_count(new_count: int) -> void:
	var old := count
	count = maxi(new_count, 0)
	if count != old:
		count_changed.emit(count, old)


static func radius_for(n: int) -> float:
	return SPACING * sqrt(float(mini(maxi(n, 0), MAX_VISIBLE))) + RADIUS_MARGIN


## Sunflower (Vogel) layout: compact, round, deterministic, and gnome i keeps
## its offset when the army grows, so the swarm never reshuffles.
static func formation_point(i: int) -> Vector2:
	var a := i * GOLDEN_ANGLE
	return Vector2(cos(a), sin(a)) * SPACING * sqrt(float(i))


static func formation(n: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(maxi(n, 0))
	for i in points.size():
		points[i] = formation_point(i)
	return points
