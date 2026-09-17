extends GdUnitTestSuite

func test_not_showing_until_started() -> void:
	var line := SunsetLine.new()
	assert_bool(line.is_showing()).is_false()
	assert_float(line.alpha()).is_equal(0.0)

func test_fades_in_over_half_a_second() -> void:
	var line := SunsetLine.new()
	line.start()
	line.advance(0.25)
	assert_float(line.alpha()).is_equal_approx(0.5, 0.0001)

func test_holds_about_4_seconds() -> void:
	var line := SunsetLine.new()
	line.start()
	line.advance(0.5)
	line.advance(3.9)
	assert_float(line.alpha()).is_equal(1.0)

func test_fades_out_then_is_gone() -> void:
	var line := SunsetLine.new()
	line.start()
	line.advance(4.75)
	assert_float(line.alpha()).is_equal_approx(0.5, 0.0001)
	line.advance(0.25)
	assert_bool(line.is_showing()).is_false()
	assert_float(line.alpha()).is_equal(0.0)

func test_hold_can_be_shorter() -> void:
	var line := SunsetLine.new(3.0)
	line.start()
	line.advance(3.4)
	assert_float(line.alpha()).is_equal(1.0)
	line.advance(0.35)
	assert_float(line.alpha()).is_equal_approx(0.5, 0.0001)   # 3.75 s: halfway through the 0.5 s fade-out
	line.advance(0.25)
	assert_bool(line.is_showing()).is_false()
