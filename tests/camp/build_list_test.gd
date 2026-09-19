extends GdUnitTestSuite
## The list's place on screen, its width, and the key hint words.

## A scale at which the side-by-side list (206) is wider than the picture and the stacked one (160) fits: 206 * 3.5 > Screen.WIDTH >= 160 * 3.5 + both margins.
const STACKING := 3.5

func test_top_left_above_and_right_of_him_on_screen() -> void:
	# the man at the picture's centre: the list's bottom-left is RIGHT_OF_HIM right of and ABOVE_HIM above him
	assert_that(BuildList.top_left_for(Screen.CENTRE)).is_equal(
		Screen.CENTRE + Vector2(BuildList.RIGHT_OF_HIM, -BuildList.ABOVE_HIM - BuildList.SIZE.y))
	# near the right edge it is kept SCREEN_MARGIN inside it
	assert_that(BuildList.top_left_for(Vector2(Screen.WIDTH - 160, 90))) \
		.is_equal(Vector2(Screen.WIDTH - BuildList.SCREEN_MARGIN - BuildList.SIZE.x, 11))
	assert_that(BuildList.top_left_for(Vector2(136, 70))).is_equal(Vector2(148, 2))
	assert_that(BuildList.top_left_for(Vector2(100, 110))).is_equal(Vector2(112, 31))

func test_text_fits() -> void:
	assert_float(BuildList.SIZE.x).is_greater_equal(2 * BuildList.EDGE + 2 * BuildList.INSET + 7 * 8 + BuildList.COST_GAP + 15 * 8)
	assert_int("99/8 driftwood".length()).is_less("Needs a lean-to".length())

func test_top_left_at_larger_scales() -> void:
	assert_vector(BuildList.top_left_for(Vector2(Screen.WIDTH - 160, 90), 1.0)) \
		.is_equal(Vector2(Screen.WIDTH - BuildList.SCREEN_MARGIN - 206, 11))
	# 1.5: 309 wide, kept inside the right margin
	assert_vector(BuildList.top_left_for(Vector2(Screen.WIDTH - 160, 150), 1.5)) \
		.is_equal(Vector2(Screen.WIDTH - BuildList.SCREEN_MARGIN - 309, 46))
	assert_vector(BuildList.top_left_for(Vector2(Screen.WIDTH - 160, 90), 1.5)) \
		.is_equal(Vector2(Screen.WIDTH - BuildList.SCREEN_MARGIN - 309, 2))
	# wider than the picture less its margins: centred on it
	assert_vector(BuildList.top_left_for(Vector2(100, 232), STACKING)).is_equal(Vector2(roundf((Screen.WIDTH - 206 * STACKING) / 2), 26))
	assert_vector(BuildList.top_left_for(Screen.CENTRE, STACKING)).is_equal(Vector2(roundf((Screen.WIDTH - 206 * STACKING) / 2), 2))

func test_top_left_for_a_stacked_list() -> void:
	# 160 * 3.5 = 560 wide: kept inside the right margin
	var x := Screen.WIDTH - BuildList.SCREEN_MARGIN - BuildList.STACKED_SIZE.x * STACKING
	assert_vector(BuildList.top_left_for(Vector2(100, 150), STACKING, BuildList.STACKED_SIZE)).is_equal(Vector2(x, 2))
	assert_vector(BuildList.top_left_for(Vector2(100, 290), STACKING, BuildList.STACKED_SIZE)).is_equal(Vector2(x, 14))
	assert_vector(BuildList.top_left_for(Screen.CENTRE)).is_equal(
		Screen.CENTRE + Vector2(BuildList.RIGHT_OF_HIM, -BuildList.ABOVE_HIM - BuildList.SIZE.y))

func test_stacked_words_fit() -> void:
	assert_float(BuildList.STACKED_ROW_SIZE.x - 6).is_greater_equal(15 * 8)
	assert_float(BuildList.STACKED_SIZE.x * STACKING).is_less_equal(Screen.WIDTH - 2 * BuildList.SCREEN_MARGIN)
	assert_float(BuildList.STACKED_ROW_TOP[1] + BuildList.STACKED_ROW_SIZE.y).is_less_equal(BuildList.STACKED_SIZE.y - 1)

func test_stacks_only_when_wider_than_the_screen() -> void:
	assert_bool(BuildList.stacks(206, 1.0)).is_false()
	assert_bool(BuildList.stacks(206, 2.0)).is_false()
	assert_bool(BuildList.stacks(206, STACKING)).is_true()
	assert_bool(BuildList.stacks(Screen.WIDTH / STACKING, STACKING)).is_false()
	assert_bool(BuildList.stacks(160, STACKING)).is_false()

func test_the_list_wears_the_frame() -> void:
	assert_bool(is_same(BuildList.FRAME, load("res://src/hud/frame.tres"))).is_true()
	var constants := (load("res://src/camp/build_list.gd") as GDScript).get_script_constant_map()
	assert_bool(constants.has(&"BORDER")).is_false()
	assert_bool(constants.has(&"FILL")).is_false()

func test_everything_the_list_holds_clears_the_rim() -> void:
	var f := load("res://src/hud/frame.tres") as StyleBoxTexture
	assert_float(BuildList.EDGE).is_equal(f.texture_margin_left + 2.0)
	assert_float(BuildList.EDGE).is_equal(f.texture_margin_top + 2.0)
	assert_float(BuildList.EDGE).is_equal(f.texture_margin_right + 2.0)
	assert_float(BuildList.EDGE).is_equal(f.texture_margin_bottom + 2.0)
	assert_float(BuildList.TITLE_TOP).is_equal(BuildList.EDGE)
	assert_float(BuildList.BOTTOM_MARGIN).is_equal(BuildList.EDGE)
	assert_float(BuildList.WORDS_INSET).is_equal(2.0 * BuildList.EDGE + 2.0 * BuildList.INSET)
	assert_vector(BuildList.ROW_SIZE).is_equal(Vector2(190, 11))
	assert_vector(BuildList.STACKED_ROW_SIZE).is_equal(Vector2(144, 21))
	assert_float(BuildList.SIZE.x).is_equal(BuildList.ROW_SIZE.x + 2.0 * BuildList.EDGE)
	assert_float(BuildList.STACKED_SIZE.x).is_equal(BuildList.STACKED_ROW_SIZE.x + 2.0 * BuildList.EDGE)
	assert_float(float(BuildList.ROW_TOP[1] - BuildList.ROW_TOP[0])).is_equal(BuildList.ROW_SIZE.y + BuildList.ROW_GAP)
