extends GdUnitTestSuite
## Timing of a held menu direction: a delay, then a steady repeat.

var h: HoldRepeat

func before_test() -> void:
	h = HoldRepeat.new()

func test_nothing_before_delay_then_every_interval() -> void:
	h.press(1)
	assert_int(h.advance(0.39)).is_equal(0)
	assert_int(h.advance(0.01)).is_equal(1)
	assert_int(h.advance(0.1)).is_equal(1)
	assert_int(h.advance(0.35)).is_equal(3)

func test_release_stops_and_press_restarts() -> void:
	h.press(1)
	h.advance(1.0)
	h.release()
	assert_int(h.advance(5.0)).is_equal(0)
	assert_int(h.direction).is_equal(0)
	h.press(-1)
	assert_int(h.direction).is_equal(-1)
	assert_int(h.advance(0.39)).is_equal(0)

func test_one_big_frame() -> void:
	h.press(1)
	assert_int(h.advance(1.0)).is_equal(7)
