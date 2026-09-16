extends GdUnitTestSuite

func test_lit_in_afternoon_goes_out_next_morning() -> void:
	assert_float(FireLife.out_at(780.0)).is_equal(1860.0)

func test_lit_before_seven_goes_out_same_morning() -> void:
	assert_float(FireLife.out_at(1440.0 + 400.0)).is_equal(1860.0)

func test_lit_exactly_at_seven_waits_a_day() -> void:
	assert_float(FireLife.out_at(1860.0)).is_equal(3300.0)

func test_lit_just_after_seven() -> void:
	assert_float(FireLife.out_at(1860.5)).is_equal(3300.0)

func test_lit_before_midnight() -> void:
	assert_float(FireLife.out_at(1439.0)).is_equal(1860.0)

func test_is_out_at_and_after() -> void:
	assert_bool(FireLife.is_out(1860.0, 1859.9)).is_false()
	assert_bool(FireLife.is_out(1860.0, 1860.0)).is_true()
	assert_bool(FireLife.is_out(INF, 99999.0)).is_false()
