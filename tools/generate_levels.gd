extends SceneTree
## Writes levels/level_001.json ... level_060.json with LevelGenerator and
## prints a balance summary. Run from the project root:
##   godot --headless -s tools/generate_levels.gd            (write files)
##   godot --headless -s tools/generate_levels.gd -- --dry   (summary only)

const COUNT := 60
const OUT_DIR := "res://levels/"


func _init() -> void:
	var dry := "--dry" in OS.get_cmdline_user_args()
	print("lvl ch  rows  best   boss hp  kind             guard cage chase plain mower  seed")
	for n in range(1, COUNT + 1):
		var data := LevelGenerator.generate(n)
		var result := LevelValidator.validate(LevelData.from_dict(data))
		var moles: Array = data.get("moles", [])
		print("%3d %2d %5d %6d %9d  %-16s %5d %4d %5d %5d %5d %5d%s" % [
			n, data.chapter, data.gate_pairs.size(), result.best, data.boss.hp, data.boss.kind,
			moles.filter(func(m: Dictionary) -> bool: return m.get("guard", false)).size(),
			moles.filter(func(m: Dictionary) -> bool: return m.has("cage")).size(),
			moles.filter(func(m: Dictionary) -> bool: return m.has("chase")).size(),
			moles.filter(func(m: Dictionary) -> bool: return m.keys().size() == 3).size(),
			data.get("mowers", []).size(), data.seed,
			"" if result.fair else "  UNFAIR",
		])
		if not dry:
			var file := FileAccess.open(OUT_DIR + "level_%03d.json" % n, FileAccess.WRITE)
			file.store_string(JSON.stringify(data, "  ") + "\n")
	quit()
