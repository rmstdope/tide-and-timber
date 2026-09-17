extends GdUnitTestSuite

func _region(frames: SpriteFrames, anim: StringName, i: int) -> Rect2:
	return (frames.get_frame_texture(anim, i) as AtlasTexture).region

func _atlas(frames: SpriteFrames, anim: StringName, i: int) -> String:
	return (frames.get_frame_texture(anim, i) as AtlasTexture).atlas.resource_path

func test_thirty_two_animations() -> void:
	var names := Array(ManFrames.build().get_animation_names())
	names.sort()
	assert_array(names).is_equal([
		"collect_down", "collect_left", "collect_right", "collect_up",
		"death_down", "death_left", "death_right", "death_up",
		"run_down", "run_left", "run_right", "run_up",
		"still_down", "still_left", "still_right", "still_up",
		"wade_collect_down", "wade_collect_left", "wade_collect_right", "wade_collect_up",
		"wade_still_down", "wade_still_left", "wade_still_right", "wade_still_up",
		"wade_walk_down", "wade_walk_left", "wade_walk_right", "wade_walk_up",
		"walk_down", "walk_left", "walk_right", "walk_up"])

func test_idle_breathes() -> void:
	var frames := ManFrames.build()
	assert_int(frames.get_frame_count(&"still_up")).is_equal(4)
	assert_bool(frames.get_animation_loop(&"still_up")).is_true()
	assert_float(frames.get_animation_speed(&"still_up")).is_equal(6.0)
	assert_that(_region(frames, &"still_up", 0)).is_equal(Rect2(0, 64, 64, 64))
	assert_str(_atlas(frames, &"still_up", 0)).is_equal("res://assets/man/idle.png")

func test_walk_animations() -> void:
	var frames := ManFrames.build()
	assert_int(frames.get_frame_count(&"walk_left")).is_equal(6)
	assert_bool(frames.get_animation_loop(&"walk_left")).is_true()
	assert_float(frames.get_animation_speed(&"walk_left")).is_equal(12.0)
	assert_that(_region(frames, &"walk_left", 0)).is_equal(Rect2(0, 128, 64, 64))
	assert_that(_region(frames, &"walk_left", 5)).is_equal(Rect2(320, 128, 64, 64))
	assert_str(_atlas(frames, &"walk_left", 0)).is_equal("res://assets/man/walk.png")

func test_run_animations() -> void:
	var frames := ManFrames.build()
	assert_int(frames.get_frame_count(&"run_right")).is_equal(6)
	assert_bool(frames.get_animation_loop(&"run_right")).is_true()
	assert_float(frames.get_animation_speed(&"run_right")).is_equal(16.0)
	assert_that(_region(frames, &"run_right", 0)).is_equal(Rect2(0, 192, 64, 64))
	assert_str(_atlas(frames, &"run_right", 0)).is_equal("res://assets/man/run.png")
	# Wading is one pace whether Shift is held, so running in the water shows the wading walk.
	assert_bool(frames.has_animation(&"wade_run_right")).is_false()

func test_collect_animations() -> void:
	var frames := ManFrames.build()
	assert_int(frames.get_frame_count(&"collect_down")).is_equal(8)
	assert_bool(frames.get_animation_loop(&"collect_down")).is_false()
	assert_float(frames.get_animation_speed(&"collect_down")).is_equal(12.0)
	assert_that(_region(frames, &"collect_down", 7)).is_equal(Rect2(448, 0, 64, 64))
	assert_str(_atlas(frames, &"collect_down", 0)).is_equal("res://assets/man/collect.png")

func test_the_fall_animations() -> void:
	var frames := ManFrames.build()
	assert_int(frames.get_frame_count(&"death_left")).is_equal(8)
	assert_bool(frames.get_animation_loop(&"death_left")).is_false()
	assert_float(frames.get_animation_speed(&"death_left")).is_equal(4.0)
	assert_that(_region(frames, &"death_left", 0)).is_equal(Rect2(0, 128, 64, 64))
	assert_that(_region(frames, &"death_left", 7)).is_equal(Rect2(448, 128, 64, 64))
	assert_str(_atlas(frames, &"death_left", 0)).is_equal("res://assets/man/death.png")
	# He keeps his legs if he goes down in the shallows, as the placeholder poses did.
	assert_bool(frames.has_animation(&"wade_death_left")).is_false()

## The rules count the fall's frames without loading its five textures, so the two must agree.
func test_the_fall_has_as_many_frames_as_the_rules_count() -> void:
	assert_int(ManFrames.build().get_frame_count(&"death_down")).is_equal(WakeUp.FALL_FRAMES)

func test_wading_hides_legs() -> void:
	var frames := ManFrames.build()
	var first := frames.get_frame_texture(&"wade_walk_left", 0) as AtlasTexture
	assert_that(first.region).is_equal(Rect2(0, 128, 64, 44))
	assert_that(first.margin).is_equal(Rect2(0, 0, 0, 20))
	assert_vector(first.get_size()).is_equal(Vector2(64, 64))
	assert_that(_region(frames, &"wade_still_up", 0)).is_equal(Rect2(0, 64, 64, 44))
	assert_int(frames.get_frame_count(&"wade_collect_down")).is_equal(8)
	var cut := frames.get_frame_texture(&"wade_collect_down", 0) as AtlasTexture
	assert_that(cut.region).is_equal(Rect2(0, 0, 64, 44))
	assert_that(cut.margin).is_equal(Rect2(0, 0, 0, 20))

## His feet sit on the node origin, which is what makes the map, collisions, the camera, y-sorting,
## trail marks, saves and every BeachLayout cell go on meaning what they did. The sprite is centred,
## so the top of its frame is offset.y - half a frame, and the footline has to land on 0 from there.
func test_his_feet_stand_on_the_node_origin() -> void:
	var player := (load("res://src/player/player.tscn") as PackedScene).instantiate() as Player
	auto_free(player)
	var sprite := player.get_node("%Sprite") as AnimatedSprite2D
	assert_vector(sprite.offset).is_equal(Vector2(0, -16))
	var frame_top := sprite.offset.y - ManFrames.FRAME_SIZE.y / 2.0
	assert_float(frame_top + ManFrames.FOOTLINE).override_failure_message(
		"his footline sits at y %.1f, not on the origin" % (frame_top + ManFrames.FOOTLINE)).is_equal(0.0)
