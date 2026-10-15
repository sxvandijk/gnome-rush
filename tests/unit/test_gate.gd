extends GutTest


func test_add_gate_adds() -> void:
	assert_eq(Gate.new(Gate.Op.ADD, 5).apply(10), 15)


func test_negative_add_gate_subtracts() -> void:
	assert_eq(Gate.new(Gate.Op.ADD, -4).apply(10), 6)


func test_subtract_never_goes_below_zero() -> void:
	assert_eq(Gate.new(Gate.Op.ADD, -20).apply(7), 0)


func test_multiply() -> void:
	assert_eq(Gate.new(Gate.Op.MUL, 3).apply(7), 21)


func test_divide_rounds_down() -> void:
	assert_eq(Gate.new(Gate.Op.DIV, 2).apply(7), 3)


func test_divide_can_reach_zero() -> void:
	assert_eq(Gate.new(Gate.Op.DIV, 4).apply(3), 0)


func test_mul_and_div_values_are_at_least_one() -> void:
	assert_eq(Gate.new(Gate.Op.MUL, 0).value, 1)
	assert_eq(Gate.new(Gate.Op.DIV, -3).value, 1)


func test_acorn_raises_add_gate_by_one() -> void:
	var gate := Gate.new(Gate.Op.ADD, -20)
	gate.hit_by_acorn()
	assert_eq(gate.value, -19)


func test_acorn_turns_minus_twenty_into_plus_five() -> void:
	var gate := Gate.new(Gate.Op.ADD, -20)
	for i in 25:
		gate.hit_by_acorn()
	assert_eq(gate.value, 5)
	assert_eq(gate.apply(10), 15)


func test_acorn_does_not_change_mul_or_div() -> void:
	var mul := Gate.new(Gate.Op.MUL, 2)
	var div := Gate.new(Gate.Op.DIV, 3)
	mul.hit_by_acorn()
	div.hit_by_acorn()
	assert_eq(mul.value, 2)
	assert_eq(div.value, 3)


func test_label() -> void:
	assert_eq(Gate.new(Gate.Op.ADD, 5).label(), "+5")
	assert_eq(Gate.new(Gate.Op.ADD, -20).label(), "−20")
	assert_eq(Gate.new(Gate.Op.ADD, 0).label(), "+0")
	assert_eq(Gate.new(Gate.Op.MUL, 3).label(), "×3")
	assert_eq(Gate.new(Gate.Op.DIV, 2).label(), "÷2")


func test_is_positive() -> void:
	assert_true(Gate.new(Gate.Op.ADD, 1).is_positive())
	assert_false(Gate.new(Gate.Op.ADD, -1).is_positive())
	assert_false(Gate.new(Gate.Op.ADD, 0).is_positive())
	assert_true(Gate.new(Gate.Op.MUL, 2).is_positive())
	assert_false(Gate.new(Gate.Op.MUL, 1).is_positive())
	assert_false(Gate.new(Gate.Op.DIV, 2).is_positive())


func test_from_dict() -> void:
	var gate := Gate.from_dict({"op": "add", "value": -3})
	assert_eq(gate.op, Gate.Op.ADD)
	assert_eq(gate.value, -3)
	assert_eq(Gate.from_dict({"op": "mul", "value": 2}).op, Gate.Op.MUL)
	assert_eq(Gate.from_dict({"op": "div", "value": 2}).op, Gate.Op.DIV)
