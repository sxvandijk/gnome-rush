extends Node
## Autoload "Game": the player's progress (saved after every change), which
## mode and level is being played, and scene switching.

enum Mode { LEVEL, DAILY, ENDLESS }

const RUN_SCENE := "res://game/scenes/run.tscn"
const MAP_SCENE := "res://game/scenes/level_map.tscn"
const SHOP_SCENE := "res://game/scenes/shop.tscn"
const SAVE_PATH := "user://progress.json"
const ENDLESS_COINS_PER_ROW := 2

var progress := Progress.new()
var mode := Mode.LEVEL
var current_level := 1


func _ready() -> void:
	load_progress()
	# Development: `godot -- --level=25` starts straight in level 25
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			play.call_deferred(int(arg.get_slice("=", 1)), true)
		elif arg == "--daily":
			play_daily.call_deferred()
		elif arg == "--endless":
			play_endless.call_deferred()


func load_progress() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)) if FileAccess.file_exists(SAVE_PATH) else null
	progress = Progress.from_dict(data) if data is Dictionary else Progress.new()


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(progress.to_dict()))


func play(n: int, ignore_lock := false) -> void:
	if not ignore_lock and not progress.is_unlocked(n):
		return
	mode = Mode.LEVEL
	current_level = clampi(n, 1, LevelLoader.level_count())
	get_tree().change_scene_to_file(RUN_SCENE)


func play_daily() -> void:
	mode = Mode.DAILY
	get_tree().change_scene_to_file(RUN_SCENE)


func play_endless() -> void:
	mode = Mode.ENDLESS
	get_tree().change_scene_to_file(RUN_SCENE)


func has_next() -> bool:
	return mode == Mode.LEVEL and current_level < LevelLoader.level_count()


func play_next() -> void:
	play(current_level + 1)


func show_map() -> void:
	get_tree().change_scene_to_file(MAP_SCENE)


func show_shop() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE)


func run_title() -> String:
	match mode:
		Mode.DAILY:
			return "Dagelijkse uitdaging"
		Mode.ENDLESS:
			return "Eindeloos"
	return "Level %d" % current_level


## The level for the current mode, checked by the validator; null if broken.
func level_for_run() -> LevelData:
	match mode:
		Mode.DAILY:
			return LevelLoader.load_dict(Daily.level_data(Daily.today(), progress.unlocked))
		Mode.ENDLESS:
			return LevelData.from_dict(LevelGenerator.endless(Daily.seed_for(Daily.today())))
	return LevelLoader.load_level(current_level)


## Pays out a finished run and saves. Returns what the result screen shows:
## {won, stars, coins, record, rows}.
func finish_run(run: RunState) -> Dictionary:
	var result := {"won": run.is_won(), "stars": 0, "coins": 0, "record": false, "rows": run.rows_passed()}
	match mode:
		Mode.ENDLESS:
			result.won = false
			result.record = progress.record_endless(result.rows)
			result.coins = floori(result.rows * ENDLESS_COINS_PER_ROW * progress.coin_multiplier())
		Mode.DAILY:
			if result.won:
				result.stars = Rewards.stars(run.army.count, run.level.best, run.boss.max_hp)
				if progress.claim_daily(Daily.today()):
					result.coins = floori(Daily.reward(run.level.number) * progress.coin_multiplier())
		Mode.LEVEL:
			if result.won:
				result.stars = Rewards.stars(run.army.count, run.level.best, run.boss.max_hp if run.boss else 0.0)
				result.coins = Rewards.coins(current_level, run.army.count, result.stars, run.moles_defeated, progress.coin_multiplier())
				progress.complete_level(current_level, result.stars)
	progress.add_coins(result.coins)
	save()
	return result
