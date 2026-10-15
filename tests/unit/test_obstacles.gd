extends GutTest


func test_mole_group_from_dict() -> void:
	var group := MoleGroup.from_dict({"z": 70.0, "x": -2.0, "count": 12})
	assert_eq(group.z, 70.0)
	assert_eq(group.x, -2.0)
	assert_eq(group.count, 12)
	assert_false(group.resolved)


func test_mole_group_variants_default_off() -> void:
	var group := MoleGroup.from_dict({"z": 70.0, "x": -2.0, "count": 12})
	assert_eq(group.cage, 0)
	assert_eq(group.chase, 0.0)


func test_mole_group_cage_and_chase() -> void:
	var group := MoleGroup.from_dict({"z": 70.0, "x": -2.0, "count": 12, "cage": 16, "chase": 1.5})
	assert_eq(group.cage, 16)
	assert_eq(group.chase, 1.5)


func test_army_add() -> void:
	var army := Army.new(5, 4.3)
	army.add(7)
	assert_eq(army.count, 12)


func test_mole_group_radius_like_army() -> void:
	assert_eq(MoleGroup.from_dict({"z": 0.0, "x": 0.0, "count": 25}).radius(), Army.radius_for(25))


func test_mower_from_dict_and_sway() -> void:
	var mower := Mower.from_dict({"z": 97.0, "speed": 1.6, "phase": 0.5})
	assert_eq(mower.z, 97.0)
	assert_almost_eq(mower.x_at(0.0), sin(0.5) * Mower.SWAY, 0.0001)
	assert_almost_eq(mower.x_at(2.0), sin(2.0 * 1.6 + 0.5) * Mower.SWAY, 0.0001)


func test_mower_overlap() -> void:
	var mower := Mower.from_dict({"z": 50.0, "speed": 0.0, "phase": 0.0})  # parked at x = 0
	assert_true(mower.overlaps(0.0, 50.0, 0.5, 0.0))
	assert_true(mower.overlaps(1.4, 50.0, 0.5, 0.0))  # 1.0 half width + 0.5 radius
	assert_false(mower.overlaps(1.6, 50.0, 0.5, 0.0))
	assert_true(mower.overlaps(0.0, 51.0, 0.5, 0.0))  # 0.6 half depth + 0.5 radius
	assert_false(mower.overlaps(0.0, 51.2, 0.5, 0.0))


func test_boss_from_dict() -> void:
	var boss := Boss.from_dict({"z": 176.0, "hp": 40, "kind": "mole_king"})
	assert_eq(boss.z, 176.0)
	assert_eq(boss.hp, 40.0)
	assert_eq(boss.max_hp, 40.0)
	assert_eq(boss.kind, "mole_king")
	assert_false(boss.is_defeated())


func test_boss_damage() -> void:
	var boss := Boss.from_dict({"z": 0.0, "hp": 1})
	boss.damage(0.25)
	assert_eq(boss.hp, 0.75)
	assert_eq(boss.hp_display(), 1)
	boss.damage(1.0)
	assert_eq(boss.hp, 0.0)
	assert_true(boss.is_defeated())
	assert_eq(boss.hp_display(), 0)
