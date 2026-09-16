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
	assert_int(MorningCardView.height_for(6)).is_equal(84)
