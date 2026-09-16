extends GdUnitTestSuite

const SHEET := preload("res://assets/man/man.png")

func _region(frames: SpriteFrames, anim: StringName, i: int) -> Rect2:
	return (frames.get_frame_texture(anim, i) as AtlasTexture).region

func test_sixteen_animations() -> void:
	var names := Array(ManFrames.build(SHEET).get_animation_names())
	names.sort()
	assert_array(names).is_equal(["still_down", "still_left", "still_right", "still_up",
		"wade_still_down", "wade_still_left", "wade_still_right", "wade_still_up",
		"wade_walk_down", "wade_walk_left", "wade_walk_right", "wade_walk_up",
		"walk_down", "walk_left", "walk_right", "walk_up"])

func test_walk_animations() -> void:
	var frames := ManFrames.build(SHEET)
	assert_int(frames.get_frame_count(&"walk_left")).is_equal(4)
	assert_bool(frames.get_animation_loop(&"walk_left")).is_true()
	assert_float(frames.get_animation_speed(&"walk_left")).is_equal(8.0)
	assert_that(_region(frames, &"walk_left", 0)).is_equal(Rect2(16, 48, 16, 24))
	assert_that(_region(frames, &"walk_left", 3)).is_equal(Rect2(0, 48, 16, 24))

func test_still_animations() -> void:
	var frames := ManFrames.build(SHEET)
	assert_int(frames.get_frame_count(&"still_up")).is_equal(1)
	assert_that(_region(frames, &"still_up", 0)).is_equal(Rect2(0, 24, 16, 24))
	assert_bool(frames.get_animation_loop(&"still_up")).is_false()

func test_waking_poses() -> void:
	var frames := ManFrames.build(SHEET)
	ManFrames.add_waking(frames, load("res://assets/man/man_wake.png"))
	for pose: StringName in [&"lie", &"push_up", &"sit"]:
		assert_int(frames.get_frame_count(pose)).override_failure_message(pose).is_equal(1)
		assert_bool(frames.get_animation_loop(pose)).override_failure_message(pose).is_false()
	assert_that(_region(frames, &"push_up", 0)).is_equal(Rect2(24, 0, 24, 24))
	assert_int(frames.get_animation_names().size()).is_equal(19)
	assert_int(frames.get_frame_count(&"walk_down")).is_equal(4)

func test_wading_hides_legs() -> void:
	var frames := ManFrames.build(SHEET)
	assert_int(frames.get_frame_count(&"wade_walk_left")).is_equal(4)
	assert_bool(frames.get_animation_loop(&"wade_walk_left")).is_true()
	assert_float(frames.get_animation_speed(&"wade_walk_left")).is_equal(8.0)
	var first := frames.get_frame_texture(&"wade_walk_left", 0) as AtlasTexture
	assert_that(first.region).is_equal(Rect2(16, 48, 16, 20))
	assert_that(first.margin).is_equal(Rect2(0, 0, 0, 4))
	assert_vector(first.get_size()).is_equal(Vector2(16, 24))
	assert_int(frames.get_frame_count(&"wade_still_up")).is_equal(1)
	assert_that(_region(frames, &"wade_still_up", 0)).is_equal(Rect2(0, 24, 16, 20))
	assert_bool(frames.get_animation_loop(&"wade_still_up")).is_false()
