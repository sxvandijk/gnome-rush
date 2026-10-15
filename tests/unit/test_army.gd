extends GutTest


func test_starts_with_count() -> void:
	var army := Army.new(10, 3.0)
	assert_eq(army.count, 10)
	assert_false(army.is_defeated())


func test_count_never_negative() -> void:
	assert_eq(Army.new(-4, 3.0).count, 0)


func test_pass_gate_pair_uses_center_x() -> void:
	var army := Army.new(10, 3.0)
	var pair := GatePair.new(Gate.new(Gate.Op.ADD, 5), Gate.new(Gate.Op.MUL, 3))
	army.set_center_x(-1.0)
	army.pass_gate_pair(pair)
	assert_eq(army.count, 15)


func test_defeated_at_zero() -> void:
	var army := Army.new(5, 3.0)
	army.pass_gate_pair(GatePair.new(Gate.new(Gate.Op.ADD, -10), Gate.new(Gate.Op.ADD, -10)))
	assert_eq(army.count, 0)
	assert_true(army.is_defeated())


func test_count_changed_signal() -> void:
	var army := Army.new(10, 3.0)
	watch_signals(army)
	army.pass_gate_pair(GatePair.new(Gate.new(Gate.Op.ADD, 2), Gate.new(Gate.Op.ADD, 2)))
	assert_signal_emitted_with_parameters(army, "count_changed", [12, 10])


func test_center_x_clamped_to_lane() -> void:
	var army := Army.new(1, 3.0)
	army.set_center_x(10.0)
	assert_eq(army.center_x, 3.0)
	army.set_center_x(-10.0)
	assert_eq(army.center_x, -3.0)
	army.set_center_x(1.25)
	assert_eq(army.center_x, 1.25)


func test_formation_has_one_offset_per_gnome() -> void:
	assert_eq(Army.formation(0).size(), 0)
	assert_eq(Army.formation(1).size(), 1)
	assert_eq(Army.formation(250).size(), 250)


func test_formation_first_gnome_in_center() -> void:
	assert_eq(Army.formation(1)[0], Vector2.ZERO)


func test_formation_is_deterministic() -> void:
	assert_eq(Army.formation(40), Army.formation(40))


func test_formation_is_stable_when_growing() -> void:
	# Existing gnomes keep their spot when the army grows, so nothing jumps.
	var small := Army.formation(10)
	var big := Army.formation(30)
	for i in small.size():
		assert_eq(small[i], big[i])


func test_formation_gnomes_do_not_overlap() -> void:
	var spacing := 0.5
	var points := Army.formation(100, spacing)
	var min_dist := INF
	for i in points.size():
		for j in range(i + 1, points.size()):
			min_dist = minf(min_dist, points[i].distance_to(points[j]))
	assert_gt(min_dist, spacing * 0.6)


func test_fitted_spacing_keeps_default_for_small_armies() -> void:
	assert_eq(Army.fitted_spacing(1, 3.0), Army.DEFAULT_SPACING)
	assert_eq(Army.fitted_spacing(10, 3.0), Army.DEFAULT_SPACING)


func test_fitted_spacing_keeps_big_armies_inside_radius() -> void:
	var spacing := Army.fitted_spacing(300, 2.7)
	assert_lt(spacing, Army.DEFAULT_SPACING)
	assert_almost_eq(Army.formation_radius(300, spacing), 2.7, 0.001)


func test_formation_radius_grows_with_count() -> void:
	assert_lt(Army.formation_radius(10), Army.formation_radius(100))
	assert_eq(Army.formation_radius(1), 0.0)
