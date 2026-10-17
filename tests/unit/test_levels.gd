extends GutTest
## Every level in levels/ must pass the validator: the best route without
## shooting reaches the boss with at least 1.2x its hit points.

const LEVEL_DIR := "res://levels/"


func test_all_levels_fair_without_shooting() -> void:
	var files := DirAccess.get_files_at(LEVEL_DIR)
	assert_gt(files.size(), 0)
	for file in files:
		if not file.ends_with(".json"):
			continue
		var level := LevelData.load_json(LEVEL_DIR + file)
		assert_not_null(level, file)
		var result := LevelValidator.validate(level)
		gut.p("%s: best %d, needed %.0f" % [file, result.best, result.needed])
		assert_true(result.fair, "%s: best %d, needed %.0f" % [file, result.best, result.needed])
