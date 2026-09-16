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
