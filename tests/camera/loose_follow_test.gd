extends GdUnitTestSuite

const D := 1.0 / 60.0
const EPS := Vector2(0.0001, 0.0001)

func test_inside_dead_zone_does_not_move() -> void:
	assert_vector(LooseFollow.step(Vector2.ZERO, Vector2(10, -15), D)).is_equal(Vector2.ZERO)
	assert_vector(LooseFollow.step(Vector2.ZERO, Vector2(24, 20), D)).is_equal(Vector2.ZERO)

func test_outside_eases_by_overflow() -> void:
	assert_vector(LooseFollow.step(Vector2.ZERO, Vector2(40, 0), D)) \
		.is_equal_approx(Vector2(16.0 * (1.0 - exp(-5.0 / 60.0)), 0), EPS)

func test_small_overflow_settles_exactly() -> void:
	assert_vector(LooseFollow.step(Vector2.ZERO, Vector2(24.4, 0), D)).is_equal_approx(Vector2(0.4, 0), EPS)

func test_converges_and_never_overshoots() -> void:
	var centre := Vector2.ZERO
	for i in 300:
		centre = LooseFollow.step(centre, Vector2(100, -60), D)
		assert_bool(centre.x <= 76.0 and centre.y >= -40.0) \
			.override_failure_message("overshot at step %d: %s" % [i, centre]).is_true()
	assert_vector(centre).is_equal_approx(Vector2(76, -40), EPS)
