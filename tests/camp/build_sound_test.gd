extends GdUnitTestSuite
## The generated knocks heard during the build's black.

func test_knock_decays_and_repeats() -> void:
	assert_float(BuildSound.knock(0.0)).is_equal_approx(1.0, 0.001)
	assert_float(BuildSound.knock(0.1)).is_equal_approx(0.0183, 0.001)
	assert_float(BuildSound.knock(0.65)).is_equal_approx(0.0183, 0.001)
	var t := 0.0
	while t <= 1.1:
		assert_float(BuildSound.knock(t)).is_between(0.0, 1.0)
		t += 0.05
