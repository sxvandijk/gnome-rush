extends GutTest


func test_progress_starts_at_zero_and_keeps_rising() -> void:
	assert_eq(Difficulty.progress(1), 0.0)
	assert_lt(Difficulty.progress(60), Difficulty.progress(100))
	assert_lt(Difficulty.progress(100), Difficulty.progress(500))
	assert_lt(Difficulty.progress(300), 1.0)


func test_margin_shrinks_from_easy_to_hard() -> void:
	assert_almost_eq(Difficulty.margin(1), 0.75, 0.0001)
	assert_almost_eq(Difficulty.margin(59), 0.05 + 0.7 * exp(-58.0 / 35.0), 0.0001)
	# Plain levels (not a boss, not right after one) only get harder
	var previous := INF
	for n in range(1, 400):
		if n % 5 == 0 or (n % 5 == 1 and n > 1):
			continue
		assert_lte(Difficulty.margin(n), previous, "level %d" % n)
		previous = Difficulty.margin(n)


func test_curve_flattens_out() -> void:
	assert_almost_eq(Difficulty.margin(1001), Difficulty.LATE_MARGIN * Difficulty.BREATHER, 0.001)
	assert_almost_eq(Difficulty.margin(1002), Difficulty.LATE_MARGIN, 0.001)


func test_boss_levels_are_tighter() -> void:
	assert_lt(Difficulty.margin(5), Difficulty.margin(4))
	assert_lt(Difficulty.margin(20), Difficulty.margin(19))
	assert_lt(Difficulty.margin(20), Difficulty.margin(15))


func test_level_after_a_boss_is_a_breather() -> void:
	assert_gt(Difficulty.margin(21), Difficulty.margin(20))
	assert_gt(Difficulty.margin(21), Difficulty.margin(22))


func test_margin_always_positive() -> void:
	# Every level stays beatable without shooting
	for n in range(1, 2000):
		assert_gte(Difficulty.margin(n), Difficulty.MIN_MARGIN, "level %d" % n)


func test_unnumbered_level_uses_default_margin() -> void:
	assert_eq(Difficulty.margin(0), Difficulty.DEFAULT_MARGIN)


func test_boss_factor() -> void:
	assert_almost_eq(Difficulty.boss_factor(1), 1.0 / 1.75, 0.0001)


func test_ramp() -> void:
	assert_eq(Difficulty.ramp(1, 0.1, 0.3), 0.1)
	assert_almost_eq(Difficulty.ramp(36, 0.1, 0.3), lerpf(0.1, 0.3, 1.0 - exp(-1.0)), 0.0001)
