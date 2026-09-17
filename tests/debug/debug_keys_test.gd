extends GdUnitTestSuite
## F1-F4's rules: what each key flips and the line it returns.

var dn: DayNight

func before_test() -> void:
	dn = auto_free(load("res://src/day_night/day_night.tscn").instantiate())
	add_child(dn)

func after_test() -> void:
	DebugSwitches.readout = false
	DebugSwitches.collision_areas = false
	DebugSwitches.use_areas = false
	DebugSwitches.walk_through = false

func _all_off() -> void:
	assert_bool(DebugSwitches.readout).is_false()
	assert_bool(DebugSwitches.collision_areas).is_false()
	assert_bool(DebugSwitches.use_areas).is_false()
	assert_bool(DebugSwitches.walk_through).is_false()

func test_next_speed_cycles_and_wraps() -> void:
	var pairs := [[1.0, 2.0], [2.0, 4.0], [4.0, 8.0], [8.0, 16.0], [16.0, 32.0], [32.0, 1.0],
		[0.25, 1.0], [0.5, 1.0], [3.0, 4.0], [60.0, 1.0]]
	for p: Array in pairs:
		assert_float(DebugKeys.next_speed(p[0])).override_failure_message(str(p)).is_equal(p[1])

func test_f1_flips_readout_with_its_line() -> void:
	assert_str(DebugKeys.press(DebugShortcut.Name.READOUT, dn)).is_equal("Readout on")
	assert_bool(DebugSwitches.readout).is_true()
	assert_str(DebugKeys.press(DebugShortcut.Name.READOUT, dn)).is_equal("Readout off")
	_all_off()

func test_f2_flips_collision_areas_with_its_line() -> void:
	assert_str(DebugKeys.press(DebugShortcut.Name.COLLISION_AREAS, dn)).is_equal("Collision areas on")
	assert_bool(DebugSwitches.collision_areas).is_true()
	assert_bool(DebugSwitches.readout).is_false()
	assert_str(DebugKeys.press(DebugShortcut.Name.COLLISION_AREAS, dn)).is_equal("Collision areas off")
	_all_off()

func test_f3_cycles_the_clock_speed() -> void:
	assert_float(dn.time_scale).is_equal(1.0)
	assert_str(DebugKeys.press(DebugShortcut.Name.SPEED, dn)).is_equal("Speed x2")
	assert_float(dn.time_scale).is_equal(2.0)
	var line := ""
	for i in 4:
		line = DebugKeys.press(DebugShortcut.Name.SPEED, dn)
	assert_str(line).is_equal("Speed x32")
	assert_str(DebugKeys.press(DebugShortcut.Name.SPEED, dn)).is_equal("Speed x1")
	assert_float(dn.time_scale).is_equal(1.0)

func test_f3_from_a_slow_speed_goes_to_x1() -> void:
	dn.time_scale = 0.25
	assert_str(DebugKeys.press(DebugShortcut.Name.SPEED, dn)).is_equal("Speed x1")

func test_f4_flips_walk_through_with_its_line() -> void:
	assert_str(DebugKeys.press(DebugShortcut.Name.WALK_THROUGH, dn)).is_equal("Walk through things on")
	assert_bool(DebugSwitches.walk_through).is_true()
	assert_str(DebugKeys.press(DebugShortcut.Name.WALK_THROUGH, dn)).is_equal("Walk through things off")
	_all_off()

func test_without_a_clock_f3_and_f4_do_nothing() -> void:
	assert_str(DebugKeys.press(DebugShortcut.Name.SPEED, null)).is_equal("")
	assert_str(DebugKeys.press(DebugShortcut.Name.WALK_THROUGH, null)).is_equal("")
	assert_bool(DebugSwitches.walk_through).is_false()
	assert_str(DebugKeys.press(DebugShortcut.Name.READOUT, null)).is_equal("Readout on")

func test_no_shortcut_does_nothing() -> void:
	assert_str(DebugKeys.press(DebugShortcut.Name.NONE, dn)).is_equal("")
	_all_off()
	assert_float(dn.time_scale).is_equal(1.0)

func test_every_line_draws_in_glyphs_and_fits() -> void:
	var lines := [DebugKeys.READOUT_ON, DebugKeys.READOUT_OFF, DebugKeys.COLLISION_ON, DebugKeys.COLLISION_OFF,
		DebugKeys.WALK_THROUGH_ON, DebugKeys.WALK_THROUGH_OFF, "Speed x32", "Speed x16"]
	for line: String in lines:
		for ch in line:
			if ch != " ":
				assert_int(Glyphs.ORDER.find(ch)).override_failure_message(line + ": " + ch).is_greater_equal(0)
		assert_int(Glyphs.width(line)).override_failure_message(line).is_less_equal(int(DebugKeyLine.BOX.size.x) - 8)
