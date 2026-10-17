class_name LevelLoader
extends RefCounted
## Loads levels for play. Every level goes through the validator first; one
## that breaks the fairness rule is never loaded.

const LEVEL_COUNT := 60
const LEVEL_DIR := "res://levels/"


static func path_for(n: int) -> String:
	return LEVEL_DIR + "level_%03d.json" % n


static func load_level(n: int) -> LevelData:
	return load_path(path_for(n))


## Null when the file is missing, broken or unfair.
static func load_path(path: String) -> LevelData:
	var level := LevelData.load_json(path)
	if level == null:
		return null
	var result := LevelValidator.validate(level)
	if not result.fair:
		push_warning("Refusing unfair level %s: best route %d, needs %.0f" % [path, result.best, result.needed])
		return null
	return level
