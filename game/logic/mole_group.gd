class_name MoleGroup
extends RefCounted
## A group of moles on the lane. If the army touches it, they fight
## one-for-one; steer around it to dodge.

var z: float
var x: float
var count: int
## True once the group is beaten or the army has passed it.
var resolved := false


func _init(p_z: float, p_x: float, p_count: int) -> void:
	z = p_z
	x = p_x
	count = maxi(p_count, 0)


static func from_dict(data: Dictionary) -> MoleGroup:
	return new(float(data["z"]), float(data.get("x", 0.0)), int(data["count"]))


func radius() -> float:
	return Army.radius_for(count)
