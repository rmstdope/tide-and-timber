extends GdUnitTestSuite

const NIGHT := Color8(110, 125, 190)

func test_midday_and_start_of_play_are_full_daylight() -> void:
	assert_that(Daylight.color_at(720.0)).is_equal(Color.WHITE)
	assert_that(Daylight.color_at(780.0)).is_equal(Color.WHITE)

func test_sunset_is_orange_dusk_is_purple_night_is_blue() -> void:
	var sunset := Daylight.color_at(1110.0)
	assert_bool(sunset.r > sunset.g and sunset.g > sunset.b).is_true()
	var dusk := Daylight.color_at(1200.0)
	assert_bool(dusk.b > dusk.g and dusk.r > dusk.g).is_true()
	var night := Daylight.color_at(60.0)
	assert_bool(night.b > night.r and night.b > night.g).is_true()

func test_night_is_never_black() -> void:
	for m in 1440:
		var c := Daylight.color_at(float(m))
		assert_bool(c.r >= 0.4 and c.g >= 0.4 and c.b >= 0.4).override_failure_message("minute %d" % m).is_true()

func test_changes_smoothly() -> void:
	for m in 1440:
		var a := Daylight.color_at(float(m))
		var b := Daylight.color_at(float(m + 1))
		var ok := absf(a.r - b.r) <= 0.01 and absf(a.g - b.g) <= 0.01 and absf(a.b - b.b) <= 0.01
		assert_bool(ok).override_failure_message("minute %d" % m).is_true()

func test_morning_light_returns() -> void:
	assert_that(Daylight.color_at(300.0)).is_equal(NIGHT)
	assert_that(Daylight.color_at(420.0)).is_equal(Color.WHITE)
	assert_bool(Daylight.color_at(330.0).r > Daylight.color_at(300.0).r).is_true()

func test_wraps_past_midnight() -> void:
	assert_that(Daylight.color_at(1440.0 + 60.0)).is_equal(Daylight.color_at(60.0))
