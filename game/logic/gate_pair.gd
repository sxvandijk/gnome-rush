class_name GatePair
extends RefCounted
## A left/right pair of gates across the lane at depth z. The army goes
## through the gate on the side of its centre; on the split itself it goes
## right. In chapter 3 the split slides: split_x(t) = sin(t·speed + phase)·amp.

var left: Gate
var right: Gate
var z: float
var used := false
var shift_amp := 0.0
var shift_speed := 0.0
var shift_phase := 0.0


func _init(p_left: Gate, p_right: Gate, p_z := 0.0) -> void:
	left = p_left
	right = p_right
	z = p_z


static func from_dict(data: Dictionary) -> GatePair:
	var pair := new(Gate.from_dict(data["left"]), Gate.from_dict(data["right"]), float(data.get("z", 0.0)))
	var shift: Dictionary = data.get("shift", {})
	pair.shift_amp = float(shift.get("amp", 0.0))
	pair.shift_speed = float(shift.get("speed", 0.0))
	pair.shift_phase = float(shift.get("phase", 0.0))
	return pair


func split_x(time: float) -> float:
	if shift_amp == 0.0:
		return 0.0
	return sin(time * shift_speed + shift_phase) * shift_amp


func gate_for_x(center_x: float, time := 0.0) -> Gate:
	return left if center_x < split_x(time) else right


## Applies the chosen gate once; later calls leave the count unchanged.
func apply(count: int, center_x: float, time := 0.0) -> int:
	if used:
		return count
	used = true
	return gate_for_x(center_x, time).apply(count)
