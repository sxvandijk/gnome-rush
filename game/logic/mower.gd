class_name Mower
extends RefCounted
## A lawnmower driving back and forth across the lane at depth z. Costs
## gnomes while it overlaps the army.

const SWAY := 3.7
const HALF_WIDTH := 1.0
const HALF_DEPTH := 0.6

var z: float
var speed: float
var phase: float


func _init(p_z: float, p_speed: float, p_phase: float) -> void:
	z = p_z
	speed = p_speed
	phase = p_phase


static func from_dict(data: Dictionary) -> Mower:
	return new(float(data["z"]), float(data.get("speed", 1.5)), float(data.get("phase", 0.0)))


func x_at(time: float) -> float:
	return sin(time * speed + phase) * SWAY


## Army as a circle (centre x, depth d, radius r) against the mower box.
func overlaps(army_x: float, army_d: float, army_r: float, time: float) -> bool:
	return absf(army_x - x_at(time)) < HALF_WIDTH + army_r \
		and absf(army_d - z) < HALF_DEPTH + army_r
