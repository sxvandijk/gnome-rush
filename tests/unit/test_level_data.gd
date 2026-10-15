extends GutTest


func _dict() -> Dictionary:
	return {
		"id": "t",
		"start_count": 7,
		"lane_half_width": 6.0,
		"army_x_limit": 4.3,
		"length": 50.0,
		"speed": 9.0,
		"gate_pairs": [
			{"z": 30.0, "left": {"op": "add", "value": 1}, "right": {"op": "mul", "value": 2}},
			{"z": 10.0, "left": {"op": "div", "value": 2}, "right": {"op": "add", "value": -3}},
		],
		"moles": [{"z": 40.0, "x": 1.0, "count": 5}, {"z": 20.0, "x": -1.0, "count": 3}],
		"mowers": [{"z": 25.0, "speed": 1.5, "phase": 0.0}],
		"boss": {"z": 60.0, "hp": 9},
	}


func test_from_dict_reads_fields() -> void:
	var level := LevelData.from_dict(_dict())
	assert_eq(level.id, "t")
	assert_eq(level.start_count, 7)
	assert_eq(level.lane_half_width, 6.0)
	assert_eq(level.army_x_limit, 4.3)
	assert_eq(level.length, 50.0)
	assert_eq(level.speed, 9.0)


func test_prototype_defaults() -> void:
	var level := LevelData.from_dict({})
	assert_eq(level.lane_half_width, 6.0)
	assert_eq(level.army_x_limit, 4.3)
	assert_eq(level.speed, 9.0)
	assert_null(level.create_boss())
	assert_eq(level.create_moles().size(), 0)


func test_create_pairs_sorted_by_z() -> void:
	var pairs := LevelData.from_dict(_dict()).create_pairs()
	assert_eq(pairs.size(), 2)
	assert_eq(pairs[0].z, 10.0)
	assert_eq(pairs[1].z, 30.0)


func test_create_moles_sorted_by_z() -> void:
	var moles := LevelData.from_dict(_dict()).create_moles()
	assert_eq(moles.size(), 2)
	assert_eq(moles[0].z, 20.0)


func test_create_mowers_and_boss() -> void:
	var level := LevelData.from_dict(_dict())
	assert_eq(level.create_mowers().size(), 1)
	assert_eq(level.create_boss().hp, 9.0)


func test_create_returns_fresh_objects() -> void:
	var level := LevelData.from_dict(_dict())
	level.create_pairs()[0].apply(10, 0.0)
	assert_false(level.create_pairs()[0].used)
	level.create_boss().damage(5.0)
	assert_eq(level.create_boss().hp, 9.0)


func test_load_test_level_from_disk() -> void:
	var level := LevelData.load_json("res://levels/test_001.json")
	assert_not_null(level)
	assert_eq(level.id, "test_001")
	assert_eq(level.create_pairs().size(), 6)
	assert_not_null(level.create_boss())


func test_load_missing_file_returns_null() -> void:
	assert_null(LevelData.load_json("res://levels/does_not_exist.json"))
