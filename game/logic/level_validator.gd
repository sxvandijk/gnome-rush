class_name LevelValidator
extends RefCounted
## Works out the best route through a level without shooting or paid help
## and checks the fairness rule: that route must beat the boss with at least
## 20% to spare (hp x 1.2 <= best).
##
## 1. make_plan(): picks a side at every gate pair and decides per mole group
##    whether to fight. Every rule is monotone in the army size (more in, more
##    out), so taking the biggest army at each step is optimal.
## 2. best_route(): plays that plan in RunState without shooting, steering
##    around mowers and dodged moles. The army size at the boss is `best`: a
##    lower bound of the true optimum, so the check errs on the fair side.

const MARGIN := 1.2
## A mole group at most this far before a gate pair guards that gate: there
## is no room left to dodge it and still reach the gate behind it.
const GUARD_DISTANCE := 6.0
const GATE_X := 3.5
## Distance from a sliding split the pilot keeps when it aims for a side.
const GATE_SIDE_OFFSET := 1.5
const MOWER_LOOKAHEAD := 16.0
const MAX_TIME := 600.0


class Plan:
	var take_left: Array[bool] = []  # Per gate pair, sorted by z
	var fight: Array[bool] = []  # Per mole group, sorted by z
	## Army size at the end if mowers cost nothing.
	var expected := 0


static func make_plan(level: LevelData) -> Plan:
	var plan := Plan.new()
	var pairs := level.create_pairs()
	var moles := level.create_moles()
	plan.take_left.resize(pairs.size())
	plan.fight.resize(moles.size())
	var count := level.start_count
	var p := 0
	var m := 0
	while p < pairs.size() or m < moles.size():
		if m < moles.size() and (p >= pairs.size() or moles[m].z < pairs[p].z):
			var group := moles[m]
			if p < pairs.size() and pairs[p].z - group.z <= GUARD_DISTANCE:
				count = _plan_guard(plan, count, group, m, pairs[p], p)
				p += 1
			else:
				var fight := count > group.count and group.cage > group.count
				plan.fight[m] = fight
				if fight:
					count += group.cage - group.count
			m += 1
		else:
			var left := pairs[p].left.apply(count)
			var right := pairs[p].right.apply(count)
			plan.take_left[p] = left > right
			count = maxi(left, right)
			p += 1
	plan.expected = count
	return plan


## Guarded gate: fight through to the guarded side, or dodge to the other.
static func _plan_guard(plan: Plan, count: int, group: MoleGroup, m: int, pair: GatePair, p: int) -> int:
	var guarded_left := group.x < 0.0
	var guarded := pair.left if guarded_left else pair.right
	var other := pair.right if guarded_left else pair.left
	var dodge_count := other.apply(count)
	var fight_count := guarded.apply(count - group.count + group.cage) if count > group.count else -1
	var fight := fight_count > dodge_count
	plan.fight[m] = fight
	plan.take_left[p] = guarded_left == fight
	return fight_count if fight else dodge_count


## Army size when it reaches the boss (or the end of a boss-less level).
static func best_route(level: LevelData, plan: Plan = null) -> int:
	if plan == null:
		plan = make_plan(level)
	var run := RunState.new(level)
	run.fire_rate = 0.0
	var t := 0.0
	while not run.at_boss and not run.is_finished() and t < MAX_TIME:
		run.set_target_x(pilot_target(run, plan))
		run.update(RunState.STEP)
		t += RunState.STEP
	return run.army.count


## {fair: bool, best: int, needed: float} — needed is hp x 1.2.
static func validate(level: LevelData) -> Dictionary:
	var best := best_route(level)
	var boss := level.create_boss()
	var needed := boss.max_hp * MARGIN if boss else 1.0
	return {"fair": best > 0 and best >= needed, "best": best, "needed": needed}


static func is_fair(level: LevelData) -> bool:
	return validate(level).fair


## Where the autopilot steers: towards whatever comes next (gate side, a
## mole group to fight or a cage to collect, the far side to dodge), moved
## aside for a mower that crosses its path first.
static func pilot_target(run: RunState, plan: Plan) -> float:
	var target := run.army.center_x
	var event_z := INF
	for i in run.pairs.size():
		var pair := run.pairs[i]
		if not pair.used:
			# Aim at the chosen side of the split as it will be when we cross it
			var cross_time := run.time + maxf(0.0, pair.z - run.distance) / run.level.speed
			var split := pair.split_x(cross_time)
			target = split - GATE_SIDE_OFFSET if plan.take_left[i] else split + GATE_SIDE_OFFSET
			if pair.shift_amp == 0.0:
				target = -GATE_X if plan.take_left[i] else GATE_X
			event_z = pair.z
			break
	for i in run.moles.size():
		var group := run.moles[i]
		if group.resolved and not group.cage_waiting():
			continue
		if group.z >= event_z:
			break
		if plan.fight[i] or group.cage_waiting():
			target = group.x
		else:
			target = -signf(group.x) * run.army.x_limit if group.x != 0.0 else run.army.x_limit
		event_z = group.z
		break
	return _avoid_mowers(run, target, event_z)


static func _avoid_mowers(run: RunState, target: float, event_z: float) -> float:
	var r := run.army.radius()
	var reach_z := Mower.HALF_DEPTH + r
	for mower in run.mowers:
		var ahead := mower.z - run.distance
		if ahead < -reach_z or ahead > MOWER_LOOKAHEAD or mower.z > event_z:
			continue
		# Time window in which the army overlaps the mower's depth
		var speed := run.level.speed
		var t0 := run.time + maxf(0.0, ahead - reach_z) / speed
		var t1 := run.time + (ahead + reach_z) / speed
		var needed := Mower.HALF_WIDTH + r + 0.3
		var best_x := target
		var best_score := -INF
		for k in 35:
			var x := lerpf(-run.army.x_limit, run.army.x_limit, k / 34.0)
			var clearance := INF
			for s in 9:
				clearance = minf(clearance, absf(x - mower.x_at(lerpf(t0, t1, s / 8.0))))
			var score := minf(clearance, needed) - absf(x - target) * 0.01
			if score > best_score:
				best_score = score
				best_x = x
		return best_x
	return target
