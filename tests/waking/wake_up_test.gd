extends GdUnitTestSuite
## The waking's rules: the fade up, getting himself up, control once, and the move hint.

var w: WakeUp
var calls: Array[String] = []

func before_test() -> void:
	calls = []
	w = WakeUp.new()
	var recorded := calls
	w.control_given.connect(func() -> void: recorded.append("control"))

func test_starts_black_and_lying() -> void:
	assert_int(w.phase).is_equal(WakeUp.Phase.FADING_IN)
	assert_float(w.cover_alpha()).is_equal_approx(1.0, 0.001)
	assert_int(w.fall_frame()).is_equal(WakeUp.FALL_FRAMES - 1)
	assert_float(w.hint_alpha()).is_equal_approx(0.0, 0.001)

func test_picture_fades_up_over_one_second() -> void:
	w.advance(0.5)
	assert_float(w.cover_alpha()).is_equal_approx(0.5, 0.001)
	w.advance(0.5)
	assert_float(w.cover_alpha()).is_equal_approx(0.0, 0.001)
	assert_int(w.phase).is_equal(WakeUp.Phase.LYING)
	assert_int(w.fall_frame()).is_equal(WakeUp.FALL_FRAMES - 1)

func test_lies_two_seconds_then_pushes_up() -> void:
	w.advance(1.0)
	w.advance(1.9)
	assert_int(w.phase).is_equal(WakeUp.Phase.LYING)
	w.advance(0.2)
	assert_int(w.phase).is_equal(WakeUp.Phase.PUSHING_UP)
	assert_int(w.fall_frame()).is_equal(7)
	w.advance(0.2)
	assert_int(w.fall_frame()).is_equal(5)

func test_sits_then_stands_with_control() -> void:
	w.advance(3.5)
	assert_int(w.phase).is_equal(WakeUp.Phase.SITTING)
	assert_int(w.fall_frame()).is_equal(4)
	assert_array(calls).is_empty()
	w.advance(0.8)
	assert_int(w.phase).is_equal(WakeUp.Phase.CONTROL)
	assert_int(w.fall_frame()).is_equal(-1)
	assert_array(calls).is_equal(["control"])
	assert_float(w.hint_alpha()).is_equal_approx(1.0, 0.001)

func test_control_given_once_on_a_long_step() -> void:
	w.advance(100.0)
	assert_int(w.phase).is_equal(WakeUp.Phase.CONTROL)
	assert_array(calls).is_equal(["control"])
	w.advance(1.0)
	assert_array(calls).is_equal(["control"])

func test_walking_before_control_does_not_count() -> void:
	w.add_walked(100.0)
	w.advance(5.0)
	assert_float(w.walked).is_equal_approx(0.0, 0.001)
	assert_float(w.hint_alpha()).is_equal_approx(1.0, 0.001)

func test_hint_stays_until_a_few_steps_then_fades() -> void:
	w.advance(5.0)
	w.add_walked(20.0)
	w.advance(10.0)
	assert_float(w.hint_alpha()).is_equal_approx(1.0, 0.001)
	w.add_walked(12.0)
	w.advance(0.25)
	assert_float(w.hint_alpha()).is_equal_approx(0.5, 0.001)
	w.advance(0.25)
	assert_float(w.hint_alpha()).is_equal_approx(0.0, 0.001)
	w.advance(5.0)
	w.add_walked(50.0)
	w.advance(1.0)
	assert_float(w.hint_alpha()).is_equal_approx(0.0, 0.001)

func test_resume_gives_control_with_no_story() -> void:
	w.resume()
	assert_int(w.phase).is_equal(WakeUp.Phase.CONTROL)
	assert_int(w.fall_frame()).is_equal(-1)
	assert_float(w.hint_alpha()).is_equal(0.0)
	assert_float(w.cover_alpha()).is_equal(1.0)
	assert_array(calls).is_empty()

func test_resume_fades_up_over_a_second() -> void:
	w.resume()
	w.advance(0.5)
	assert_float(w.cover_alpha()).is_equal_approx(0.5, 0.001)
	w.advance(0.6)
	assert_float(w.cover_alpha()).is_equal_approx(0.0, 0.001)
	w.add_walked(0.0)
	w.advance(1.0)
	assert_float(w.hint_alpha()).is_equal(0.0)
	assert_array(calls).is_empty()

## Getting up is the fall backwards over PUSH_UP_SECONDS + SIT_SECONDS, ending on his feet.
func test_getting_up_runs_the_fall_backwards() -> void:
	assert_int(WakeUp.getting_up_frame(0.0)).is_equal(7)
	assert_int(WakeUp.getting_up_frame(0.6)).is_equal(3)
	assert_int(WakeUp.getting_up_frame(1.19)).is_equal(0)
	assert_int(WakeUp.getting_up_frame(5.0)).is_equal(0)
