class_name LevelData
extends RefCounted
## A level as loaded from levels/*.json. Immutable description; the create_*
## methods return fresh objects for each run. Defaults are the prototype's.

var id := ""
var number := 0
var chapter := 1
var start_count := 10
var lane_half_width := 6.0
var army_x_limit := 4.3
var length := 100.0
var speed := 9.0
## Best route without shooting, filled in by LevelLoader (for the stars).
var best := 0
var _pair_dicts: Array = []
var _mole_dicts: Array = []
var _mower_dicts: Array = []
var _sprinkler_dicts: Array = []
var _boss_dict: Dictionary = {}


static func from_dict(data: Dictionary) -> LevelData:
	var level := LevelData.new()
	level.id = str(data.get("id", ""))
	level.number = int(data.get("number", 0))
	level.chapter = int(data.get("chapter", 1))
	level.start_count = int(data.get("start_count", level.start_count))
	level.lane_half_width = float(data.get("lane_half_width", level.lane_half_width))
	level.army_x_limit = float(data.get("army_x_limit", level.army_x_limit))
	level.length = float(data.get("length", level.length))
	level.speed = float(data.get("speed", level.speed))
	level._pair_dicts = data.get("gate_pairs", [])
	level._mole_dicts = data.get("moles", [])
	level._mower_dicts = data.get("mowers", [])
	level._sprinkler_dicts = data.get("sprinklers", [])
	level._boss_dict = data.get("boss", {})
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


func create_moles() -> Array[MoleGroup]:
	var moles: Array[MoleGroup] = []
	for d in _mole_dicts:
		moles.append(MoleGroup.from_dict(d))
	moles.sort_custom(func(a: MoleGroup, b: MoleGroup) -> bool: return a.z < b.z)
	return moles


func create_mowers() -> Array[Mower]:
	var mowers: Array[Mower] = []
	for d in _mower_dicts:
		mowers.append(Mower.from_dict(d))
	return mowers


func create_sprinklers() -> Array[Sprinkler]:
	var sprinklers: Array[Sprinkler] = []
	for d in _sprinkler_dicts:
		sprinklers.append(Sprinkler.from_dict(d))
	return sprinklers


## Null when the level has no boss; it is then won at `length`.
func create_boss() -> Boss:
	return Boss.from_dict(_boss_dict) if not _boss_dict.is_empty() else null
