extends GutTest
## Chapter 2: sprinklers push the army sideways.
## Chapter 3: gate pairs whose split line slides back and forth.

const STEP := 1.0 / 60.0


func _run(extra: Dictionary) -> RunState:
	var data := {"id": "t", "start_count": 10, "length": 80.0, "gate_pairs": []}
	data.merge(extra, true)
	var run := RunState.new(LevelData.from_dict(data))
	run.fire_rate = 0.0
	return run


# --- Sprinklers --------------------------------------------------------------

func test_sprinkler_from_dict_and_push() -> void:
	var s := Sprinkler.from_dict({"z": 40.0, "push": 5.0, "speed": 2.0, "phase": 0.5})
	assert_eq(s.z, 40.0)
	assert_almost_eq(s.push_at(1.0), 5.0 * sin(2.0 + 0.5), 0.0001)


func test_sprinkler_reach() -> void:
	var s := Sprinkler.from_dict({"z": 40.0, "push": 5.0})
	assert_true(s.reaches(40.0))
	assert_true(s.reaches(40.0 - Sprinkler.HALF_DEPTH + 0.1))
	assert_false(s.reaches(40.0 - Sprinkler.HALF_DEPTH - 0.1))


func test_sprinkler_pushes_steering_target() -> void:
	# Phase PI/2 with speed 0: constant push of +5 to the right
	var run := _run({"sprinklers": [{"z": 10.0, "push": 5.0, "speed": 0.0, "phase": PI / 2.0}]})
	while run.distance < 10.0:
		run.update(STEP)
	assert_gt(run.target_x, 0.5)
	assert_gt(run.army.center_x, 0.3)


func test_no_push_outside_reach() -> void:
	var run := _run({"sprinklers": [{"z": 60.0, "push": 5.0, "speed": 0.0, "phase": PI / 2.0}]})
	run.update(2.0)  # distance 18, far from z = 60
	assert_eq(run.target_x, 0.0)


func test_level_data_creates_sprinklers() -> void:
	var level := LevelData.from_dict({"sprinklers": [{"z": 10.0, "push": 3.0}]})
	assert_eq(level.create_sprinklers().size(), 1)


# --- Sliding gates -----------------------------------------------------------

func test_pair_without_shift_splits_at_zero() -> void:
	var pair := GatePair.from_dict({"z": 10.0, "left": {"op": "add", "value": 1}, "right": {"op": "add", "value": 2}})
	assert_eq(pair.split_x(3.0), 0.0)


func test_sliding_split() -> void:
	var pair := GatePair.from_dict({
		"z": 10.0, "left": {"op": "add", "value": 1}, "right": {"op": "add", "value": 2},
		"shift": {"amp": 2.0, "speed": 1.5, "phase": 0.2},
	})
	assert_almost_eq(pair.split_x(1.0), 2.0 * sin(1.5 + 0.2), 0.0001)


func test_side_follows_split() -> void:
	# Split parked at +2 (speed 0, phase PI/2): x = 1 is on the left
	var pair := GatePair.from_dict({
		"z": 10.0, "left": {"op": "add", "value": 1}, "right": {"op": "add", "value": 2},
		"shift": {"amp": 2.0, "speed": 0.0, "phase": PI / 2.0},
	})
	assert_eq(pair.gate_for_x(1.0, 0.0), pair.left)
	assert_eq(pair.gate_for_x(2.5, 0.0), pair.right)
	assert_eq(pair.apply(10, 1.0, 0.0), 11)


func test_run_uses_split_at_crossing_time() -> void:
	var run := _run({"gate_pairs": [{
		"z": 9.0, "left": {"op": "add", "value": 5}, "right": {"op": "mul", "value": 2},
		"shift": {"amp": 2.0, "speed": 0.0, "phase": PI / 2.0},
	}]})
	run.set_target_x(1.0)  # Right of 0 but left of the split at +2
	run.army.set_center_x(1.0)
	run.update(1.1)
	assert_eq(run.army.count, 15)


func test_validator_times_sliding_gates() -> void:
	var level := LevelData.from_dict({"id": "t", "start_count": 10, "length": 60.0, "gate_pairs": [{
		"z": 30.0, "left": {"op": "mul", "value": 3}, "right": {"op": "add", "value": 1},
		"shift": {"amp": 2.0, "speed": 1.3, "phase": 0.0},
	}]})
	assert_eq(LevelValidator.best_route(level), 30)


func test_validator_beats_sprinkler() -> void:
	var level := LevelData.from_dict({"id": "t", "start_count": 10, "length": 60.0,
		"gate_pairs": [{"z": 30.0, "left": {"op": "mul", "value": 3}, "right": {"op": "add", "value": 1}}],
		"sprinklers": [{"z": 27.0, "push": 6.0, "speed": 0.0, "phase": PI / 2.0}],
	})
	assert_eq(LevelValidator.best_route(level), 30)
