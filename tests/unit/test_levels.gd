extends GutTest
## Plays every level in levels/ with a simple no-shooting autopilot and
## checks the fairness rule: the army reaches the boss with at least 1.2x
## its hit points. A greedy pilot is a lower bound for the best route, so
## passing here means the real best route passes too. (The full validator
## follows in M3.)

const LEVEL_DIR := "res://levels/"
const STEP := 1.0 / 60.0
const MARGIN := 1.2
## A mole group this close before a gate pair guards that gate.
const GUARD_DISTANCE := 6.0


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


## Deals with whatever comes first: a mole group (fight it when that pays
## off, otherwise steer to the far side) or a gate pair (take the better one).
func _pilot_target(run: RunState) -> float:
	var next_pair: GatePair = null
	for pair in run.pairs:
		if not pair.used:
			next_pair = pair
			break
	var next_moles: MoleGroup = null
	for group in run.moles:
		if not group.resolved or group.cage_waiting():
			next_moles = group
			break
	if next_moles and (next_pair == null or next_moles.z < next_pair.z):
		if next_moles.cage_waiting() or _fight_pays(run.army.count, next_moles, next_pair):
			return next_moles.x
		return -signf(next_moles.x) * run.army.x_limit if next_moles.x != 0.0 else run.army.x_limit
	if next_pair:
		var left := next_pair.left.apply(run.army.count)
		var right := next_pair.right.apply(run.army.count)
		return -3.0 if left > right else 3.0
	return run.army.center_x


func _fight_pays(count: int, group: MoleGroup, next_pair: GatePair) -> bool:
	if count <= group.count:
		return false
	var after_fight := count - group.count + group.cage
	if next_pair == null or next_pair.z - group.z > GUARD_DISTANCE:
		return after_fight > count
	# Guarded gate: compare fighting into the guarded side with dodging to the other
	var guarded := next_pair.left if group.x < 0.0 else next_pair.right
	var other := next_pair.right if group.x < 0.0 else next_pair.left
	return guarded.apply(after_fight) > other.apply(count)
