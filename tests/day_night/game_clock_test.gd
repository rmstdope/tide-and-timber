extends GdUnitTestSuite

func _at(minutes: float) -> GameClock:
	var c := GameClock.new()
	c.total_minutes = minutes
	return c

func test_starts_on_day_1_at_13_00() -> void:
	var c := GameClock.new()
	assert_str(c.day_text()).is_equal("DAY 1")
	assert_str(c.time_text()).is_equal("13:00")
	assert_bool(c.is_day()).is_true()

func test_time_steps_every_10_game_minutes() -> void:
	var c := GameClock.new()
	c.advance(14.9)
	assert_str(c.time_text()).is_equal("13:00")
	c.advance(0.1)
	assert_str(c.time_text()).is_equal("13:10")

func test_one_game_hour_is_90_real_seconds() -> void:
	var c := GameClock.new()
	c.advance(90.0)
	assert_str(c.time_text()).is_equal("14:00")

func test_dark_at_20_00_after_630_real_seconds() -> void:
	var c := GameClock.new()
	c.advance(630.0)
	assert_str(c.time_text()).is_equal("20:00")
	assert_bool(c.is_day()).is_false()

func test_night_runs_at_day_pace_to_06_00() -> void:
	var c := GameClock.new()
	c.advance(630.0 + 900.0)
	assert_str(c.time_text()).is_equal("06:00")
	assert_str(c.day_text()).is_equal("DAY 2")
	assert_bool(c.is_day()).is_true()

func test_day_turns_at_midnight() -> void:
	var c := _at(1439.0)
	assert_str(c.day_text()).is_equal("DAY 1")
	assert_str(c.time_text()).is_equal("23:50")
	c.total_minutes = 1440.0
	assert_str(c.day_text()).is_equal("DAY 2")
	assert_str(c.time_text()).is_equal("00:00")

func test_time_text_is_always_five_characters_with_leading_zero() -> void:
	assert_str(_at(1440.0 + 360.0).time_text()).is_equal("06:00")
	assert_str(_at(1440.0 + 65.0).time_text()).is_equal("01:00")
	for m in range(0, 1440, 10):
		assert_int(_at(float(m)).time_text().length()).is_equal(5)

func test_day_text_grows_to_three_digits() -> void:
	assert_str(_at(99 * 1440.0).day_text()).is_equal("DAY 100")

func test_dial_fraction_day_and_night() -> void:
	assert_float(_at(360.0).dial_fraction()).is_equal_approx(0.0, 0.0001)
	assert_bool(_at(360.0).is_day()).is_true()
	assert_float(_at(780.0).dial_fraction()).is_equal_approx(0.5, 0.0001)
	assert_float(_at(1190.0).dial_fraction()).is_equal_approx(830.0 / 840.0, 0.0001)
	assert_float(_at(1200.0).dial_fraction()).is_equal_approx(0.0, 0.0001)
	assert_bool(_at(1200.0).is_day()).is_false()
	assert_float(_at(60.0).dial_fraction()).is_equal_approx(0.5, 0.0001)
	assert_bool(_at(60.0).is_day()).is_false()
	assert_float(_at(350.0).dial_fraction()).is_equal_approx(590.0 / 600.0, 0.0001)

func test_sunsets_passed_counts_each_18_30() -> void:
	assert_int(_at(780.0).sunsets_passed()).is_equal(-1)
	assert_int(_at(1109.9).sunsets_passed()).is_equal(-1)
	assert_int(_at(1110.0).sunsets_passed()).is_equal(0)
	assert_int(_at(1440.0 + 1109.0).sunsets_passed()).is_equal(0)
	assert_int(_at(1440.0 + 1110.0).sunsets_passed()).is_equal(1)

func test_dawns_passed() -> void:
	assert_int(GameClock.new().dawns_passed()).is_equal(0)
	assert_int(_at(1799.0).dawns_passed()).is_equal(0)
	assert_int(_at(1800.0).dawns_passed()).is_equal(1)
	assert_int(_at(3240.0).dawns_passed()).is_equal(2)

func test_last_dawn_minutes() -> void:
	assert_float(_at(1800.67).last_dawn_minutes()).is_equal(1800.0)
	assert_float(_at(3000.0).last_dawn_minutes()).is_equal(1800.0)
	assert_float(_at(3240.0).last_dawn_minutes()).is_equal(3240.0)
