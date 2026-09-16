extends GdUnitTestSuite
## The night's rules: the 20:30 warning, the 5 seconds outside the firelight, frost, the collapse.

var watch: NightWatch
var got: Array[String] = []

func before_test() -> void:
	watch = NightWatch.new()
	got = []
	watch.warned.connect(func() -> void: got.append("warned"))
	watch.stepped_out.connect(func() -> void: got.append("stepped_out"))
	watch.collapsed.connect(func() -> void: got.append("collapsed"))

func test_constants() -> void:
	assert_int(NightWatch.WARN_MINUTE).is_equal(1230)
	assert_int(NightWatch.NIGHT_START_MINUTE).is_equal(1260)
	assert_int(NightWatch.NIGHT_END_MINUTE).is_equal(300)
	assert_float(NightWatch.GRACE_SECONDS).is_equal(5.0)

func test_is_night_window() -> void:
	assert_bool(NightWatch.is_night(1259.9)).is_false()
	assert_bool(NightWatch.is_night(1260.0)).is_true()
	assert_bool(NightWatch.is_night(0.0)).is_true()
	assert_bool(NightWatch.is_night(299.9)).is_true()
	assert_bool(NightWatch.is_night(300.0)).is_false()
	assert_bool(NightWatch.is_night(780.0)).is_false()

func test_next_morning() -> void:
	assert_float(NightWatch.next_morning(1300.0)).is_equal(1800.0)
	assert_float(NightWatch.next_morning(1440.0 + 200.0)).is_equal(1800.0)
	assert_float(NightWatch.next_morning(1800.0)).is_equal(3240.0)
	assert_float(NightWatch.next_morning(780.0)).is_equal(1800.0)

func test_warns_once_at_2030_when_outside() -> void:
	watch.reset(1200.0)
	watch.advance(0.1, 1229.0, false)
	assert_array(got).is_empty()
	watch.advance(0.1, 1230.0, false)
	assert_array(got).is_equal(["warned"])
	watch.advance(0.1, 1240.0, false)
	assert_array(got).is_equal(["warned"])

func test_no_warning_in_light_at_2030_nor_after() -> void:
	watch.reset(1200.0)
	watch.advance(0.1, 1231.0, true)
	watch.advance(0.1, 1240.0, false)
	assert_array(got).is_empty()

func test_warns_again_next_evening() -> void:
	watch.reset(1200.0)
	watch.advance(0.1, 1230.0, false)
	watch.reset(1800.0)
	watch.advance(0.1, 1230.0 + 1440.0, false)
	assert_array(got).is_equal(["warned", "warned"])

func test_warning_crossed_by_a_jump() -> void:
	watch.reset(1215.0)
	watch.advance(0.0, 1245.0, false)
	assert_array(got).is_equal(["warned"])

func test_outside_at_2100_steps_out_and_frost_grows() -> void:
	watch.reset(1250.0)
	watch.advance(0.5, 1259.0, false)
	assert_bool(watch.outside).is_false()
	assert_float(watch.frost).is_equal(0.0)
	watch.advance(0.5, 1260.0, false)
	assert_array(got).is_equal(["stepped_out"])
	assert_bool(watch.outside).is_true()
	assert_float(watch.outside_seconds).is_equal(0.0)
	watch.advance(2.5, 1261.0, false)
	assert_float(watch.frost).is_equal_approx(0.5, 0.001)
	assert_bool(watch.has_collapsed).is_false()

func test_collapses_after_five_seconds_once() -> void:
	watch.reset(1260.0)
	watch.advance(0.0, 1260.0, false)
	watch.advance(4.5, 1262.0, false)
	assert_bool(got.has("collapsed")).is_false()
	watch.advance(0.5, 1262.5, false)
	assert_str(got.back()).is_equal("collapsed")
	assert_bool(watch.has_collapsed).is_true()
	watch.advance(10.0, 1270.0, false)
	assert_int(got.count("collapsed")).is_equal(1)

func test_back_inside_melts_and_resets() -> void:
	watch.reset(1260.0)
	watch.advance(0.0, 1260.0, false)
	watch.advance(4.0, 1262.0, false)
	assert_float(watch.frost).is_equal_approx(0.8, 0.001)
	watch.advance(0.5, 1262.5, true)
	assert_bool(watch.outside).is_false()
	assert_float(watch.outside_seconds).is_equal(0.0)
	assert_float(watch.frost).is_equal_approx(0.3, 0.001)
	watch.advance(1.0, 1263.0, true)
	assert_float(watch.frost).is_equal(0.0)

func test_stepping_out_again_starts_fresh() -> void:
	watch.reset(1260.0)
	watch.advance(0.0, 1260.0, false)
	watch.advance(4.5, 1261.0, false)
	watch.advance(0.0, 1261.0, true)
	watch.advance(0.0, 1262.0, false)
	assert_str(got.back()).is_equal("stepped_out")
	assert_int(got.count("stepped_out")).is_equal(2)
	watch.advance(4.5, 1263.0, false)
	assert_bool(watch.has_collapsed).is_false()
	watch.advance(0.5, 1263.5, false)
	assert_bool(watch.has_collapsed).is_true()

func test_danger_ends_at_0500() -> void:
	watch.reset(1440.0 + 290.0)
	watch.advance(0.0, 1440.0 + 299.0, false)
	assert_bool(watch.outside).is_true()
	watch.advance(2.0, 1440.0 + 300.0, false)
	assert_bool(watch.outside).is_false()
	assert_float(watch.frost).is_equal(0.0)
	watch.advance(10.0, 1440.0 + 301.0, false)
	assert_bool(watch.has_collapsed).is_false()

func test_safe_all_night_in_light() -> void:
	watch.reset(1250.0)
	for m in range(1250, 1741, 10):
		watch.advance(1.0, float(m), true)
	assert_array(got).is_empty()
	assert_float(watch.frost).is_equal(0.0)

func test_reset_clears() -> void:
	watch.reset(1260.0)
	watch.advance(0.0, 1260.0, false)
	watch.advance(5.0, 1262.0, false)
	assert_bool(watch.has_collapsed).is_true()
	watch.reset(1800.0)
	assert_bool(watch.has_collapsed).is_false()
	assert_bool(watch.outside).is_false()
	assert_float(watch.frost).is_equal(0.0)
	assert_float(watch.outside_seconds).is_equal(0.0)
