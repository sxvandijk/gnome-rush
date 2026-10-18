class_name Difficulty
extends RefCounted
## The difficulty curve: everything that gets harder over the levels depends
## only on the level number, through these functions. There is no last
## level: the curve keeps tightening and flattens out, so new levels can be
## added forever.
##
## margin(n) is how much room the best route without shooting has over the
## boss: best >= hp x (1 + margin). Generous early (75% in level 1), tight
## later (about 18% at 60, 8% at 100, 5% in the long run). Boss levels are a
## bit tighter, the level after a boss a bit looser (a breather). Never below
## MIN_MARGIN, so every level can be won; shooting adds room on top.

const FIRST_MARGIN := 0.75
const LATE_MARGIN := 0.05
## Levels over which most of the ramp happens (e-folding length).
const RAMP_LEVELS := 35.0
const MIN_MARGIN := 0.03
const MINI_BOSS_SQUEEZE := 0.8
const END_BOSS_SQUEEZE := 0.6
const BREATHER := 1.3
const LEVELS_PER_CHAPTER := 20
## For levels without a number (hand-made test levels)
const DEFAULT_MARGIN := 0.2


## 0.0 in level 1, approaching 1.0 the further you get.
static func progress(n: int) -> float:
	return 1.0 - exp(-maxf(n - 1, 0) / RAMP_LEVELS)


## From `easy` in level 1 towards `hard` in the long run.
static func ramp(n: int, easy: float, hard: float) -> float:
	return lerpf(easy, hard, progress(n))


static func margin(n: int) -> float:
	if n <= 0:
		return DEFAULT_MARGIN
	var m := ramp(n, FIRST_MARGIN, LATE_MARGIN)
	if n % LEVELS_PER_CHAPTER == 0:
		m *= END_BOSS_SQUEEZE
	elif n % 5 == 0:
		m *= MINI_BOSS_SQUEEZE
	elif n % 5 == 1 and n > 1:
		m *= BREATHER
	return maxf(m, MIN_MARGIN)


## Share of the best route the boss gets as hit points.
static func boss_factor(n: int) -> float:
	return 1.0 / (1.0 + margin(n))
