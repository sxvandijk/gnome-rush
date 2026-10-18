extends GutTest


func test_stars() -> void:
	# best route 200 against 100 hp: the ideal win leaves 100
	assert_eq(Rewards.stars(100, 200, 100), 3)
	assert_eq(Rewards.stars(60, 200, 100), 3)
	assert_eq(Rewards.stars(59, 200, 100), 2)
	assert_eq(Rewards.stars(25, 200, 100), 2)
	assert_eq(Rewards.stars(24, 200, 100), 1)
	assert_eq(Rewards.stars(1, 200, 100), 1)


func test_stars_when_shooting_beats_the_best_route() -> void:
	assert_eq(Rewards.stars(500, 200, 100), 3)


func test_no_stars_for_a_loss() -> void:
	assert_eq(Rewards.stars(0, 200, 100), 0)


func test_coins() -> void:
	# 10 + 5x3 + 3 x sqrt(100) + 5 x 2 + 40/10 = 69
	assert_eq(Rewards.coins(3, 100, 2, 40, 1.0), 69)
	assert_eq(Rewards.coins(3, 100, 2, 40, 1.5), 103)


func test_coins_grow_slowly_with_huge_armies() -> void:
	assert_lt(Rewards.coins(10, 10000, 3, 0, 1.0), 400)
