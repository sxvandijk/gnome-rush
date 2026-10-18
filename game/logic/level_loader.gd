class_name LevelLoader
extends RefCounted
## Loads levels for play. Every level goes through the validator first; one
## that the difficulty curve says cannot be won is never loaded. The number
## of levels comes from levels/index.json, so levels can be added freely.

const LEVEL_DIR := "res://levels/"
const INDEX_PATH := "res://levels/index.json"


static func path_for(n: int) -> String:
	return LEVEL_DIR + "level_%04d.json" % n


static func level_count() -> int:
	var index = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	return int(index.get("count", 0)) if index is Dictionary else 0


static func load_level(n: int) -> LevelData:
	return load_path(path_for(n))


## Null when the file is missing, broken or cannot be won.
static func load_path(path: String) -> LevelData:
	var level := LevelData.load_json(path)
	if level == null:
		return null
	var result := LevelValidator.validate(level)
	if not result.fair:
		push_warning("Refusing level %s: best route %d, needs %.0f" % [path, result.best, result.needed])
		return null
	return level
