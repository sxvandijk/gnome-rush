extends GutTest


func _level(start := 10) -> LevelData:
	return LevelData.from_dict({
		"id": "t",
		"start_count": start,
		"lane_half_width": 3.0,
		"length": 30.0,
		"speed": 5.0,
		"gate_pairs": [
			{"z": 10.0, "left": {"op": "add", "value": 5}, "right": {"op": "mul", "value": 2}},
			{"z": 20.0, "left": {"op": "add", "value": -100}, "right": {"op": "add", "value": 1}},
		],
	})


func test_starts_at_zero_with_start_count() -> void:
	var run := RunState.new(_level())
	assert_eq(run.distance, 0.0)
	assert_eq(run.army.count, 10)
	assert_eq(run.army.lane_half_width, 3.0)
	assert_false(run.is_finished())


func test_gate_not_applied_before_reaching_it() -> void:
	var run := RunState.new(_level())
	run.advance(9.9)
	assert_eq(run.army.count, 10)


func test_gate_applied_when_reached() -> void:
	var run := RunState.new(_level())
	run.army.set_center_x(1.0)
	run.advance(10.0)
	assert_eq(run.army.count, 20)


func test_multiple_gates_in_one_big_step() -> void:
	var run := RunState.new(_level())
	run.army.set_center_x(1.0)
	run.advance(25.0)
	assert_eq(run.army.count, 21)


func test_pair_passed_signal() -> void:
	var run := RunState.new(_level())
	watch_signals(run)
	run.army.set_center_x(-1.0)
	run.advance(10.0)
	assert_signal_emit_count(run, "pair_passed", 1)
	var params: Array = get_signal_parameters(run, "pair_passed")
	assert_eq(params[1], params[0].left)


func test_win_at_end_of_lane() -> void:
	var run := RunState.new(_level())
	run.army.set_center_x(1.0)
	run.advance(30.0)
	assert_true(run.is_finished())
	assert_true(run.is_won())


func test_distance_stops_at_length() -> void:
	var run := RunState.new(_level())
	run.advance(100.0)
	assert_eq(run.distance, 30.0)


func test_loss_when_army_reaches_zero() -> void:
	var run := RunState.new(_level())
	run.army.set_center_x(-1.0)
	run.advance(20.0)
	assert_true(run.army.is_defeated())
	assert_true(run.is_finished())
	assert_false(run.is_won())


func test_no_progress_after_finish() -> void:
	var run := RunState.new(_level())
	run.army.set_center_x(-1.0)
	run.advance(20.0)
	run.advance(5.0)
	assert_eq(run.distance, 20.0)
