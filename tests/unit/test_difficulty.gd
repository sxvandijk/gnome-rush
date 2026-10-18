extends GutTest


func test_progress_runs_from_first_to_last_level() -> void:
	assert_eq(Difficulty.progress(1), 0.0)
	assert_eq(Difficulty.progress(60), 1.0)
	assert_almost_eq(Difficulty.progress(30), 29.0 / 59.0, 0.0001)


func test_margin_shrinks_from_easy_to_hard() -> void:
	assert_almost_eq(Difficulty.margin(1), 0.75, 0.0001)
	assert_almost_eq(Difficulty.margin(59), lerpf(0.75, 0.05, 58.0 / 59.0), 0.0001)
	var previous := INF
	for n in range(1, 61):
		if n % 5 == 0:
			continue
		assert_lt(Difficulty.margin(n), previous, "level %d" % n)
		previous = Difficulty.margin(n)


func test_boss_levels_are_tighter() -> void:
	assert_almost_eq(Difficulty.margin(5), lerpf(0.75, 0.05, 4.0 / 59.0) * 0.8, 0.0001)
	assert_almost_eq(Difficulty.margin(60), 0.03, 0.0001)
	assert_lt(Difficulty.margin(20), Difficulty.margin(19))


func test_margin_always_positive() -> void:
	# Every level stays beatable without shooting
	for n in range(1, 61):
		assert_gte(Difficulty.margin(n), Difficulty.MIN_MARGIN, "level %d" % n)


func test_unnumbered_level_uses_default_margin() -> void:
	assert_eq(Difficulty.margin(0), Difficulty.DEFAULT_MARGIN)


func test_boss_factor() -> void:
	assert_almost_eq(Difficulty.boss_factor(1), 1.0 / 1.75, 0.0001)
	assert_almost_eq(Difficulty.boss_factor(60), 1.0 / 1.03, 0.0001)


func test_ramp() -> void:
	assert_eq(Difficulty.ramp(1, 0.1, 0.3), 0.1)
	assert_eq(Difficulty.ramp(60, 0.1, 0.3), 0.3)
