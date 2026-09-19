extends GdUnitTestSuite
## The morning card: fades in, holds, goes in about 4 seconds; wide enough for its longest lines.

func test_fades_in_holds_and_goes_in_four_seconds() -> void:
	var card := MorningCard.new()
	card.start()
	card.advance(0.25)
	assert_float(card.alpha()).is_equal_approx(0.5, 0.001)
	card.advance(0.25)
	assert_float(card.alpha()).is_equal(1.0)
	card.advance(3.0)
	assert_float(card.alpha()).is_equal(1.0)
	assert_bool(card.is_showing()).is_true()
	card.advance(0.25)
	assert_float(card.alpha()).is_equal_approx(0.5, 0.001)
	card.advance(0.25)
	assert_bool(card.is_showing()).is_false()

func test_card_is_wide_enough() -> void:
	assert_int(MorningCardView.WIDTH).is_greater_equal(18 * 8 + 16)
	assert_int(MorningCardView.WIDTH).is_greater_equal(17 * 8 + 8)
	assert_int(MorningCardView.height_for(6)).is_equal(86)

func test_height_for_grows_with_rel() -> void:
	assert_int(MorningCardView.height_for(6)).is_equal(86)
	assert_int(MorningCardView.height_for(6, 2.0)).is_equal(158)

func test_the_card_wears_the_frame() -> void:
	assert_bool(is_same(MorningCardView.FRAME, load("res://src/hud/frame.tres"))).is_true()
	var constants := (load("res://src/night/morning_card_view.gd") as GDScript).get_script_constant_map()
	assert_bool(constants.has(&"BORDER")).is_false()
	assert_bool(constants.has(&"FILL")).is_false()
	var f := load("res://src/hud/frame.tres") as StyleBoxTexture
	assert_int(MorningCardView.PAD_TOP).is_equal(int(f.texture_margin_top) + 2)
	assert_int(MorningCardView.PAD_SIDE).is_equal(int(f.texture_margin_left) + 2)
	assert_int(MorningCardView.PAD_BOTTOM).is_greater_equal(int(f.texture_margin_bottom))
