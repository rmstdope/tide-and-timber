extends GdUnitTestSuite

func test_no_keys_is_still() -> void:
	assert_vector(Walk.direction(false, false, false, false)).is_equal(Vector2.ZERO)

func test_one_key_is_a_unit_axis() -> void:
	assert_vector(Walk.direction(false, true, false, false)).is_equal(Vector2(1, 0))
	assert_vector(Walk.direction(false, false, true, false)).is_equal(Vector2(0, -1))

func test_opposite_keys_cancel() -> void:
	assert_vector(Walk.direction(true, true, false, false)).is_equal(Vector2.ZERO)
	assert_vector(Walk.direction(true, true, false, true)).is_equal(Vector2(0, 1))
	assert_vector(Walk.direction(true, true, true, true)).is_equal(Vector2.ZERO)

func test_diagonal_is_no_faster() -> void:
	var dir := Walk.direction(false, true, true, false)
	assert_vector(dir).is_equal_approx(Vector2(0.7071, -0.7071), Vector2(0.0001, 0.0001))
	assert_float(Walk.velocity(dir).length()).is_equal_approx(48.0, 0.001)

func test_speed_is_three_tiles_a_second() -> void:
	assert_vector(Walk.velocity(Vector2(1, 0))).is_equal(Vector2(48, 0))

func test_diagonals_face_sideways() -> void:
	assert_int(Walk.facing_for(Vector2(-0.7, -0.7), Walk.Facing.DOWN)).is_equal(Walk.Facing.LEFT)
	assert_int(Walk.facing_for(Vector2(0.7, 0.7), Walk.Facing.DOWN)).is_equal(Walk.Facing.RIGHT)

func test_straight_directions_face_their_way() -> void:
	assert_int(Walk.facing_for(Vector2(0, -1), Walk.Facing.DOWN)).is_equal(Walk.Facing.UP)
	assert_int(Walk.facing_for(Vector2(0, 1), Walk.Facing.UP)).is_equal(Walk.Facing.DOWN)

func test_standing_keeps_last_facing() -> void:
	assert_int(Walk.facing_for(Vector2.ZERO, Walk.Facing.LEFT)).is_equal(Walk.Facing.LEFT)

func test_animation_names() -> void:
	assert_that(Walk.animation_for(Walk.Facing.UP, true)).is_equal(&"walk_up")
	assert_that(Walk.animation_for(Walk.Facing.RIGHT, false)).is_equal(&"still_right")

func test_facing_vectors() -> void:
	assert_vector(Walk.facing_vector(Walk.Facing.DOWN)).is_equal(Vector2(0, 1))
	assert_vector(Walk.facing_vector(Walk.Facing.UP)).is_equal(Vector2(0, -1))
	assert_vector(Walk.facing_vector(Walk.Facing.LEFT)).is_equal(Vector2(-1, 0))
	assert_vector(Walk.facing_vector(Walk.Facing.RIGHT)).is_equal(Vector2(1, 0))

func test_run_is_double_walk() -> void:
	assert_float(Walk.speed_for(true, false)).is_equal(96.0)
	assert_float(Walk.speed_for(false, false)).is_equal(Walk.SPEED)

func test_wading_is_half_walk_even_running() -> void:
	assert_float(Walk.speed_for(false, true)).is_equal(24.0)
	assert_float(Walk.speed_for(true, true)).is_equal(24.0)

func test_velocity_takes_a_speed() -> void:
	assert_vector(Walk.velocity(Vector2(1, 0), 96.0)).is_equal(Vector2(96, 0))
	assert_vector(Walk.velocity(Vector2(1, 0))).is_equal(Vector2(48, 0))

func test_wading_animation_names() -> void:
	assert_that(Walk.animation_for(Walk.Facing.LEFT, true, true)).is_equal(&"wade_walk_left")
	assert_that(Walk.animation_for(Walk.Facing.DOWN, false, true)).is_equal(&"wade_still_down")
	assert_that(Walk.animation_for(Walk.Facing.UP, true, false)).is_equal(&"walk_up")

func test_trail_kinds() -> void:
	assert_that(Walk.trail_for(true, true, false)).is_equal(&"puff")
	assert_that(Walk.trail_for(true, false, true)).is_equal(&"ripple")
	assert_that(Walk.trail_for(true, true, true)).is_equal(&"ripple")
	assert_that(Walk.trail_for(true, false, false)).is_equal(&"")
	assert_that(Walk.trail_for(false, true, false)).is_equal(&"")
	assert_that(Walk.trail_for(false, false, true)).is_equal(&"")

func test_trail_intervals() -> void:
	assert_float(Walk.trail_interval(&"puff")).is_equal(0.15)
	assert_float(Walk.trail_interval(&"ripple")).is_equal(0.3)
	assert_float(Walk.trail_interval(&"")).is_equal(0.0)
