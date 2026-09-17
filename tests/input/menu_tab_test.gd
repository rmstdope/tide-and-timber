extends GdUnitTestSuite
## Which way a menu_tab press turns.

func test_q_e_and_shoulders() -> void:
	var q := InputEventKey.new()
	q.physical_keycode = KEY_Q
	var e := InputEventKey.new()
	e.physical_keycode = KEY_E
	var lb := InputEventJoypadButton.new()
	lb.button_index = JOY_BUTTON_LEFT_SHOULDER
	var rb := InputEventJoypadButton.new()
	rb.button_index = JOY_BUTTON_RIGHT_SHOULDER
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	assert_int(MenuTab.step(q)).is_equal(-1)
	assert_int(MenuTab.step(e)).is_equal(1)
	assert_int(MenuTab.step(lb)).is_equal(-1)
	assert_int(MenuTab.step(rb)).is_equal(1)
	assert_int(MenuTab.step(a)).is_equal(0)
	assert_int(MenuTab.step(InputEventMouseButton.new())).is_equal(0)
