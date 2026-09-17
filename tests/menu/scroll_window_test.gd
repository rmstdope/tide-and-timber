extends GdUnitTestSuite
## ScrollWindow: the shared rule that keeps a list's highlighted item inside its visible band,
## and the ▲ / ▼ marks drawn where rows are hidden.

func test_follow_moves_the_least_distance_down() -> void:
	assert_int(ScrollWindow.follow(190, 54, 52, 80, 0)).is_equal(26)

func test_follow_moves_the_least_distance_up() -> void:
	assert_int(ScrollWindow.follow(190, 54, 20, 48, 58)).is_equal(20)

func test_follow_keeps_the_offset_while_the_item_is_visible() -> void:
	assert_int(ScrollWindow.follow(190, 54, 20, 48, 0)).is_equal(0)
	assert_int(ScrollWindow.follow(190, 54, 52, 80, 26)).is_equal(26)

func test_follow_is_zero_when_the_content_fits() -> void:
	assert_int(ScrollWindow.follow(100, 100, 80, 96, 5)).is_equal(0)
	assert_int(ScrollWindow.follow(50, 100, 0, 10, 0)).is_equal(0)

func test_a_taller_item_shows_its_top() -> void:
	assert_int(ScrollWindow.follow(190, 32, 0, 48, 80)).is_equal(0)
	assert_int(ScrollWindow.follow(190, 54, 116, 190, 0)).is_equal(116)

func test_follow_clamps() -> void:
	assert_int(ScrollWindow.follow(132, 82, 80, 132, 0)).is_equal(50)
	assert_int(ScrollWindow.follow(100, 60, 90, 100, 70)).is_equal(40)
	assert_int(ScrollWindow.follow(190, 54, 0, 10, -5)).is_equal(0)

func test_hidden_above_and_below() -> void:
	assert_bool(ScrollWindow.hidden_above(0)).is_false()
	assert_bool(ScrollWindow.hidden_above(1)).is_true()
	assert_bool(ScrollWindow.hidden_below(0, 190, 54)).is_true()
	assert_bool(ScrollWindow.hidden_below(116, 190, 54)).is_true()
	assert_bool(ScrollWindow.hidden_below(136, 190, 54)).is_false()

func test_band_in_local_units() -> void:
	var twice := Transform2D(0.0, Vector2(2, 2), 0.0, Vector2(-160, -90))
	assert_that(ScrollWindow.band(twice, 152)).is_equal(Vector2(46, 120))
	assert_that(ScrollWindow.band(twice, 108)).is_equal(Vector2(46, 98))
	assert_that(ScrollWindow.band(Transform2D(0.0, Vector2(1.5, 1.5), 0.0, Vector2(-80, -45)), 158)) \
			.is_equal(Vector2(32, 134))
	assert_that(ScrollWindow.band(Transform2D.IDENTITY, 164)).is_equal(Vector2(2, 162))

func test_mark_origin_centres_the_glyph() -> void:
	var font := load("res://assets/fonts/PressStart2P-Regular.ttf") as Font
	assert_that(ScrollWindow.mark_origin(font, Vector2(78, 5), true)).is_equal(Vector2(74, 9))
	assert_that(ScrollWindow.mark_origin(font, Vector2(78, 69), false)).is_equal(Vector2(74, 73))
