class_name Difficulty
extends RefCounted
## The difficulty curve: everything that gets harder over the levels depends
## only on the level number, through these functions.
##
## margin(n) is how much room the best route without shooting has over the
## boss: best >= hp x (1 + margin). Generous early (75% in level 1), tight at
## the end (5% in level 60; boss levels tighter still), never zero, so every
## level can be won. Shooting gives the player extra room on top.

const LAST_LEVEL := 60
const FIRST_MARGIN := 0.75
const LAST_MARGIN := 0.05
const MIN_MARGIN := 0.03
const MINI_BOSS_SQUEEZE := 0.8
const END_BOSS_SQUEEZE := 0.6
## For levels without a number (hand-made test levels)
const DEFAULT_MARGIN := 0.2


## 0.0 in level 1, 1.0 in the last level.
static func progress(n: int) -> float:
	return clampf(float(n - 1) / (LAST_LEVEL - 1), 0.0, 1.0)


## Linear from `easy` in level 1 to `hard` in the last level.
static func ramp(n: int, easy: float, hard: float) -> float:
	return lerpf(easy, hard, progress(n))


static func margin(n: int) -> float:
	if n <= 0:
		return DEFAULT_MARGIN
	var m := ramp(n, FIRST_MARGIN, LAST_MARGIN)
	if n % 20 == 0:
		m *= END_BOSS_SQUEEZE
	elif n % 5 == 0:
		m *= MINI_BOSS_SQUEEZE
	return maxf(m, MIN_MARGIN)


## Share of the best route the boss gets as hit points.
static func boss_factor(n: int) -> float:
	return 1.0 / (1.0 + margin(n))
