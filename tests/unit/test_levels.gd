extends GutTest
## Plays every level in levels/ with a simple no-shooting autopilot and
## checks the fairness rule: the army reaches the boss with at least 1.2x
## its hit points. A greedy pilot is a lower bound for the best route, so
## passing here means the real best route passes too. (The full validator
## follows in M3.)

const LEVEL_DIR := "res://levels/"
const STEP := 1.0 / 60.0
const MARGIN := 1.2


func test_all_levels_fair_without_shooting() -> void:
	var files := DirAccess.get_files_at(LEVEL_DIR)
	assert_gt(files.size(), 0)
	for file in files:
		if not file.ends_with(".json"):
			continue
		var level := LevelData.load_json(LEVEL_DIR + file)
		assert_not_null(level, file)
		var arrived := _army_at_boss(level)
		var boss := level.create_boss()
		gut.p("%s: army %d at boss, boss hp %s" % [file, arrived, boss.max_hp if boss else "-"])
		if boss:
			assert_true(arrived >= boss.max_hp * MARGIN,
				"%s: army %d at boss, needs %.0f (hp %.0f x %.1f)" % [file, arrived, boss.max_hp * MARGIN, boss.max_hp, MARGIN])
		else:
			assert_gt(arrived, 0, file)


## Army size on arrival at the boss (or at the end of a boss-less level).
func _army_at_boss(level: LevelData) -> int:
	var run := RunState.new(level)
	run.fire_rate = 0.0
	var t := 0.0
	while not run.at_boss and not run.is_finished() and t < 300.0:
		run.set_target_x(_pilot_target(run))
		run.update(STEP)
		t += STEP
	return run.army.count


## Heads for the better gate of the next pair, unless a mole group comes
## first: then it steers to the far side of the lane.
func _pilot_target(run: RunState) -> float:
	var next_pair: GatePair = null
	for pair in run.pairs:
		if not pair.used:
			next_pair = pair
			break
	var next_moles: MoleGroup = null
	for group in run.moles:
		if not group.resolved:
			next_moles = group
			break
	if next_moles and (next_pair == null or next_moles.z < next_pair.z):
		return -signf(next_moles.x) * run.army.x_limit if next_moles.x != 0.0 else run.army.x_limit
	if next_pair:
		var left := next_pair.left.apply(run.army.count)
		var right := next_pair.right.apply(run.army.count)
		return -3.0 if left > right else 3.0
	return run.army.center_x
