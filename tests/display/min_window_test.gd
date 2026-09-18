extends GdUnitTestSuite

# The window will not be dragged smaller than one times the picture (tr-1o0.1).

func test_the_window_will_not_go_below_one_times_the_picture() -> void:
	var w: Window = auto_free(Window.new())
	Display.apply_min_size(w)
	assert_vector(Vector2(w.min_size)).is_equal(Screen.SIZE)

func test_the_minimum_is_one_times_the_picture() -> void:
	assert_vector(Vector2(Screen.MIN_WINDOW)).is_equal(Screen.SIZE)
