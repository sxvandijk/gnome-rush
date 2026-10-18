class_name Progress
extends RefCounted
## The player's progress: levels, stars, coins, upgrades, skins, daily
## challenge and endless record. Pure data and rules; SaveStore writes it.

const VERSION := 1
## Upgrade effect per level and maximum level. Costs: 30 x (level + 1)^1.5.
const UPGRADES := {
	"army": {"max": 20, "step": 5.0},  # Extra gnomes at the start
	"fire": {"max": 10, "step": 1.5},  # Extra acorns per second
	"damage": {"max": 10, "step": 0.1},  # Extra acorn damage on the boss
	"coins": {"max": 10, "step": 0.1},  # Extra share of coins
}
const BASE_FIRE_RATE := 5.0
const BASE_BOSS_DAMAGE := 0.25

var unlocked := 1
var stars := {}  # Level number as string -> best stars
var coins := 0
var upgrades := {"army": 0, "fire": 0, "damage": 0, "coins": 0}
var skins_owned: Array = ["classic"]
var skin := "classic"
var daily_claimed := ""  # Date of the last rewarded daily challenge
var endless_best := 0


func is_unlocked(n: int) -> bool:
	return n >= 1 and n <= unlocked


func stars_for(n: int) -> int:
	return int(stars.get(str(n), 0))


func total_stars() -> int:
	var total := 0
	for s in stars.values():
		total += int(s)
	return total


func complete_level(n: int, won_stars: int) -> void:
	stars[str(n)] = maxi(stars_for(n), won_stars)
	if n >= unlocked:
		unlocked = n + 1


func add_coins(amount: int) -> void:
	coins += maxi(amount, 0)


## -1 when the upgrade is at its maximum.
func upgrade_cost(kind: String) -> int:
	var level: int = upgrades[kind]
	if level >= UPGRADES[kind].max:
		return -1
	return floori(30.0 * pow(level + 1, 1.5))


func buy_upgrade(kind: String) -> bool:
	var cost := upgrade_cost(kind)
	if cost < 0 or coins < cost:
		return false
	coins -= cost
	upgrades[kind] += 1
	return true


func start_bonus() -> int:
	return roundi(upgrades.army * UPGRADES.army.step)


func fire_rate() -> float:
	return BASE_FIRE_RATE + upgrades.fire * UPGRADES.fire.step


func boss_damage() -> float:
	return BASE_BOSS_DAMAGE + upgrades.damage * UPGRADES.damage.step


func coin_multiplier() -> float:
	return 1.0 + upgrades.coins * UPGRADES.coins.step


func buy_skin(id: String) -> bool:
	var entry := Skins.get_skin(id)
	if entry.id != id or id in skins_owned or entry.price < 0 or coins < entry.price:
		return false
	coins -= entry.price
	skins_owned.append(id)
	return true


func select_skin(id: String) -> bool:
	if not id in skins_owned:
		return false
	skin = id
	return true


## True the first time on a given date: the daily reward is paid out once.
func claim_daily(date: String) -> bool:
	if daily_claimed == date:
		return false
	daily_claimed = date
	return true


## True for a new record.
func record_endless(rows: int) -> bool:
	if rows <= endless_best:
		return false
	endless_best = rows
	return true


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"unlocked": unlocked,
		"stars": stars.duplicate(),
		"coins": coins,
		"upgrades": upgrades.duplicate(),
		"skins_owned": skins_owned.duplicate(),
		"skin": skin,
		"daily_claimed": daily_claimed,
		"endless_best": endless_best,
	}


## Tolerant of missing or broken fields: anything odd falls back to defaults.
static func from_dict(data: Dictionary) -> Progress:
	var p := Progress.new()
	p.unlocked = maxi(_int(data.get("unlocked"), 1), 1)
	p.coins = maxi(_int(data.get("coins"), 0), 0)
	p.endless_best = maxi(_int(data.get("endless_best"), 0), 0)
	p.daily_claimed = str(data.get("daily_claimed", ""))
	var saved_stars = data.get("stars")
	if saved_stars is Dictionary:
		for key in saved_stars:
			p.stars[str(key)] = clampi(_int(saved_stars[key], 0), 0, 3)
	var saved_upgrades = data.get("upgrades")
	if saved_upgrades is Dictionary:
		for kind in UPGRADES:
			p.upgrades[kind] = clampi(_int(saved_upgrades.get(kind), 0), 0, UPGRADES[kind].max)
	var owned = data.get("skins_owned")
	if owned is Array:
		for id in owned:
			if Skins.get_skin(str(id)).id == str(id) and not str(id) in p.skins_owned:
				p.skins_owned.append(str(id))
	p.select_skin(str(data.get("skin", "classic")))
	return p


static func _int(value, fallback: int) -> int:
	if value is int or value is float:
		return int(value)
	return fallback
