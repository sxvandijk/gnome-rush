class_name Sprinkler
extends RefCounted
## Chapter 2 (vegetable garden): a sprinkler whose swinging jet pushes the
## army sideways while it runs past. The push moves the steering target, so
## the player has to drag against it.

const HALF_DEPTH := 5.0

var z: float
var push: float
var speed: float
var phase: float


func _init(p_z: float, p_push: float, p_speed: float, p_phase: float) -> void:
	z = p_z
	push = p_push
	speed = p_speed
	phase = p_phase


static func from_dict(data: Dictionary) -> Sprinkler:
	return new(float(data["z"]), float(data.get("push", 4.0)), float(data.get("speed", 1.5)), float(data.get("phase", 0.0)))


## Sideways push in units per second; the sign gives the direction.
func push_at(time: float) -> float:
	return push * sin(time * speed + phase)


func reaches(army_d: float) -> bool:
	return absf(army_d - z) < HALF_DEPTH
