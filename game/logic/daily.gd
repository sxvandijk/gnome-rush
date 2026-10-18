class_name Daily
extends RefCounted
## The daily challenge: one generated level per date (seed yyyymmdd), as
## hard as the player's progress, rewarded once a day.

const MIN_DIFFICULTY := 5


static func seed_for(date: String) -> int:
	return int(date.replace("-", ""))


## Difficulty level: where the player is, but never a beginner level.
static func difficulty_for(unlocked: int) -> int:
	return maxi(unlocked, MIN_DIFFICULTY)


static func level_data(date: String, unlocked: int) -> Dictionary:
	var n := difficulty_for(unlocked)
	var data := LevelGenerator.generate(n, seed_for(date) * 100)
	data.id = "daily_" + date
	return data


static func reward(difficulty: int) -> int:
	return 50 + 5 * difficulty


## Today's date as yyyy-mm-dd (device local time).
static func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]
