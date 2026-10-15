class_name MoleGroup
extends RefCounted
## A group of moles on the lane. If the army touches it, they fight
## one-for-one; steer around it to dodge. Optional variants:
## - cage: gnomes held captive; freed when the moles are beaten and the army
##   walks over the cage.
## - chase: sideways speed at which the group closes in on the army.

## Size of the cage for pick-up, like an army radius.
const CAGE_RADIUS := 0.8

var z: float
var x: float
var count: int
var cage := 0
var chase := 0.0
## True once the moles are beaten or the army has passed them.
var resolved := false
var cage_opened := false
var cage_missed := false


func _init(p_z: float, p_x: float, p_count: int) -> void:
	z = p_z
	x = p_x
	count = maxi(p_count, 0)


static func from_dict(data: Dictionary) -> MoleGroup:
	var group := new(float(data["z"]), float(data.get("x", 0.0)), int(data["count"]))
	group.cage = int(data.get("cage", 0))
	group.chase = float(data.get("chase", 0.0))
	return group


func radius() -> float:
	return Army.radius_for(count)


## True while a freed cage is still waiting to be picked up.
func cage_waiting() -> bool:
	return cage > 0 and count <= 0 and not cage_opened and not cage_missed
