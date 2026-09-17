extends GdUnitTestSuite
## The Debug panel's Time page rules: Day, Time and Speed limits, and the rows over a DayNight.

const M := 1440.0

func test_day_after_stops_at_1_and_99() -> void:
	assert_float(DebugTime.day_after(780.0, 1)).is_equal(2220.0)
	assert_float(DebugTime.day_after(780.0, -1)).is_equal(780.0)
	assert_float(DebugTime.day_after(98 * M + 780.0, 1)).is_equal(98 * M + 780.0)
	assert_float(DebugTime.day_after(98 * M + 780.0, -1)).is_equal(97 * M + 780.0)

func test_time_after_steps_to_half_hours() -> void:
	assert_float(DebugTime.time_after(780.0, 1)).is_equal(810.0)
	assert_float(DebugTime.time_after(780.0, -1)).is_equal(750.0)
	assert_float(DebugTime.time_after(797.3, 1)).is_equal(810.0)
	assert_float(DebugTime.time_after(797.3, -1)).is_equal(780.0)
	assert_float(DebugTime.time_after(1425.0, 1)).is_equal(1440.0)
	assert_float(DebugTime.time_after(1440.0, -1)).is_equal(1410.0)

func test_time_after_stops_at_the_ends() -> void:
	assert_float(DebugTime.time_after(0.0, -1)).is_equal(0.0)
	assert_float(DebugTime.time_after(15.0, -1)).is_equal(0.0)
	assert_float(DebugTime.time_after(99 * M - 30.0, 1)).is_equal(99 * M - 30.0)
	assert_float(DebugTime.time_after(99 * M - 40.0, 1)).is_equal(99 * M - 30.0)

func test_speed_after_walks_the_list_without_wrap() -> void:
	assert_float(DebugTime.speed_after(1.0, 1)).is_equal(2.0)
	assert_float(DebugTime.speed_after(1.0, -1)).is_equal(0.5)
	assert_float(DebugTime.speed_after(0.25, -1)).is_equal(0.25)
	assert_float(DebugTime.speed_after(32.0, 1)).is_equal(32.0)
	assert_float(DebugTime.speed_after(3.0, 1)).is_equal(4.0)
	assert_float(DebugTime.speed_after(3.0, -1)).is_equal(2.0)
	assert_float(DebugTime.speed_after(60.0, 1)).is_equal(60.0)
	assert_float(DebugTime.speed_after(60.0, -1)).is_equal(32.0)

func test_speed_text() -> void:
	var texts: Array = DebugTime.SPEEDS.map(func(s: float) -> String: return DebugTime.speed_text(s))
	assert_array(texts).is_equal(["x0.25", "x0.5", "x1", "x2", "x4", "x8", "x16", "x32"])

func _values(rows: Array[DebugRow]) -> Array:
	return rows.map(func(r: DebugRow) -> String: return r.value_text())

func test_rows_over_a_day_night() -> void:
	var dn: DayNight = auto_free(load("res://src/day_night/day_night.tscn").instantiate())
	add_child(dn)
	var rows := DebugTime.rows(dn)
	assert_array(rows.map(func(r: DebugRow) -> String: return r.label)).is_equal(["Day", "Time", "Speed"])
	assert_array(_values(rows)).is_equal(["1", "13:00", "x1"])
	rows[0].step.call(1)
	assert_str(rows[0].value_text()).is_equal("2")
	assert_float(dn.clock.total_minutes).is_equal(2220.0)
	rows[1].step.call(1)
	assert_str(rows[1].value_text()).is_equal("13:30")
	assert_float(dn.clock.total_minutes).is_equal(2250.0)
	rows[2].step.call(-1)
	assert_str(rows[2].value_text()).is_equal("x0.5")
	assert_float(dn.time_scale).is_equal(0.5)
	assert_array(rows.map(func(r: DebugRow) -> bool: return r.repeats)).is_equal([false, true, false])

func test_rows_without_a_clock() -> void:
	var rows := DebugTime.rows(null)
	assert_array(_values(rows)).is_equal(["1", "13:00", "x1"])
	for r in rows:
		assert_bool(r.step.is_valid()).is_false()
