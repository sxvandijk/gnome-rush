extends GutTest


func _pair() -> GatePair:
	return GatePair.new(Gate.new(Gate.Op.ADD, -5), Gate.new(Gate.Op.MUL, 2))


func test_army_left_of_center_takes_left_gate() -> void:
	assert_eq(_pair().apply(10, -0.5), 5)


func test_army_right_of_center_takes_right_gate() -> void:
	assert_eq(_pair().apply(10, 0.5), 20)


func test_army_exactly_on_center_takes_right_gate() -> void:
	assert_eq(_pair().apply(10, 0.0), 20)


func test_pair_applies_only_once() -> void:
	var pair := _pair()
	assert_eq(pair.apply(10, 1.0), 20)
	assert_true(pair.used)
	assert_eq(pair.apply(20, 1.0), 20)


func test_gate_for_x() -> void:
	var pair := _pair()
	assert_eq(pair.gate_for_x(-2.0), pair.left)
	assert_eq(pair.gate_for_x(2.0), pair.right)


func test_from_dict() -> void:
	var pair := GatePair.from_dict({
		"z": 30.0,
		"left": {"op": "add", "value": 10},
		"right": {"op": "div", "value": 2},
	})
	assert_eq(pair.z, 30.0)
	assert_eq(pair.left.label(), "+10")
	assert_eq(pair.right.label(), "÷2")
