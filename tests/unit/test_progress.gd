extends GutTest


# --- Levels and stars --------------------------------------------------------

func test_new_progress() -> void:
	var p := Progress.new()
	assert_eq(p.unlocked, 1)
	assert_eq(p.coins, 0)
	assert_true(p.is_unlocked(1))
	assert_false(p.is_unlocked(2))
	assert_eq(p.stars_for(1), 0)
	assert_eq(p.skin, "classic")


func test_completing_current_level_unlocks_next() -> void:
	var p := Progress.new()
	p.complete_level(1, 2)
	assert_eq(p.unlocked, 2)
	assert_eq(p.stars_for(1), 2)


func test_replaying_old_level_keeps_best_stars() -> void:
	var p := Progress.new()
	p.complete_level(1, 3)
	p.complete_level(2, 1)
	p.complete_level(1, 1)
	assert_eq(p.stars_for(1), 3)
	assert_eq(p.unlocked, 3)


func test_total_stars() -> void:
	var p := Progress.new()
	p.complete_level(1, 3)
	p.complete_level(2, 2)
	assert_eq(p.total_stars(), 5)


# --- Upgrades ----------------------------------------------------------------

func test_upgrade_cost_follows_prototype() -> void:
	var p := Progress.new()
	assert_eq(p.upgrade_cost("army"), 30)  # 30 x 1^1.5
	p.upgrades.army = 3
	assert_eq(p.upgrade_cost("army"), 240)  # 30 x 4^1.5


func test_buy_upgrade() -> void:
	var p := Progress.new()
	p.coins = 100
	assert_true(p.buy_upgrade("fire"))
	assert_eq(p.upgrades.fire, 1)
	assert_eq(p.coins, 70)


func test_cannot_buy_without_coins() -> void:
	var p := Progress.new()
	p.coins = 10
	assert_false(p.buy_upgrade("army"))
	assert_eq(p.upgrades.army, 0)
	assert_eq(p.coins, 10)


func test_upgrade_max() -> void:
	var p := Progress.new()
	p.upgrades.fire = Progress.UPGRADES.fire.max
	p.coins = 1000000
	assert_eq(p.upgrade_cost("fire"), -1)
	assert_false(p.buy_upgrade("fire"))


func test_upgrade_effects() -> void:
	var p := Progress.new()
	assert_eq(p.start_bonus(), 0)
	assert_eq(p.fire_rate(), 5.0)
	assert_eq(p.boss_damage(), 0.25)
	assert_eq(p.coin_multiplier(), 1.0)
	p.upgrades = {"army": 2, "fire": 2, "damage": 2, "coins": 2}
	assert_eq(p.start_bonus(), 10)
	assert_eq(p.fire_rate(), 8.0)
	assert_almost_eq(p.boss_damage(), 0.45, 0.0001)
	assert_almost_eq(p.coin_multiplier(), 1.2, 0.0001)


# --- Skins -------------------------------------------------------------------

func test_buy_and_select_skin() -> void:
	var p := Progress.new()
	var skin: Dictionary = Skins.CATALOG.filter(func(s: Dictionary) -> bool: return s.price > 0)[0]
	p.coins = skin.price
	assert_false(p.select_skin(skin.id))
	assert_true(p.buy_skin(skin.id))
	assert_eq(p.coins, 0)
	assert_true(p.select_skin(skin.id))
	assert_eq(p.skin, skin.id)
	assert_false(p.buy_skin(skin.id))  # Already owned


func test_pack_skins_not_for_coins() -> void:
	var p := Progress.new()
	p.coins = 1000000
	var pack: Dictionary = Skins.CATALOG.filter(func(s: Dictionary) -> bool: return s.price < 0)[0]
	assert_false(p.buy_skin(pack.id))


func test_skin_catalog() -> void:
	assert_eq(Skins.get_skin("classic").price, 0)
	assert_eq(Skins.get_skin("nope").id, "classic")  # Unknown falls back


# --- Daily and endless -------------------------------------------------------

func test_daily_claimed_once_per_day() -> void:
	var p := Progress.new()
	assert_true(p.claim_daily("2026-10-18"))
	assert_false(p.claim_daily("2026-10-18"))
	assert_true(p.claim_daily("2026-10-19"))


func test_endless_record() -> void:
	var p := Progress.new()
	assert_true(p.record_endless(12))
	assert_false(p.record_endless(8))
	assert_eq(p.endless_best, 12)


# --- Saving ------------------------------------------------------------------

func test_round_trip() -> void:
	var p := Progress.new()
	p.complete_level(1, 3)
	p.complete_level(2, 2)
	p.coins = 345
	p.upgrades.army = 2
	p.skins_owned.append("forest")
	p.skin = "forest"
	p.claim_daily("2026-10-18")
	p.record_endless(7)
	var copy := Progress.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_eq(copy.to_dict(), p.to_dict())
	assert_eq(copy.stars_for(1), 3)
	assert_eq(copy.unlocked, 3)


func test_broken_save_gives_fresh_progress() -> void:
	assert_eq(Progress.from_dict({}).unlocked, 1)
	assert_eq(Progress.from_dict({"coins": "lots", "upgrades": 5}).coins, 0)
	var p := Progress.from_dict({"unlocked": 4, "upgrades": {"army": 99}})
	assert_eq(p.unlocked, 4)
	assert_eq(p.upgrades.army, Progress.UPGRADES.army.max)
	assert_eq(p.upgrades.fire, 0)
