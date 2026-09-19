extends GdUnitTestSuite
## HudFrame: the one shared knobbed frame and the depth of its rim, tied to frame.tres.

func test_rim_is_the_frame_texture_margin() -> void:
	assert_str(HudFrame.STYLE.resource_path).is_equal("res://src/hud/frame.tres")
	assert_float(HudFrame.RIM).is_equal(6.0)
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		assert_float(HudFrame.STYLE.get_margin(side)).is_equal(HudFrame.RIM)

func test_the_square_board_style_is_gone() -> void:
	assert_bool(ResourceLoader.exists("res://src/pause/board.tres")).is_false()
