class_name LevelGenerator
extends RefCounted
## Builds level n from seed n (values from docs/prototype-waarden.md and the
## design tables in PLAN.md). Obstacles get more frequent and stronger with
## the level number (Difficulty), and the boss gets its hit points from the
## validator's best route and Difficulty.margin(n). If a layout cannot work
## (army wiped out, too small), the next sub-seed is tried. Same number, same
## level, on every device.

const START_COUNT := 10
const FIRST_ROW_Z := 32.0
const ROW_SPACING := 26.0
const BOSS_GAP := 14.0
const GUARD_OFFSET := 3.0
const GUARD_X := 2.0
const MAX_ATTEMPTS := 20
const MUL_LIMIT := 2000
## A layout whose best route ends below this is too weak: next sub-seed.
const MIN_BEST := 50
const ENDLESS_ROWS := 120
const LEVELS_PER_CHAPTER := 20

const MINI_BOSSES := ["cat", "magpie", "sprinkler_robot"]
const END_BOSSES := ["mole_king_xl", "flamingo_queen", "koi_emperor"]

# The level each variant first appears at; chances per row ramp up from the
# first value (level 1) towards the second (long run), see chance()
const GUARD_FROM := 2
const GUARD_CHANCE := [0.15, 0.35]
const MOWER_FROM := 3
const MOWER_CHANCE := [0.08, 0.25]
const CAGE_FROM := 4
const CAGE_CHANCE := [0.12, 0.22]
const CHASE_FROM := 8
const CHASE_CHANCE := [0.08, 0.22]
const PLAIN_MOLE_CHANCE := [0.05, 0.05]
const BAD_GATE_CHANCE := [0.45, 0.65]
# Chapter mechanics
const SPRINKLER_CHANCE := [0.3, 0.5]
const SPRINKLER_OFFSET := 5.0
const SHIFT_CHANCE := [0.35, 0.55]


## seed_base: -1 for the regular level n (seed n x 1000); the daily
## challenge passes its own.
static func generate(n: int, seed_base := -1) -> Dictionary:
	var data := {}
	for attempt in MAX_ATTEMPTS:
		data = _layout(n, (n * 1000 if seed_base < 0 else seed_base) + attempt)
		var level := LevelData.from_dict(data)
		var best := LevelValidator.best_route(level)
		var hp := floorf(maxf(best * Difficulty.boss_factor(n), boss_min_hp(n)))
		if best >= MIN_BEST and hp * (1.0 + Difficulty.margin(n)) <= best:
			data.boss.hp = hp
			return data
	push_error("Level %d: no fair layout in %d attempts" % [n, MAX_ATTEMPTS])
	return data


static func chapter(n: int) -> int:
	return (n - 1) / LEVELS_PER_CHAPTER + 1


static func boss_kind(n: int) -> String:
	if n % LEVELS_PER_CHAPTER == 0:
		return END_BOSSES[(chapter(n) - 1) % END_BOSSES.size()]
	if n % 5 == 0:
		return MINI_BOSSES[(n / 5 - 1 - n / LEVELS_PER_CHAPTER) % MINI_BOSSES.size()]
	return "mole_king"


## Chance per row for level n, from an [easy, hard] pair.
static func chance(n: int, range_: Array) -> float:
	return Difficulty.ramp(n, range_[0], range_[1])


static func boss_min_hp(n: int) -> float:
	return 8.0 if n % 5 == 0 else 5.0


static func cage_ratio(n: int) -> float:
	return maxf(1.1, 1.5 - 0.01 * (n - CAGE_FROM))


static func sprinkler_push(n: int) -> float:
	return minf(10.0, 6.0 + 0.1 * (n - LEVELS_PER_CHAPTER - 1))


static func chase_speed(n: int) -> float:
	return minf(2.0, 0.6 + 0.03 * n)


## Endless mode: rows keep coming, each one as hard as level 1 + 2 x row,
## and there is no boss. Score is the number of rows passed.
static func endless(seed: int, rows := ENDLESS_ROWS) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var parts := {"pairs": [], "moles": [], "mowers": [], "sprinklers": []}
	var best := START_COUNT
	for r in rows:
		best = _add_row(rng, 1 + 2 * r, FIRST_ROW_Z + r * ROW_SPACING, best, r == rows - 1, parts)
	var data := {
		"id": "endless_%d" % seed,
		"seed": seed,
		"start_count": START_COUNT,
		"length": FIRST_ROW_Z + rows * ROW_SPACING,
		"gate_pairs": parts.pairs,
	}
	for key in ["moles", "mowers", "sprinklers"]:
		if not parts[key].is_empty():
			data[key] = parts[key]
	return data


static func _layout(n: int, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rows := 5 + mini(n, 8)
	var parts := {"pairs": [], "moles": [], "mowers": [], "sprinklers": []}
	# Rough, cautious estimate of the army so far, to size the moles like the
	# prototype: best gates, chasers assumed to catch the army
	var best := START_COUNT
	for r in rows:
		best = _add_row(rng, n, FIRST_ROW_Z + r * ROW_SPACING, best, r == rows - 1, parts)
	var pairs: Array = parts.pairs
	var moles: Array = parts.moles
	var mowers: Array = parts.mowers
	var sprinklers: Array = parts.sprinklers

	var boss_z: float = pairs[-1].z + BOSS_GAP
	var data := {
		"id": "level_%03d" % n,
		"number": n,
		"chapter": chapter(n),
		"seed": seed,
		"start_count": START_COUNT,
		"length": boss_z,
		"gate_pairs": pairs,
		# Placeholder hp so the validator run reaches the boss; set in generate()
		"boss": {"z": boss_z, "hp": 1e9, "kind": boss_kind(n)},
	}
	if not moles.is_empty():
		data.moles = moles
	if not mowers.is_empty():
		data.mowers = mowers
	if not sprinklers.is_empty():
		data.sprinklers = sprinklers
	return data


## One gate row at depth z for difficulty level n, with what goes with it:
## sliding split, sprinkler, guard, and the obstacle halfway to the next
## row. Returns the updated army estimate.
static func _add_row(rng: RandomNumberGenerator, n: int, z: float, best: int, last_row: bool, parts: Dictionary) -> int:
	var pairs: Array = parts.pairs
	var moles: Array = parts.moles
	var mowers: Array = parts.mowers
	var sprinklers: Array = parts.sprinklers
	var good := _good_gate(rng, n, best)
	var other := _bad_gate(rng, n) if rng.randf() < chance(n, BAD_GATE_CHANCE) else _good_gate(rng, n, best)
	var good_left := rng.randf() < 0.5
	var pair := {"z": z, "left": good if good_left else other, "right": other if good_left else good}
	pairs.append(pair)

	if chapter(n) >= 3 and rng.randf() < chance(n, SHIFT_CHANCE):
		pair.shift = {
			"amp": snappedf(rng.randf_range(1.0, 2.0), 0.01),
			"speed": snappedf(rng.randf_range(0.8, 1.4) + 0.01 * (n - 40), 0.01),
			"phase": snappedf(rng.randf_range(0.0, TAU), 0.01),
		}
	if chapter(n) >= 2 and rng.randf() < chance(n, SPRINKLER_CHANCE):
		sprinklers.append({
			"z": z - SPRINKLER_OFFSET,
			"push": snappedf(sprinkler_push(n), 0.01),
			"speed": snappedf(rng.randf_range(1.0, 2.0), 0.01),
			"phase": snappedf(rng.randf_range(0.0, TAU), 0.01),
		})

	# A sliding split would let the guard end up on the wrong side
	if n >= GUARD_FROM and not pair.has("shift") and rng.randf() < chance(n, GUARD_CHANCE):
		var left := Gate.from_dict(pair.left).apply(best)
		var right := Gate.from_dict(pair.right).apply(best)
		moles.append({
			"z": z - GUARD_OFFSET,
			"x": -GUARD_X if left > right else GUARD_X,
			"count": _mole_count(rng, best),
			"guard": true,
		})
	best = maxi(Gate.from_dict(pair.left).apply(best), Gate.from_dict(pair.right).apply(best))

	if not last_row:
		best = _mid_obstacle(rng, n, z + ROW_SPACING * 0.5, best, moles, mowers)
	return best


## At most one obstacle halfway between two rows. Returns the updated
## army estimate.
static func _mid_obstacle(rng: RandomNumberGenerator, n: int, z: float, best: int, moles: Array, mowers: Array) -> int:
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	if n >= CHASE_FROM and rng.randf() < chance(n, CHASE_CHANCE):
		var count := maxi(2, roundi(best * rng.randf_range(0.10, 0.30)))
		moles.append({"z": z, "x": side * 3.0, "count": count, "chase": snappedf(chase_speed(n), 0.01)})
		return best - count
	elif n >= CAGE_FROM and rng.randf() < chance(n, CAGE_CHANCE):
		var count := maxi(2, roundi(best * rng.randf_range(0.25, 0.5)))
		var cage := floori(count * cage_ratio(n))
		moles.append({
			"z": z,
			"x": snappedf(side * rng.randf_range(1.5, 3.0), 0.1),
			"count": count,
			"cage": cage,
		})
		return best + cage - count
	elif n >= MOWER_FROM and rng.randf() < chance(n, MOWER_CHANCE):
		mowers.append({
			"z": z,
			"speed": snappedf(rng.randf_range(1.3, 2.1) + 0.05 * n, 0.01),
			"phase": snappedf(rng.randf_range(0.0, TAU), 0.01),
		})
	elif n >= GUARD_FROM and rng.randf() < chance(n, PLAIN_MOLE_CHANCE):
		moles.append({"z": z, "x": snappedf(rng.randf_range(-2.0, 2.0), 0.1), "count": _mole_count(rng, best)})
	return best


static func _mole_count(rng: RandomNumberGenerator, best: int) -> int:
	return maxi(2, roundi(best * rng.randf_range(0.25, 0.55)))


static func _good_gate(rng: RandomNumberGenerator, n: int, best: int) -> Dictionary:
	# No more multiplying once the army is big: keeps numbers and fights sane
	if rng.randf() < 0.28 and best < MUL_LIMIT:
		var triple := rng.randf() >= 0.75 and best < 250
		return {"op": "mul", "value": 3 if triple else 2}
	return {"op": "add", "value": rng.randi_range(5, 14 + 3 * n)}


static func _bad_gate(rng: RandomNumberGenerator, n: int) -> Dictionary:
	if rng.randf() < 0.30:
		return {"op": "div", "value": 2}
	return {"op": "add", "value": -rng.randi_range(5, 12 + 2 * n)}
