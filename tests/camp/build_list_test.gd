extends GdUnitTestSuite
## The list's place on screen, its width, and the key hint words.

func test_top_left_above_and_right_of_him_on_screen() -> void:
	assert_that(BuildList.top_left_for(Vector2(160, 90))).is_equal(Vector2(120, 21))
	assert_that(BuildList.top_left_for(Vector2(136, 70))).is_equal(Vector2(120, 2))
	assert_that(BuildList.top_left_for(Vector2(100, 110))).is_equal(Vector2(112, 41))

func test_text_fits() -> void:
	assert_float(BuildList.SIZE.x).is_greater_equal(6 + 7 * 8 + 8 + 15 * 8 + 6)
	assert_int("99/8 driftwood".length()).is_less("Needs a lean-to".length())

func test_top_left_at_larger_scales() -> void:
	assert_vector(BuildList.top_left_for(Vector2(160, 90), 1.0)).is_equal(Vector2(120, 21))
	assert_vector(BuildList.top_left_for(Vector2(100, 150), 1.5)).is_equal(Vector2(22, 61))
	assert_vector(BuildList.top_left_for(Vector2(160, 90), 1.5)).is_equal(Vector2(22, 2))
	assert_vector(BuildList.top_left_for(Vector2(100, 150), 2.0)).is_equal(Vector2(-36, 40))
	assert_vector(BuildList.top_left_for(Vector2(160, 90), 2.0)).is_equal(Vector2(-36, 2))

func test_top_left_for_a_stacked_list() -> void:
	assert_vector(BuildList.top_left_for(Vector2(100, 150), 2.0, BuildList.STACKED_SIZE)).is_equal(Vector2(16, 2))
	assert_vector(BuildList.top_left_for(Vector2(60, 170), 2.0, BuildList.STACKED_SIZE)).is_equal(Vector2(16, 20))
	assert_vector(BuildList.top_left_for(Vector2(160, 90))).is_equal(Vector2(120, 21))

func test_stacked_words_fit() -> void:
	assert_float(BuildList.STACKED_ROW_SIZE.x - 6).is_greater_equal(15 * 8)
	assert_float(BuildList.STACKED_SIZE.x * 2).is_less_equal(320 - 2 * BuildList.SCREEN_MARGIN)
	assert_float(BuildList.STACKED_ROW_TOP[1] + BuildList.STACKED_ROW_SIZE.y).is_less_equal(BuildList.STACKED_SIZE.y - 1)

func test_stacks_only_when_wider_than_the_screen() -> void:
	assert_bool(BuildList.stacks(196, 1.0)).is_false()
	assert_bool(BuildList.stacks(196, 1.5)).is_false()
	assert_bool(BuildList.stacks(196, 2.0)).is_true()
	assert_bool(BuildList.stacks(160, 2.0)).is_false()
	assert_bool(BuildList.stacks(150, 2.0)).is_false()
