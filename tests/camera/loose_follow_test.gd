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

const ISLAND_BOUNDS := Rect2(320, 180, 2304, 56)

func test_centre_bounds_inset_by_half_the_view() -> void:
	assert_that(LooseFollow.centre_bounds(Rect2(0, 0, 2944, 416), Vector2(640, 360))).is_equal(ISLAND_BOUNDS)
	assert_that(LooseFollow.centre_bounds(Rect2(100, 50, 1000, 400), Vector2(640, 360))).is_equal(Rect2(420, 230, 360, 40))

func test_centre_bounds_pins_a_world_narrower_than_the_view() -> void:
	assert_that(LooseFollow.centre_bounds(Rect2(0, 0, 320, 200), Vector2(640, 360))).is_equal(Rect2(160, 100, 0, 0))
	assert_that(LooseFollow.centre_bounds(Rect2(0, 0, 640, 360), Vector2(640, 360))).is_equal(Rect2(320, 180, 0, 0))

func test_clamp_centre_leaves_an_inside_centre_alone() -> void:
	assert_vector(LooseFollow.clamp_centre(Vector2(1480, 184), ISLAND_BOUNDS)).is_equal(Vector2(1480, 184))

func test_clamp_centre_stops_at_every_edge() -> void:
	assert_vector(LooseFollow.clamp_centre(Vector2(0, 0), ISLAND_BOUNDS)).is_equal(Vector2(320, 180))
	assert_vector(LooseFollow.clamp_centre(Vector2(5000, 900), ISLAND_BOUNDS)).is_equal(Vector2(2624, 236))
	assert_vector(LooseFollow.clamp_centre(Vector2(1480, 900), ISLAND_BOUNDS)).is_equal(Vector2(1480, 236))
	assert_vector(LooseFollow.clamp_centre(Vector2(0, 184), ISLAND_BOUNDS)).is_equal(Vector2(320, 184))

func test_unbounded_changes_nothing() -> void:
	assert_vector(LooseFollow.clamp_centre(Vector2(1480, 184), LooseFollow.UNBOUNDED)).is_equal(Vector2(1480, 184))
	assert_vector(LooseFollow.clamp_centre(Vector2(-2000, 9000), LooseFollow.UNBOUNDED)).is_equal(Vector2(-2000, 9000))
