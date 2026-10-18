extends GutTest


func test_path_for_level() -> void:
	assert_eq(LevelLoader.path_for(1), "res://levels/level_0001.json")
	assert_eq(LevelLoader.path_for(60), "res://levels/level_0060.json")
	assert_eq(LevelLoader.path_for(1234), "res://levels/level_1234.json")


func test_loads_a_fair_level() -> void:
	var level := LevelLoader.load_path("res://tests/fixtures/test_001.json")
	assert_not_null(level)
	assert_eq(level.id, "test_001")
	assert_gt(level.best, 0)


func test_refuses_an_unfair_level() -> void:
	var level := LevelLoader.load_path("res://tests/fixtures/unfair.json")
	assert_null(level)
	assert_push_error_count(0)  # Refusal is a warning, not an error


func test_missing_level_is_null() -> void:
	assert_null(LevelLoader.load_path("res://levels/nope.json"))


func test_level_count_from_index() -> void:
	var count := LevelLoader.level_count()
	assert_gte(count, 60)
	assert_true(FileAccess.file_exists(LevelLoader.path_for(count)))
	assert_false(FileAccess.file_exists(LevelLoader.path_for(count + 1)))
