class_name Gate
extends RefCounted
## One gate. ADD covers both "+n" and "−n" (value may be negative), so an
## acorn hit simply raises the value by one and −20 can climb to +5.

enum Op { ADD, MUL, DIV }

const _OP_NAMES := {"add": Op.ADD, "mul": Op.MUL, "div": Op.DIV}

var op: Op
var value: int


func _init(p_op: Op, p_value: int) -> void:
	op = p_op
	# Multiplying or dividing by zero (or less) makes no sense for a gate.
	value = p_value if op == Op.ADD else maxi(p_value, 1)


static func from_dict(data: Dictionary) -> Gate:
	return new(_OP_NAMES[data["op"]], int(data["value"]))


## Returns the army size after walking through this gate. Never below zero.
func apply(count: int) -> int:
	match op:
		Op.ADD:
			return maxi(count + value, 0)
		Op.MUL:
			return count * value
		Op.DIV:
			return floori(float(count) / value)
	return count


func hit_by_acorn() -> void:
	if op == Op.ADD:
		value += 1


## True when the gate grows the army; drives the green/red colour.
func is_positive() -> bool:
	match op:
		Op.ADD:
			return value > 0
		Op.MUL:
			return value > 1
	return false


func label() -> String:
	match op:
		Op.ADD:
			return ("+%d" if value >= 0 else "−%d") % absi(value)
		Op.MUL:
			return "×%d" % value
		Op.DIV:
			return "÷%d" % value
	return ""
