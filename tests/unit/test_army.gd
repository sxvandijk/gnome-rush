extends GutTest


func test_starts_with_count() -> void:
	var army := Army.new(10, 4.3)
	assert_eq(army.count, 10)
	assert_false(army.is_defeated())


func test_count_never_negative() -> void:
	assert_eq(Army.new(-4, 4.3).count, 0)


func test_pass_gate_pair_uses_center_x() -> void:
	var army := Army.new(10, 4.3)
	var pair := GatePair.new(Gate.new(Gate.Op.ADD, 5), Gate.new(Gate.Op.MUL, 3))
	army.set_center_x(-1.0)
	army.pass_gate_pair(pair)
	assert_eq(army.count, 15)


func test_defeated_at_zero() -> void:
	var army := Army.new(5, 4.3)
	army.pass_gate_pair(GatePair.new(Gate.new(Gate.Op.ADD, -10), Gate.new(Gate.Op.ADD, -10)))
	assert_eq(army.count, 0)
	assert_true(army.is_defeated())


func test_remove() -> void:
	var army := Army.new(5, 4.3)
	army.remove(2)
	assert_eq(army.count, 3)
	army.remove(10)
	assert_eq(army.count, 0)


func test_count_changed_signal() -> void:
	var army := Army.new(10, 4.3)
	watch_signals(army)
	army.pass_gate_pair(GatePair.new(Gate.new(Gate.Op.ADD, 2), Gate.new(Gate.Op.ADD, 2)))
	assert_signal_emitted_with_parameters(army, "count_changed", [12, 10])


func test_center_x_clamped_to_limit() -> void:
	var army := Army.new(1, 4.3)
	army.set_center_x(10.0)
	assert_eq(army.center_x, 4.3)
	army.set_center_x(-10.0)
	assert_eq(army.center_x, -4.3)
	army.set_center_x(1.25)
	assert_eq(army.center_x, 1.25)


func test_formation_has_one_offset_per_gnome() -> void:
	assert_eq(Army.formation(0).size(), 0)
	assert_eq(Army.formation(1).size(), 1)
	assert_eq(Army.formation(120).size(), 120)


func test_formation_first_gnome_in_center() -> void:
	assert_eq(Army.formation(1)[0], Vector2.ZERO)


func test_formation_point_matches_formation() -> void:
	var points := Army.formation(30)
	for i in points.size():
		assert_eq(Army.formation_point(i), points[i])


func test_formation_uses_prototype_spacing() -> void:
	assert_almost_eq(Army.formation_point(4).length(), 0.27 * 2.0, 0.0001)


func test_formation_is_stable_when_growing() -> void:
	# Existing gnomes keep their spot when the army grows, so nothing jumps.
	var small := Army.formation(10)
	var big := Army.formation(30)
	for i in small.size():
		assert_eq(small[i], big[i])


func test_formation_gnomes_do_not_overlap() -> void:
	var points := Army.formation(120)
	var min_dist := INF
	for i in points.size():
		for j in range(i + 1, points.size()):
			min_dist = minf(min_dist, points[i].distance_to(points[j]))
	assert_gt(min_dist, Army.SPACING * 0.6)


func test_collision_radius() -> void:
	assert_almost_eq(Army.radius_for(1), 0.27 + 0.3, 0.0001)
	assert_almost_eq(Army.radius_for(100), 0.27 * 10.0 + 0.3, 0.0001)
	# Capped at the number of visible gnomes
	assert_eq(Army.radius_for(500), Army.radius_for(120))
	assert_eq(Army.new(100, 4.3).radius(), Army.radius_for(100))
