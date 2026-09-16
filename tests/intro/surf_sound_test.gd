extends GdUnitTestSuite
## The generated sound of waves on the black beat.

func test_swell_rises_and_falls_over_six_seconds() -> void:
	assert_float(SurfSound.swell(0.0)).is_equal_approx(0.15, 0.001)
	assert_float(SurfSound.swell(3.0)).is_equal_approx(0.5, 0.001)
	assert_float(SurfSound.swell(6.0)).is_equal_approx(0.15, 0.001)
	for i in 13:
		assert_float(SurfSound.swell(i * 0.5)).is_between(0.15, 0.5)
