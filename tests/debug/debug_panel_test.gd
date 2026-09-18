extends GdUnitTestSuite
## The Debug panel's layout and input reading, without a scene.

func _key(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.pressed = true
	return e

func _button(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = true
	return e

func test_tab_step_reads_q_e_and_shoulders() -> void:
	assert_int(DebugPanel.tab_step(_key(KEY_Q))).is_equal(-1)
	assert_int(DebugPanel.tab_step(_key(KEY_E))).is_equal(1)
	assert_int(DebugPanel.tab_step(_button(JOY_BUTTON_LEFT_SHOULDER))).is_equal(-1)
	assert_int(DebugPanel.tab_step(_button(JOY_BUTTON_RIGHT_SHOULDER))).is_equal(1)
	assert_int(DebugPanel.tab_step(_key(KEY_A))).is_equal(0)

func test_tab_and_slot_hit_tests() -> void:
	assert_int(DebugPanel.tab_at(Vector2(DebugPanel.TAB_X + 1, 21))).is_equal(0)
	assert_int(DebugPanel.tab_at(Vector2(DebugPanel.TAB_X + 5 * DebugPanel.TAB_STEP + 1, 25))).is_equal(5)
	assert_int(DebugPanel.tab_at(Vector2(100, 25))).is_equal(-1)
	assert_int(DebugPanel.slot_at(Vector2(DebugPanel.ROW_X + 8, 37))).is_equal(0)
	assert_int(DebugPanel.slot_at(Vector2(DebugPanel.ROW_X + 8, 37 + 8 * 14))).is_equal(8)
	assert_int(DebugPanel.slot_at(Vector2(DebugPanel.ROW_X + 8, 49))).is_equal(-1)
	assert_int(DebugPanel.slot_at(Vector2(DebugPanel.ROW_X + 8, 37 + 9 * 14))).is_equal(-1)

func test_value_shown() -> void:
	var plain := DebugRow.new("A")
	var speed := DebugRow.new("Speed", func() -> String: return "x1", func(_d: int) -> void: pass)
	var count := DebugRow.new("Count", func() -> String: return "5")
	assert_str(DebugPanel.value_shown(plain, true)).is_equal("")
	assert_str(DebugPanel.value_shown(speed, false)).is_equal("x1")
	assert_str(DebugPanel.value_shown(speed, true)).is_equal("← x1 →")
	assert_str(DebugPanel.value_shown(count, true)).is_equal("5")

func test_panel_and_tabs_fit() -> void:
	var panel := DebugPanel.PANEL_RECT
	assert_float(panel.end.x).is_equal(Screen.WIDTH)
	assert_float(panel.end.y).is_less_equal(165.0)
	for i in DebugMenu.TAB_NAMES.size():
		assert_bool(panel.encloses(DebugPanel.tab_rect(i))).is_true()
		assert_int(Glyphs.width(DebugMenu.TAB_NAMES[i])).is_less_equal(int(DebugPanel.TAB_SIZE.x))
	assert_float(DebugPanel.row_rect(DebugMenu.VISIBLE_ROWS - 1).end.y).is_less_equal(panel.end.y)
