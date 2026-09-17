extends GdUnitTestSuite

func test_no_keys_is_still() -> void:
	assert_vector(Walk.direction(Vector2.ZERO)).is_equal(Vector2.ZERO)

func test_one_key_is_a_unit_axis() -> void:
	assert_vector(Walk.direction(Vector2(1, 0))).is_equal(Vector2(1, 0))
	assert_vector(Walk.direction(Vector2(0, -1))).is_equal(Vector2(0, -1))

func test_opposite_keys_cancel() -> void:
	var held: Array[StringName] = [&"move_left", &"move_right"]
	for a in held:
		Input.action_press(a)
	assert_vector(Walk.direction(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down"))).is_equal(Vector2.ZERO)
	Input.action_press(&"move_down")
	held.append(&"move_down")
	assert_vector(Walk.direction(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down"))).is_equal(Vector2(0, 1))
	for a in held:
		Input.action_release(a)

func test_diagonal_is_no_faster() -> void:
	var dir := Walk.direction(Vector2(1, -1).normalized())
	assert_vector(dir).is_equal_approx(Vector2(0.7071, -0.7071), Vector2(0.0001, 0.0001))
	assert_vector(dir).is_equal(Vector2(1, -1).normalized())
	assert_float(Walk.velocity(dir).length()).is_equal_approx(48.0, 0.001)

func test_direction_snaps_to_eight() -> void:
	assert_vector(Walk.direction(Vector2(0.05, -1))).is_equal(Vector2.UP)
	assert_vector(Walk.direction(Vector2(1, 0.3))).is_equal(Vector2.RIGHT)
	assert_vector(Walk.direction(Vector2(0.7, 0.6))).is_equal(Vector2(1, 1).normalized())
	assert_vector(Walk.direction(Vector2(-0.02, 0.9))).is_equal(Vector2.DOWN)
	assert_int(Walk.facing_for(Walk.direction(Vector2(0.05, -1)), Walk.Facing.DOWN)).is_equal(Walk.Facing.UP)
	assert_float(Walk.direction(Vector2(0.3, 0)).length()).is_equal_approx(1.0, 0.0001)

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

func test_facing_names_round_trip() -> void:
	for f: int in Walk.Facing.values():
		assert_int(Walk.facing_for_name(Walk.facing_name(f))).is_equal(f)
	assert_str(Walk.facing_name(Walk.Facing.LEFT)).is_equal("left")
	assert_int(Walk.facing_for_name("north")).is_equal(-1)

func test_running_has_its_own_animation() -> void:
	assert_that(Walk.animation_for(Walk.Facing.RIGHT, true, false, true)).is_equal(&"run_right")
	assert_that(Walk.animation_for(Walk.Facing.RIGHT, false, false, true)).is_equal(&"still_right")
	# Wading is one pace whether Shift is held, so there is no wading run to show.
	assert_that(Walk.animation_for(Walk.Facing.RIGHT, true, true, true)).is_equal(&"wade_walk_right")
	assert_that(Walk.animation_for(Walk.Facing.RIGHT, true)).is_equal(&"walk_right")
	assert_that(Walk.animation_for(Walk.Facing.RIGHT, false, true)).is_equal(&"wade_still_right")

func test_the_gathering_move_names() -> void:
	assert_that(Walk.collect_animation_for(Walk.Facing.UP)).is_equal(&"collect_up")
	assert_that(Walk.collect_animation_for(Walk.Facing.UP, true)).is_equal(&"wade_collect_up")

func test_animation_scale_halves_in_the_water() -> void:
	assert_float(Walk.animation_scale(false)).is_equal(1.0)
	assert_float(Walk.animation_scale(true)).is_equal(0.5)
