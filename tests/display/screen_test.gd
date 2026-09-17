extends GdUnitTestSuite

# Screen is the one place that says how big the drawn picture is. These two assertions are what
# stops it and project.godot ever drifting apart (tr-1o0.1).

func test_screen_matches_the_projects_viewport() -> void:
	assert_float(Screen.WIDTH).is_equal(
			float(ProjectSettings.get_setting("display/window/size/viewport_width")))
	assert_float(Screen.HEIGHT).is_equal(
			float(ProjectSettings.get_setting("display/window/size/viewport_height")))

func test_centre_is_half_the_picture() -> void:
	assert_vector(Screen.CENTRE).is_equal(Screen.SIZE / 2.0)

func test_the_minimum_window_is_one_times_the_picture() -> void:
	assert_vector(Vector2(Screen.MIN_WINDOW)).is_equal(Screen.SIZE)
