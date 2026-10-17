extends GutTest

# Generating runs the validator, so cache levels shared between tests.
var _cache := {}


func _gen(n: int) -> Dictionary:
	if not _cache.has(n):
		_cache[n] = LevelGenerator.generate(n)
	return _cache[n]


func _moles_with(data: Dictionary, key: String) -> Array:
	return data.get("moles", []).filter(func(m: Dictionary) -> bool: return m.has(key))


func test_same_number_same_level() -> void:
	assert_eq(JSON.stringify(LevelGenerator.generate(7)), JSON.stringify(_gen(7)))


func test_different_numbers_differ() -> void:
	assert_ne(JSON.stringify(_gen(7)), JSON.stringify(_gen(8)))


func test_metadata() -> void:
	var data := _gen(23)
	assert_eq(data.id, "level_023")
	assert_eq(data.number, 23)
	assert_eq(data.chapter, 2)
	assert_eq(data.start_count, LevelGenerator.START_COUNT)


func test_row_count_and_spacing() -> void:
	assert_eq(_gen(1).gate_pairs.size(), 6)
	assert_eq(_gen(8).gate_pairs.size(), 13)
	assert_eq(_gen(30).gate_pairs.size(), 13)
	var pairs: Array = _gen(8).gate_pairs
	for i in pairs.size():
		assert_eq(pairs[i].z, LevelGenerator.FIRST_ROW_Z + i * LevelGenerator.ROW_SPACING)


func test_boss_after_last_row() -> void:
	var data := _gen(3)
	var last: float = data.gate_pairs[-1].z
	assert_eq(data.boss.z, last + LevelGenerator.BOSS_GAP)


func test_level_one_has_no_obstacles() -> void:
	assert_eq(_gen(1).get("moles", []).size(), 0)
	assert_eq(_gen(1).get("mowers", []).size(), 0)


func test_obstacles_follow_schedule() -> void:
	for n in [2, 3]:
		assert_eq(_moles_with(_gen(n), "cage").size(), 0, "no cages in level %d" % n)
	for n in [2, 3, 5, 7]:
		assert_eq(_moles_with(_gen(n), "chase").size(), 0, "no chasers in level %d" % n)
	assert_eq(_gen(2).get("mowers", []).size(), 0)


func test_variants_appear_eventually() -> void:
	var guards := 0
	var cages := 0
	var chasers := 0
	var mowers := 0
	for n in range(9, 20):
		var data := _gen(n)
		guards += data.get("moles", []).filter(func(m: Dictionary) -> bool: return m.get("guard", false)).size()
		cages += _moles_with(data, "cage").size()
		chasers += _moles_with(data, "chase").size()
		mowers += data.get("mowers", []).size()
	assert_gt(guards, 0)
	assert_gt(cages, 0)
	assert_gt(chasers, 0)
	assert_gt(mowers, 0)


func test_guards_stand_before_the_better_gate() -> void:
	for n in range(2, 12):
		var data := _gen(n)
		for m in data.get("moles", []):
			if not m.get("guard", false):
				continue
			var pair: Dictionary = data.gate_pairs.filter(func(p: Dictionary) -> bool: return p.z > m.z)[0]
			assert_lte(pair.z - m.z, LevelValidator.GUARD_DISTANCE)
			var left := Gate.from_dict(pair.left)
			var right := Gate.from_dict(pair.right)
			var guarded := left if m.x < 0.0 else right
			var other := right if m.x < 0.0 else left
			assert_gte(guarded.apply(100), other.apply(100), "level %d" % n)


func test_chapter_mechanics() -> void:
	for n in [1, 5, 12, 20]:
		assert_false(_gen(n).has("sprinklers"), "no sprinklers in level %d" % n)
	for n in [1, 12, 25, 39]:
		assert_eq(_gen(n).gate_pairs.filter(func(p: Dictionary) -> bool: return p.has("shift")).size(), 0, "no sliding gates in level %d" % n)
	var sprinklers := 0
	for n in range(21, 25):
		sprinklers += _gen(n).get("sprinklers", []).size()
	assert_gt(sprinklers, 0)
	var shifts := 0
	for n in range(41, 44):
		shifts += _gen(n).gate_pairs.filter(func(p: Dictionary) -> bool: return p.has("shift")).size()
	assert_gt(shifts, 0)


func test_sprinklers_get_stronger() -> void:
	assert_almost_eq(LevelGenerator.sprinkler_push(21), 3.54, 0.001)
	assert_almost_eq(LevelGenerator.sprinkler_push(60), 5.1, 0.001)


func test_cage_gets_tighter() -> void:
	assert_almost_eq(LevelGenerator.cage_ratio(4), 1.5, 0.001)
	assert_almost_eq(LevelGenerator.cage_ratio(24), 1.3, 0.001)
	assert_almost_eq(LevelGenerator.cage_ratio(60), 1.1, 0.001)


func test_chase_gets_faster() -> void:
	assert_almost_eq(LevelGenerator.chase_speed(8), 0.84, 0.001)
	assert_almost_eq(LevelGenerator.chase_speed(40), 1.8, 0.001)
	assert_almost_eq(LevelGenerator.chase_speed(60), 2.0, 0.001)


func test_boss_kinds() -> void:
	assert_eq(LevelGenerator.boss_kind(1), "mole_king")
	assert_eq(LevelGenerator.boss_kind(5), "cat")
	assert_eq(LevelGenerator.boss_kind(10), "magpie")
	assert_eq(LevelGenerator.boss_kind(15), "sprinkler_robot")
	assert_eq(LevelGenerator.boss_kind(20), "mole_king_xl")
	assert_eq(LevelGenerator.boss_kind(25), "cat")
	assert_eq(LevelGenerator.boss_kind(40), "flamingo_queen")
	assert_eq(LevelGenerator.boss_kind(60), "koi_emperor")


func test_boss_factor_respects_margin() -> void:
	for n in range(1, 61):
		assert_lte(LevelGenerator.boss_factor(n) * LevelValidator.MARGIN, 1.0, "level %d" % n)
	assert_almost_eq(LevelGenerator.boss_factor(1), 0.57, 0.001)
	assert_almost_eq(LevelGenerator.boss_factor(5), 0.695, 0.001)
	assert_almost_eq(LevelGenerator.boss_factor(20), 0.80, 0.001)


func test_generated_levels_are_fair() -> void:
	for n in [1, 2, 4, 5, 8, 12, 20, 22, 41]:
		var level := LevelData.from_dict(_gen(n))
		var result := LevelValidator.validate(level)
		assert_true(result.fair, "level %d: best %d needed %.0f" % [n, result.best, result.needed])
		var hp: float = _gen(n).boss.hp
		assert_eq(hp, floorf(maxf(result.best * LevelGenerator.boss_factor(n), LevelGenerator.boss_min_hp(n))), "level %d" % n)
