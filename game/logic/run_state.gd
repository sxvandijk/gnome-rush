class_name RunState
extends RefCounted
## One attempt at a level: how far the army has run and which gate pairs it
## has passed. Distance grows forward from 0 to level.length.

signal pair_passed(pair: GatePair, gate: Gate)

var level: LevelData
var army: Army
var pairs: Array[GatePair]
var distance := 0.0
var _next_pair := 0


func _init(p_level: LevelData) -> void:
	level = p_level
	army = Army.new(level.start_count, level.lane_half_width)
	pairs = level.create_pairs()


func advance(delta_distance: float) -> void:
	if is_finished():
		return
	distance = minf(distance + delta_distance, level.length)
	while _next_pair < pairs.size() and pairs[_next_pair].z <= distance:
		var pair := pairs[_next_pair]
		var gate := pair.gate_for_x(army.center_x)
		army.pass_gate_pair(pair)
		_next_pair += 1
		pair_passed.emit(pair, gate)
		if army.is_defeated():
			distance = pair.z
			return


func is_finished() -> bool:
	return army.is_defeated() or distance >= level.length


func is_won() -> bool:
	return not army.is_defeated() and distance >= level.length
