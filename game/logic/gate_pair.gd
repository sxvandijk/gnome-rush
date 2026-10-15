class_name GatePair
extends RefCounted
## A left/right pair of gates across the lane at depth z. The army goes
## through the gate on the side of its centre; x == 0 counts as right.

var left: Gate
var right: Gate
var z: float
var used := false


func _init(p_left: Gate, p_right: Gate, p_z := 0.0) -> void:
	left = p_left
	right = p_right
	z = p_z


static func from_dict(data: Dictionary) -> GatePair:
	return new(Gate.from_dict(data["left"]), Gate.from_dict(data["right"]), float(data.get("z", 0.0)))


func gate_for_x(center_x: float) -> Gate:
	return left if center_x < 0.0 else right


## Applies the chosen gate once; later calls leave the count unchanged.
func apply(count: int, center_x: float) -> int:
	if used:
		return count
	used = true
	return gate_for_x(center_x).apply(count)
