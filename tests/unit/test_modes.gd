extends GutTest
## Daily challenge and endless mode.


# --- Daily challenge ---------------------------------------------------------

func test_daily_seed_from_date() -> void:
	assert_eq(Daily.seed_for("2026-10-18"), 20261018)


func test_daily_difficulty_follows_progress() -> void:
	assert_eq(Daily.difficulty_for(1), Daily.MIN_DIFFICULTY)
	assert_eq(Daily.difficulty_for(30), 30)


func test_same_day_same_level() -> void:
	var a := Daily.level_data("2026-10-18", 12)
	var b := Daily.level_data("2026-10-18", 12)
	assert_eq(JSON.stringify(a), JSON.stringify(b))
	assert_eq(a.id, "daily_2026-10-18")
	assert_eq(a.number, 12)


func test_other_day_other_level() -> void:
	assert_ne(JSON.stringify(Daily.level_data("2026-10-18", 12).gate_pairs),
		JSON.stringify(Daily.level_data("2026-10-19", 12).gate_pairs))


func test_daily_level_can_be_won() -> void:
	var level := LevelData.from_dict(Daily.level_data("2026-10-18", 12))
	assert_true(LevelValidator.validate(level).fair)


func test_daily_reward() -> void:
	assert_eq(Daily.reward(10), 100)


# --- Endless -----------------------------------------------------------------

func test_endless_has_many_rows_and_no_boss() -> void:
	var data := LevelGenerator.endless(7)
	assert_eq(data.gate_pairs.size(), LevelGenerator.ENDLESS_ROWS)
	assert_false(data.has("boss"))


func test_endless_is_reproducible() -> void:
	assert_eq(JSON.stringify(LevelGenerator.endless(7)), JSON.stringify(LevelGenerator.endless(7)))


func test_endless_gets_harder() -> void:
	var data := LevelGenerator.endless(7)
	var early_z: float = data.gate_pairs[9].z
	var sprinklers: Array = data.get("sprinklers", [])
	assert_eq(sprinklers.filter(func(s: Dictionary) -> bool: return s.z < early_z).size(), 0)
	assert_gt(sprinklers.size(), 0)
	assert_gt(data.gate_pairs.filter(func(p: Dictionary) -> bool: return p.has("shift")).size(), 0)


func test_rows_passed() -> void:
	var run := RunState.new(LevelData.from_dict(LevelGenerator.endless(7)))
	run.fire_rate = 0.0
	assert_eq(run.rows_passed(), 0)
	run.update(5.0)
	assert_gt(run.rows_passed(), 0)
