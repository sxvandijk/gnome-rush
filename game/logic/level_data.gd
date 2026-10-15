class_name LevelData
extends RefCounted
## A level as loaded from levels/*.json. Immutable description; call
## create_pairs() for fresh gate state at the start of each run.

var id := ""
var start_count := 10
var lane_half_width := 3.0
var length := 100.0
var speed := 6.0
var _pair_dicts: Array = []


static func from_dict(data: Dictionary) -> LevelData:
	var level := LevelData.new()
	level.id = str(data.get("id", ""))
	level.start_count = int(data.get("start_count", level.start_count))
	level.lane_half_width = float(data.get("lane_half_width", level.lane_half_width))
	level.length = float(data.get("length", level.length))
	level.speed = float(data.get("speed", level.speed))
	level._pair_dicts = data.get("gate_pairs", [])
	return level


## Returns null when the file is missing or not valid JSON.
static func load_json(path: String) -> LevelData:
	if not FileAccess.file_exists(path):
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return null
	return from_dict(data)


func create_pairs() -> Array[GatePair]:
	var pairs: Array[GatePair] = []
	for d in _pair_dicts:
		pairs.append(GatePair.from_dict(d))
	pairs.sort_custom(func(a: GatePair, b: GatePair) -> bool: return a.z < b.z)
	return pairs
