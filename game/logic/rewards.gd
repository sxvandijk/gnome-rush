class_name Rewards
extends RefCounted
## Stars and coins for a won level.

const THREE_STARS := 0.6
const TWO_STARS := 0.25


## 1–3 stars for a win (0 for a loss). Measured against what the best route
## without shooting would leave over after the boss: best − hp.
static func stars(remaining: int, best: int, hp: float) -> int:
	if remaining <= 0:
		return 0
	var ideal := maxf(best - hp, 1.0)
	var share := remaining / ideal
	if share >= THREE_STARS:
		return 3
	if share >= TWO_STARS:
		return 2
	return 1


## Our armies run into the thousands, so the leftover army counts by its
## square root (the prototype added it in full).
static func coins(level: int, remaining: int, stars_won: int, moles_defeated: int, multiplier: float) -> int:
	var base := 10.0 + 5.0 * level + 3.0 * sqrt(float(maxi(remaining, 0))) + 5.0 * stars_won + moles_defeated / 10
	return floori(base * multiplier)
