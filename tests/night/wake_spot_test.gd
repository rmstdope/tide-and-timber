extends GdUnitTestSuite
## Where he wakes after a collapse: beside the lean-to, else where he first woke.

func test_front_left_of_lean_to() -> void:
	assert_that(WakeSpot.beside_lean_to(Vector2i(92, 13), Vector2i(92, 14))).is_equal(Vector2i(91, 14))

func test_skips_a_rock() -> void:
	assert_that(WakeSpot.beside_lean_to(Vector2i(100, 12), Waking.WAKE_CELL)).is_equal(Vector2i(101, 13))

func test_falls_back_to_where_he_first_woke() -> void:
	assert_that(WakeSpot.beside_lean_to(Vector2i(92, 17), Vector2i(92, 14))).is_equal(Vector2i(92, 14))

func test_spring_cell_not_open() -> void:
	assert_bool(WakeSpot.is_open(Vector2i(96, 9))).is_false()
	assert_bool(WakeSpot.is_open(Vector2i(91, 14))).is_true()
