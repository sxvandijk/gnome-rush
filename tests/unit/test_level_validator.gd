extends GutTest


func _level(extra := {}) -> LevelData:
	var data := {"id": "t", "start_count": 10, "gate_pairs": [], "length": 60.0}
	data.merge(extra, true)
	return LevelData.from_dict(data)


func _gate(op: String, value: int) -> Dictionary:
	return {"op": op, "value": value}


# --- Plan --------------------------------------------------------------------

func test_plan_takes_better_gate() -> void:
	var plan := LevelValidator.make_plan(_level({"gate_pairs": [
		{"z": 20.0, "left": _gate("add", 5), "right": _gate("mul", 2)},
		{"z": 40.0, "left": _gate("mul", 3), "right": _gate("add", 4)},
	]}))
	assert_eq(plan.take_left, [false, true] as Array[bool])
	assert_eq(plan.expected, 60)


func test_plan_fights_guard_when_worth_it() -> void:
	var plan := LevelValidator.make_plan(_level({
		"gate_pairs": [{"z": 30.0, "left": _gate("mul", 2), "right": _gate("add", 3)}],
		"moles": [{"z": 27.0, "x": -2.0, "count": 2}],
	}))
	assert_eq(plan.fight, [true] as Array[bool])
	assert_eq(plan.take_left, [true] as Array[bool])
	assert_eq(plan.expected, 16)


func test_plan_dodges_guard_when_not_worth_it() -> void:
	var plan := LevelValidator.make_plan(_level({
		"gate_pairs": [{"z": 30.0, "left": _gate("mul", 2), "right": _gate("add", 8)}],
		"moles": [{"z": 27.0, "x": -2.0, "count": 4}],
	}))
	assert_eq(plan.fight, [false] as Array[bool])
	assert_eq(plan.take_left, [false] as Array[bool])
	assert_eq(plan.expected, 18)


func test_plan_never_fights_a_bigger_guard() -> void:
	var plan := LevelValidator.make_plan(_level({
		"gate_pairs": [{"z": 30.0, "left": _gate("mul", 3), "right": _gate("add", 1)}],
		"moles": [{"z": 27.0, "x": -2.0, "count": 10}],
	}))
	assert_eq(plan.fight, [false] as Array[bool])


func test_plan_fights_for_a_good_cage() -> void:
	var plan := LevelValidator.make_plan(_level({"moles": [
		{"z": 20.0, "x": 2.0, "count": 4, "cage": 6},
		{"z": 40.0, "x": -2.0, "count": 4, "cage": 4},
	]}))
	assert_eq(plan.fight, [true, false] as Array[bool])
	assert_eq(plan.expected, 12)


func test_plan_dodges_plain_moles() -> void:
	var plan := LevelValidator.make_plan(_level({"moles": [{"z": 20.0, "x": 0.0, "count": 3}]}))
	assert_eq(plan.fight, [false] as Array[bool])
	assert_eq(plan.expected, 10)


# --- Simulated best route ----------------------------------------------------

func test_best_route_follows_plan() -> void:
	var level := _level({"gate_pairs": [
		{"z": 20.0, "left": _gate("add", 5), "right": _gate("mul", 2)},
		{"z": 40.0, "left": _gate("mul", 3), "right": _gate("add", 4)},
	]})
	assert_eq(LevelValidator.best_route(level), 60)


func test_best_route_with_guard_and_cage() -> void:
	var level := _level({
		"gate_pairs": [{"z": 30.0, "left": _gate("mul", 2), "right": _gate("add", 3)}],
		"moles": [{"z": 27.0, "x": -2.0, "count": 2}, {"z": 45.0, "x": 2.0, "count": 4, "cage": 6}],
	})
	assert_eq(LevelValidator.best_route(level), 18)


func test_best_route_dodges_plain_moles() -> void:
	var level := _level({"moles": [{"z": 20.0, "x": -1.0, "count": 3}]})
	assert_eq(LevelValidator.best_route(level), 10)


func test_best_route_dodges_parked_mower() -> void:
	var level := _level({"mowers": [{"z": 20.0, "speed": 0.0, "phase": 0.0}], "start_count": 30})
	assert_eq(LevelValidator.best_route(level), 30)


func test_best_route_dodges_swinging_mower() -> void:
	var level := _level({"mowers": [{"z": 25.0, "speed": 1.8, "phase": 1.0}], "start_count": 30})
	assert_eq(LevelValidator.best_route(level), 30)


func test_best_route_dodges_slow_chasers() -> void:
	var level := _level({"moles": [{"z": 30.0, "x": -3.0, "count": 6, "chase": 1.0}]})
	assert_eq(LevelValidator.best_route(level), 10)


func test_best_route_counts_army_at_boss() -> void:
	var level := _level({
		"gate_pairs": [{"z": 20.0, "left": _gate("add", 5), "right": _gate("mul", 2)}],
		"boss": {"z": 40.0, "hp": 10},
	})
	assert_eq(LevelValidator.best_route(level), 20)


# --- Fairness ----------------------------------------------------------------

func test_fair_with_twenty_percent_margin() -> void:
	# best = 20, so hp up to 16 is fair (16 x 1.2 = 19.2)
	var fair := LevelValidator.validate(_level({
		"gate_pairs": [{"z": 20.0, "left": _gate("add", 5), "right": _gate("mul", 2)}],
		"boss": {"z": 40.0, "hp": 16},
	}))
	assert_true(fair.fair)
	assert_eq(fair.best, 20)


func test_unfair_without_margin() -> void:
	var unfair := LevelValidator.validate(_level({
		"gate_pairs": [{"z": 20.0, "left": _gate("add", 5), "right": _gate("mul", 2)}],
		"boss": {"z": 40.0, "hp": 17},
	}))
	assert_false(unfair.fair)


func test_unfair_when_army_cannot_survive() -> void:
	var result := LevelValidator.validate(_level({
		"gate_pairs": [{"z": 20.0, "left": _gate("add", -50), "right": _gate("add", -50)}],
	}))
	assert_false(result.fair)
	assert_eq(result.best, 0)
