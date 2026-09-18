extends GdUnitTestSuite
## The list's place on screen, its width, and the key hint words.

## A scale at which the side-by-side list (196) is wider than the picture: 196 * 4 > Screen.WIDTH.
const STACKING := 4.0

func test_top_left_above_and_right_of_him_on_screen() -> void:
	# the man at the picture's centre: the list's bottom-left is RIGHT_OF_HIM right of and ABOVE_HIM above him
	assert_that(BuildList.top_left_for(Screen.CENTRE)).is_equal(
		Screen.CENTRE + Vector2(BuildList.RIGHT_OF_HIM, -BuildList.ABOVE_HIM - BuildList.SIZE.y))
	# near the right edge it is kept SCREEN_MARGIN inside it
	assert_that(BuildList.top_left_for(Vector2(Screen.WIDTH - 160, 90))) \
		.is_equal(Vector2(Screen.WIDTH - BuildList.SCREEN_MARGIN - BuildList.SIZE.x, 21))
	assert_that(BuildList.top_left_for(Vector2(136, 70))).is_equal(Vector2(148, 2))
	assert_that(BuildList.top_left_for(Vector2(100, 110))).is_equal(Vector2(112, 41))

func test_text_fits() -> void:
	assert_float(BuildList.SIZE.x).is_greater_equal(6 + 7 * 8 + 8 + 15 * 8 + 6)
	assert_int("99/8 driftwood".length()).is_less("Needs a lean-to".length())

func test_top_left_at_larger_scales() -> void:
	assert_vector(BuildList.top_left_for(Vector2(Screen.WIDTH - 160, 90), 1.0)) \
		.is_equal(Vector2(Screen.WIDTH - BuildList.SCREEN_MARGIN - 196, 21))
	# 1.5: 294 wide, kept inside the right margin
	assert_vector(BuildList.top_left_for(Vector2(Screen.WIDTH - 160, 150), 1.5)) \
		.is_equal(Vector2(Screen.WIDTH - BuildList.SCREEN_MARGIN - 294, 61))
	assert_vector(BuildList.top_left_for(Vector2(Screen.WIDTH - 160, 90), 1.5)) \
		.is_equal(Vector2(Screen.WIDTH - BuildList.SCREEN_MARGIN - 294, 2))
	# wider than the picture less its margins: centred on it
	assert_vector(BuildList.top_left_for(Vector2(100, 232), STACKING)).is_equal(Vector2((Screen.WIDTH - 196 * STACKING) / 2, 40))
	assert_vector(BuildList.top_left_for(Screen.CENTRE, STACKING)).is_equal(Vector2((Screen.WIDTH - 196 * STACKING) / 2, 2))

func test_top_left_for_a_stacked_list() -> void:
	# 150 * 4 = 600 wide: kept inside the right margin
	var x := Screen.WIDTH - BuildList.SCREEN_MARGIN - BuildList.STACKED_SIZE.x * STACKING
	assert_vector(BuildList.top_left_for(Vector2(100, 150), STACKING, BuildList.STACKED_SIZE)).is_equal(Vector2(x, 2))
	assert_vector(BuildList.top_left_for(Vector2(60, 290), STACKING, BuildList.STACKED_SIZE)).is_equal(Vector2(x, 18))
	assert_vector(BuildList.top_left_for(Screen.CENTRE)).is_equal(
		Screen.CENTRE + Vector2(BuildList.RIGHT_OF_HIM, -BuildList.ABOVE_HIM - BuildList.SIZE.y))

func test_stacked_words_fit() -> void:
	assert_float(BuildList.STACKED_ROW_SIZE.x - 6).is_greater_equal(15 * 8)
	assert_float(BuildList.STACKED_SIZE.x * STACKING).is_less_equal(Screen.WIDTH - 2 * BuildList.SCREEN_MARGIN)
	assert_float(BuildList.STACKED_ROW_TOP[1] + BuildList.STACKED_ROW_SIZE.y).is_less_equal(BuildList.STACKED_SIZE.y - 1)

func test_stacks_only_when_wider_than_the_screen() -> void:
	assert_bool(BuildList.stacks(196, 1.0)).is_false()
	assert_bool(BuildList.stacks(196, 2.0)).is_false()
	assert_bool(BuildList.stacks(196, STACKING)).is_true()
	assert_bool(BuildList.stacks(Screen.WIDTH / STACKING, STACKING)).is_false()
	assert_bool(BuildList.stacks(150, STACKING)).is_false()
