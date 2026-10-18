extends SceneTree
## Writes levels/level_0001.json ... with LevelGenerator, plus
## levels/index.json with the level count, and prints a balance summary.
## Run from the project root:
##   godot --headless -s tools/generate_levels.gd                 (60 levels)
##   godot --headless -s tools/generate_levels.gd -- --count=200  (200 levels)
##   godot --headless -s tools/generate_levels.gd -- --dry        (summary only)

const DEFAULT_COUNT := 60


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var dry := "--dry" in args
	var count := DEFAULT_COUNT
	for arg in args:
		if arg.begins_with("--count="):
			count = int(arg.get_slice("=", 1))
	if not dry:
		DirAccess.make_dir_recursive_absolute(LevelLoader.LEVEL_DIR)
	print("  lvl ch  rows  best   boss hp  margin kind             guard cage chase plain mower   seed")
	for n in range(1, count + 1):
		var data := LevelGenerator.generate(n)
		var result := LevelValidator.validate(LevelData.from_dict(data))
		var moles: Array = data.get("moles", [])
		print("%5d %2d %5d %6d %9d %6.0f%%  %-16s %5d %4d %5d %5d %5d %6d%s" % [
			n, data.chapter, data.gate_pairs.size(), result.best, data.boss.hp, Difficulty.margin(n) * 100.0, data.boss.kind,
			moles.filter(func(m: Dictionary) -> bool: return m.get("guard", false)).size(),
			moles.filter(func(m: Dictionary) -> bool: return m.has("cage")).size(),
			moles.filter(func(m: Dictionary) -> bool: return m.has("chase")).size(),
			moles.filter(func(m: Dictionary) -> bool: return m.keys().size() == 3).size(),
			data.get("mowers", []).size(), data.seed,
			"" if result.fair else "  UNFAIR",
		])
		if not dry:
			var file := FileAccess.open(LevelLoader.path_for(n), FileAccess.WRITE)
			file.store_string(JSON.stringify(data, "  ") + "\n")
	if not dry:
		var index := FileAccess.open(LevelLoader.INDEX_PATH, FileAccess.WRITE)
		index.store_string(JSON.stringify({"count": count}, "  ") + "\n")
	quit()
