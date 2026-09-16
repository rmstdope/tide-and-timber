extends GdUnitTestSuite
## The collapse's timing: fall, fade to black, line on black, fade up, get up.

const P := Collapse.Phase

var c: Collapse
var got: Array[String] = []

func before_test() -> void:
	c = Collapse.new()
	got = []
	c.went_black.connect(func() -> void: got.append("went_black"))
	c.morning.connect(func() -> void: got.append("morning"))
	c.got_up.connect(func() -> void: got.append("got_up"))

## Advances to a cumulative time t since the collapse began.
func _to(t: float, now: Array) -> void:
	c.advance(t - now[0])
	now[0] = t

func test_phases_signals_and_cover() -> void:
	assert_int(c.phase).is_equal(P.FALLING)
	assert_float(c.cover_alpha()).is_equal(0.0)
	c.advance(2.0)
	assert_int(c.phase).is_equal(P.FADING_OUT)
	c.advance(0.25)
	assert_float(c.cover_alpha()).is_equal_approx(0.5, 0.001)
	c.advance(0.25)
	assert_int(c.phase).is_equal(P.BLACK)
	assert_float(c.cover_alpha()).is_equal(1.0)
	assert_array(got).is_equal(["went_black"])
	c.advance(3.0)
	assert_int(c.phase).is_equal(P.FADING_IN)
	assert_array(got).is_equal(["went_black", "morning"])
	c.advance(0.5)
	assert_float(c.cover_alpha()).is_equal_approx(0.5, 0.001)
	c.advance(0.5)
	assert_int(c.phase).is_equal(P.PUSHING_UP)
	c.advance(0.4)
	assert_int(c.phase).is_equal(P.SITTING)
	c.advance(0.8)
	assert_int(c.phase).is_equal(P.DONE)
	assert_array(got).is_equal(["went_black", "morning", "got_up"])

func test_one_huge_step_emits_each_once_in_order() -> void:
	c.advance(100.0)
	assert_array(got).is_equal(["went_black", "morning", "got_up"])
	c.advance(1.0)
	assert_array(got).is_equal(["went_black", "morning", "got_up"])

func test_poses_through_the_fall_and_getting_up() -> void:
	var now := [0.0]
	_to(0.3, now)
	assert_that(c.pose()).is_equal(&"")
	_to(0.9, now)
	assert_that(c.pose()).is_equal(&"sit")
	_to(1.5, now)
	assert_that(c.pose()).is_equal(&"lie")
	_to(3.0, now)
	assert_that(c.pose()).is_equal(&"lie")
	_to(6.6, now)
	assert_that(c.pose()).is_equal(&"push_up")
	_to(7.0, now)
	assert_that(c.pose()).is_equal(&"sit")
	_to(7.8, now)
	assert_that(c.pose()).is_equal(&"")

func test_sway_only_while_standing() -> void:
	var now := [0.0]
	_to(0.05, now)
	assert_float(c.sway_x()).is_equal(1.0)
	_to(0.2, now)
	assert_float(c.sway_x()).is_equal(-1.0)
	_to(0.7, now)
	assert_float(c.sway_x()).is_equal(0.0)

func test_line_on_black() -> void:
	var now := [0.0]
	_to(2.25, now)
	assert_float(c.line_alpha()).is_equal(0.0)
	_to(2.75, now)
	assert_float(c.line_alpha()).is_equal_approx(0.5, 0.001)
	_to(4.0, now)
	assert_float(c.line_alpha()).is_equal(1.0)
	_to(5.25, now)
	assert_float(c.line_alpha()).is_equal_approx(0.5, 0.001)
