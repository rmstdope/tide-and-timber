extends GdUnitTestSuite

func test_marker_at_left_top_and_right_of_arc() -> void:
	assert_that(ClockDial.marker_position(0.0)).is_equal(Vector2i(18, 24))
	assert_that(ClockDial.marker_position(0.5)).is_equal(Vector2i(32, 10))
	assert_that(ClockDial.marker_position(1.0)).is_equal(Vector2i(46, 24))

func test_sun_and_moon_are_different_shapes() -> void:
	var sun := ClockDial.marker_pixels(true)
	var moon := ClockDial.marker_pixels(false)
	assert_bool(sun != moon).is_true()
	for pixels: Array in [sun, moon]:
		assert_int(pixels.size()).is_equal(7)
		for row: String in pixels:
			assert_int(row.length()).is_equal(7)
