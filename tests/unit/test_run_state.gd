extends GutTest
## RunState runs at a fixed 1/60 s step. Distances: speed 9, so 1 s = 9 units.

const STEP := 1.0 / 60.0


func _level(extra := {}) -> LevelData:
	var data := {
		"id": "t",
		"start_count": 10,
		"lane_half_width": 6.0,
		"army_x_limit": 4.3,
		"length": 200.0,
		"speed": 9.0,
		"gate_pairs": [],
	}
	data.merge(extra, true)
	return LevelData.from_dict(data)


func _run(extra := {}, fire := false) -> RunState:
	var run := RunState.new(_level(extra))
	if not fire:
		run.fire_rate = 0.0
	return run


## Runs until distance reaches d (or the run stops moving).
func _run_to(run: RunState, d: float, max_time := 60.0) -> void:
	var t := 0.0
	while run.distance < d and t < max_time and not run.is_finished():
		run.update(STEP)
		t += STEP


## Runs until a mole fight has started.
func _run_to_fight(run: RunState, max_time := 30.0) -> void:
	var t := 0.0
	while run.fighting == null and t < max_time and not run.is_finished():
		run.update(STEP)
		t += STEP


func _gate(op: String, value: int) -> Dictionary:
	return {"op": op, "value": value}


# --- Movement and steering ---------------------------------------------------

func test_starts_at_zero() -> void:
	var run := _run()
	assert_eq(run.distance, 0.0)
	assert_eq(run.army.count, 10)
	assert_eq(run.army.x_limit, 4.3)
	assert_false(run.is_finished())


func test_moves_at_level_speed() -> void:
	var run := _run()
	for i in 60:
		run.update(STEP)
	assert_almost_eq(run.distance, 9.0, 0.001)


func test_partial_steps_accumulate() -> void:
	var run := _run()
	run.update(STEP * 0.5)
	assert_eq(run.distance, 0.0)
	run.update(STEP * 0.5)
	assert_almost_eq(run.distance, 9.0 * STEP, 0.0001)


func test_steering_follows_target_smoothly() -> void:
	var run := _run()
	run.set_target_x(4.0)
	run.update(STEP)
	assert_gt(run.army.center_x, 0.0)
	assert_lt(run.army.center_x, 4.0)
	for i in 120:
		run.update(STEP)
	assert_almost_eq(run.army.center_x, 4.0, 0.01)


func test_target_clamped_to_limit() -> void:
	var run := _run()
	run.set_target_x(99.0)
	assert_eq(run.target_x, 4.3)


# --- Gates -------------------------------------------------------------------

func test_gate_applied_when_reached() -> void:
	var run := _run({"gate_pairs": [{"z": 9.0, "left": _gate("add", 5), "right": _gate("mul", 2)}]})
	run.set_target_x(1.0)
	_run_to(run, 8.8)
	assert_eq(run.army.count, 10)
	_run_to(run, 9.0)
	assert_eq(run.army.count, 20)


func test_pair_passed_signal() -> void:
	var run := _run({"gate_pairs": [{"z": 5.0, "left": _gate("add", 5), "right": _gate("mul", 2)}]})
	watch_signals(run)
	run.set_target_x(-3.0)
	run.army.set_center_x(-3.0)
	_run_to(run, 6.0)
	assert_signal_emit_count(run, "pair_passed", 1)
	var params: Array = get_signal_parameters(run, "pair_passed")
	assert_eq(params[1], params[0].left)


# --- Acorns ------------------------------------------------------------------

func test_fires_five_acorns_per_second() -> void:
	var run := _run({}, true)
	for i in 60:
		run.update(STEP)
	assert_eq(run.shots_fired, 5)


func test_acorns_fly_forward_and_expire() -> void:
	var run := _run({}, true)
	run.update(0.25)
	assert_gt(run.acorns.size(), 0)
	for a in run.acorns:
		assert_gt(a.y, 0.0)
		assert_lte(a.y, run.distance + RunState.ACORN_RANGE)


func test_acorn_count_capped() -> void:
	var run := _run({}, true)
	run.fire_rate = 1000.0
	run.update(1.0)
	assert_lte(run.acorns.size(), RunState.MAX_ACORNS)


func test_acorn_raises_add_gate() -> void:
	var run := _run({"gate_pairs": [{"z": 30.0, "left": _gate("add", -20), "right": _gate("add", -20)}]}, true)
	run.update(1.5)  # acorns have reached z = 30, the army has not
	var pair: GatePair = run.pairs[0]
	assert_false(pair.used)
	# The swarm straddles x = 0, so acorns hit both sides
	assert_gt(pair.left.value + pair.right.value, -40)


func test_acorn_does_not_change_mul_gate() -> void:
	var run := _run({"gate_pairs": [{"z": 30.0, "left": _gate("mul", 2), "right": _gate("mul", 2)}]}, true)
	run.update(1.5)
	assert_eq(run.pairs[0].left.value, 2)
	assert_eq(run.pairs[0].right.value, 2)


func test_acorns_ignore_used_pair() -> void:
	var run := _run({"gate_pairs": [{"z": 1.0, "left": _gate("add", -5), "right": _gate("add", -5)}]}, true)
	run.update(2.0)
	assert_eq(run.pairs[0].right.value, -5)


# --- Moles -------------------------------------------------------------------

func test_moles_dodged_when_x_apart() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": -4.0, "count": 5}]})
	run.set_target_x(4.0)
	run.army.set_center_x(4.0)
	_run_to(run, 30.0)
	assert_eq(run.army.count, 10)
	assert_true(run.moles[0].resolved)


func test_mole_fight_one_for_one() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": 0.0, "count": 4}]})
	_run_to(run, 30.0)
	assert_eq(run.army.count, 6)
	assert_eq(run.moles[0].count, 0)
	assert_true(run.moles[0].resolved)


func test_army_keeps_running_slower_while_fighting() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": 0.0, "count": 8}]})
	_run_to_fight(run)
	assert_not_null(run.fighting)
	var d := run.distance
	run.update(STEP * 3)
	assert_almost_eq(run.distance - d, 9.0 * RunState.MOLE_FIGHT_SPEED * STEP * 3, 0.0001)


func test_moles_pushed_ahead_of_army() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": 0.0, "count": 20}], "start_count": 60})
	_run_to_fight(run)
	var group: MoleGroup = run.fighting
	var z := group.z
	run.update(STEP * 10)
	assert_gt(group.z, z)
	assert_gte(group.z - run.distance, run.army.radius() + group.radius() - 0.001)


func test_no_second_fight_while_fighting() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": 0.0, "count": 10}, {"z": 22.0, "x": 0.0, "count": 5}], "start_count": 50})
	_run_to_fight(run)
	var first: MoleGroup = run.fighting
	run.update(STEP * 5)
	assert_eq(run.fighting, first)


func test_mole_fight_speed() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": 0.0, "count": 50}], "start_count": 100})
	_run_to_fight(run)
	var before := run.army.count
	run.update(0.035 * 10)
	assert_almost_eq(float(before - run.army.count), 10.0, 1.0)


func test_big_mole_fight_stays_short() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": 0.0, "count": 1000}], "start_count": 2000})
	_run_to_fight(run)
	run.update(RunState.MOLE_FIGHT_MAX_TIME + 0.1)
	assert_null(run.fighting)
	assert_eq(run.army.count, 1000)  # Still one for one


func test_moles_can_beat_army() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": 0.0, "count": 30}]})
	_run_to(run, 30.0)
	assert_true(run.army.is_defeated())
	assert_true(run.is_finished())
	assert_false(run.is_won())


func test_moles_defeated_counted() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": 0.0, "count": 4}]})
	_run_to(run, 30.0)
	assert_eq(run.moles_defeated, 4)


# --- Cages -------------------------------------------------------------------

func test_cage_freed_after_beating_moles() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": 0.0, "count": 10, "cage": 15}], "start_count": 30})
	watch_signals(run)
	_run_to(run, 40.0)
	assert_eq(run.army.count, 30 - 10 + 15)
	assert_true(run.moles[0].cage_opened)
	assert_signal_emitted(run, "cage_opened")


func test_cage_lost_when_moles_dodged() -> void:
	var run := _run({"moles": [{"z": 20.0, "x": -4.0, "count": 5, "cage": 15}]})
	run.set_target_x(4.3)
	run.army.set_center_x(4.3)
	_run_to(run, 40.0)
	assert_eq(run.army.count, 10)
	assert_false(run.moles[0].cage_opened)


func test_cage_after_acorns_needs_walking_over_it() -> void:
	var level := {"moles": [{"z": 40.0, "x": -3.0, "count": 3, "cage": 6}]}
	# Shot clear from afar, then walked over: freed
	var run := _run(level, true)
	run.set_target_x(-3.0)
	run.army.set_center_x(-3.0)
	_run_to(run, 50.0)
	assert_eq(run.moles[0].count, 0)
	assert_eq(run.army.count, 16)
	# Shot clear from afar, then steered away: missed
	var away := _run(level, true)
	away.set_target_x(-3.0)
	away.army.set_center_x(-3.0)
	away.update(2.0)
	assert_eq(away.moles[0].count, 0)
	away.set_target_x(4.3)
	_run_to(away, 50.0)
	assert_eq(away.army.count, 10)
	assert_false(away.moles[0].cage_opened)
	assert_true(away.moles[0].cage_missed)


# --- Chasing moles -----------------------------------------------------------

func test_chasing_moles_move_towards_army() -> void:
	var run := _run({"moles": [{"z": 25.0, "x": -4.0, "count": 5, "chase": 2.0}]})
	run.set_target_x(4.0)
	run.army.set_center_x(4.0)
	run.update(0.5)  # Still out of range: 25 - 4.5 > CHASE_RANGE
	assert_eq(run.moles[0].x, -4.0)
	run.update(0.5)  # In range now
	assert_gt(run.moles[0].x, -4.0)
	assert_lte(run.moles[0].x, -4.0 + 2.0 * 0.5 + 0.001)


func test_chasing_moles_stay_on_lane() -> void:
	var run := _run({"moles": [{"z": 15.0, "x": 3.0, "count": 5, "chase": 50.0}]})
	run.set_target_x(4.3)
	run.army.set_center_x(4.3)
	run.update(1.0)
	assert_lte(run.moles[0].x, 4.3)


func test_plain_moles_do_not_move() -> void:
	var run := _run({"moles": [{"z": 15.0, "x": -3.0, "count": 5}]})
	run.set_target_x(4.0)
	run.update(1.0)
	assert_eq(run.moles[0].x, -3.0)


func test_acorn_kills_mole() -> void:
	var run := _run({"moles": [{"z": 30.0, "x": 0.0, "count": 40}]}, true)
	run.update(1.5)
	assert_lt(run.moles[0].count, 40)


# --- Mowers ------------------------------------------------------------------

func test_mower_costs_gnomes_when_overlapping() -> void:
	var run := _run({"mowers": [{"z": 20.0, "speed": 0.0, "phase": 0.0}], "start_count": 50})
	_run_to(run, 40.0)
	assert_lt(run.army.count, 50)


func test_mower_avoided() -> void:
	var run := _run({"mowers": [{"z": 20.0, "speed": 0.0, "phase": 0.0}], "start_count": 3})
	run.set_target_x(4.3)
	run.army.set_center_x(4.3)
	_run_to(run, 40.0)
	assert_eq(run.army.count, 3)


func test_mower_rate() -> void:
	# Contact window: (mower half depth + army radius) on both sides, at speed 9
	var run := _run({"mowers": [{"z": 20.0, "speed": 0.0, "phase": 0.0}], "start_count": 200})
	var window := 2.0 * (Mower.HALF_DEPTH + Army.radius_for(200)) / 9.0
	_run_to(run, 40.0)
	var expected := window / RunState.MOWER_INTERVAL
	assert_almost_eq(float(200 - run.army.count), expected, 2.0)

# --- Boss --------------------------------------------------------------------

func test_boss_fight_win() -> void:
	var run := _run({"boss": {"z": 30.0, "hp": 6}})
	_run_to(run, 100.0)
	run.update(5.0)
	assert_true(run.boss.is_defeated())
	assert_true(run.is_won())
	assert_true(run.is_finished())
	assert_eq(run.army.count, 4)


func test_boss_fight_loss() -> void:
	var run := _run({"boss": {"z": 30.0, "hp": 25}})
	_run_to(run, 100.0)
	run.update(5.0)
	assert_true(run.army.is_defeated())
	assert_false(run.is_won())
	assert_almost_eq(run.boss.hp, 15.0, 0.001)


func test_army_stops_before_boss() -> void:
	var run := _run({"boss": {"z": 30.0, "hp": 1000}, "start_count": 500})
	run.update(5.0)
	assert_lt(run.distance, 30.0)
	assert_true(run.at_boss)


func test_big_boss_fight_stays_short() -> void:
	var run := _run({"boss": {"z": 30.0, "hp": 5000}, "start_count": 6000})
	while not run.at_boss:
		run.update(STEP)
	run.update(RunState.BOSS_FIGHT_MAX_TIME + 0.1)
	assert_true(run.is_won())
	assert_eq(run.army.count, 1000)  # Still one for one


func test_boss_interval_speeds_up_with_big_army() -> void:
	assert_almost_eq(RunState.boss_interval(0), 0.05, 0.0001)
	assert_almost_eq(RunState.boss_interval(100), 0.025, 0.0001)
	assert_almost_eq(RunState.boss_interval(1000), 0.012, 0.0001)


func test_acorns_damage_boss() -> void:
	var run := _run({"boss": {"z": 60.0, "hp": 100}}, true)
	run.update(2.5)
	assert_false(run.at_boss)
	assert_lt(run.boss.hp, 100.0)


func test_no_boss_wins_at_length() -> void:
	var run := _run({"length": 18.0})
	run.update(3.0)
	assert_true(run.is_won())
	assert_eq(run.distance, 18.0)


# --- Determinism -------------------------------------------------------------

func test_same_input_same_result() -> void:
	var extra := {
		"gate_pairs": [{"z": 30.0, "left": _gate("add", -8), "right": _gate("mul", 2)}],
		"moles": [{"z": 45.0, "x": 1.0, "count": 6}],
		"mowers": [{"z": 60.0, "speed": 1.7, "phase": 0.3}],
		"boss": {"z": 80.0, "hp": 12},
	}
	var a := _run(extra, true)
	var b := _run(extra, true)
	for i in 900:
		var target := sin(i * 0.05) * 3.0
		a.set_target_x(target)
		b.set_target_x(target)
		a.update(0.013)  # odd frame time: fixed step must hide it
		b.update(0.013)
	assert_eq(a.army.count, b.army.count)
	assert_eq(a.boss.hp, b.boss.hp)
	assert_eq(a.distance, b.distance)
