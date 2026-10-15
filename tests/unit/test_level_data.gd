extends GutTest


func _dict() -> Dictionary:
	return {
		"id": "t",
		"start_count": 7,
		"lane_half_width": 2.5,
		"length": 50.0,
		"speed": 4.0,
		"gate_pairs": [
			{"z": 30.0, "left": {"op": "add", "value": 1}, "right": {"op": "mul", "value": 2}},
			{"z": 10.0, "left": {"op": "div", "value": 2}, "right": {"op": "add", "value": -3}},
		],
	}


func test_from_dict_reads_fields() -> void:
	var level := LevelData.from_dict(_dict())
	assert_eq(level.id, "t")
	assert_eq(level.start_count, 7)
	assert_eq(level.lane_half_width, 2.5)
	assert_eq(level.length, 50.0)
	assert_eq(level.speed, 4.0)


func test_create_pairs_sorted_by_z() -> void:
	var pairs := LevelData.from_dict(_dict()).create_pairs()
	assert_eq(pairs.size(), 2)
	assert_eq(pairs[0].z, 10.0)
	assert_eq(pairs[1].z, 30.0)


func test_create_pairs_returns_fresh_pairs() -> void:
	var level := LevelData.from_dict(_dict())
	var first := level.create_pairs()
	first[0].apply(10, 0.0)
	assert_false(level.create_pairs()[0].used)


func test_load_test_level_from_disk() -> void:
	var level := LevelData.load_json("res://levels/test_001.json")
	assert_not_null(level)
	assert_eq(level.id, "test_001")
	assert_eq(level.create_pairs().size(), 5)


func test_load_missing_file_returns_null() -> void:
	assert_null(LevelData.load_json("res://levels/does_not_exist.json"))
