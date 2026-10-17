extends GutTest


func test_path_for_level() -> void:
	assert_eq(LevelLoader.path_for(1), "res://levels/level_001.json")
	assert_eq(LevelLoader.path_for(60), "res://levels/level_060.json")


func test_loads_a_fair_level() -> void:
	var level := LevelLoader.load_path("res://tests/fixtures/test_001.json")
	assert_not_null(level)
	assert_eq(level.id, "test_001")


func test_refuses_an_unfair_level() -> void:
	var level := LevelLoader.load_path("res://tests/fixtures/unfair.json")
	assert_null(level)
	assert_push_error_count(0)  # Refusal is a warning, not an error


func test_missing_level_is_null() -> void:
	assert_null(LevelLoader.load_path("res://levels/nope.json"))


func test_level_count() -> void:
	assert_eq(LevelLoader.LEVEL_COUNT, 60)
	assert_true(FileAccess.file_exists(LevelLoader.path_for(LevelLoader.LEVEL_COUNT)))
	assert_false(FileAccess.file_exists(LevelLoader.path_for(LevelLoader.LEVEL_COUNT + 1)))
