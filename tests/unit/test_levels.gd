extends GutTest
## Every level in levels/ must pass the validator: the best route without
## shooting reaches the boss with at least 1.2x its hit points.

const LEVEL_DIR := "res://levels/"


func test_all_levels_fair_without_shooting() -> void:
	var files := Array(DirAccess.get_files_at(LEVEL_DIR)).filter(
		func(f: String) -> bool: return f.begins_with("level_") and f.ends_with(".json"))
	assert_eq(files.size(), LevelLoader.level_count())
	for file in files:
		var level := LevelData.load_json(LEVEL_DIR + file)
		assert_not_null(level, file)
		var result := LevelValidator.validate(level)
		gut.p("%s: best %d, needed %.0f" % [file, result.best, result.needed])
		assert_true(result.fair, "%s: best %d, needed %.0f" % [file, result.best, result.needed])


func test_level_files_match_generator() -> void:
	# Run tools/generate_levels.gd after changing the generator
	for n in [1, 20, 41, 60]:
		var expected := JSON.stringify(LevelGenerator.generate(n), "  ") + "\n"
		assert_eq(FileAccess.get_file_as_string(LevelLoader.path_for(n)), expected, "level %d" % n)
