extends GdUnitTestSuite
## PointerRule: the pointer hides only while a menu is open and a key or pad was used last.

var rule: PointerRule

func before_test() -> void:
	rule = PointerRule.new()

func _key(key: Key, pressed := true, echo := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = key
	e.pressed = pressed
	e.echo = echo
	return e

func _motion(relative: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.relative = relative
	return e

func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e

func _pad(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = pressed
	return e

func _stick(value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_LEFT_Y
	e.axis_value = value
	return e

func test_starts_shown_with_the_mouse_last() -> void:
	assert_bool(rule.mouse_last).is_true()
	assert_bool(rule.hidden).is_false()

func test_key_in_a_menu_hides() -> void:
	rule.set_menu_open(1, true)
	rule.observe(_key(KEY_DOWN))
	assert_bool(rule.hidden).is_true()

func test_key_with_no_menu_open_keeps_it_shown() -> void:
	rule.observe(_key(KEY_W))
	assert_bool(rule.mouse_last).is_false()
	assert_bool(rule.hidden).is_false()

func test_menu_opening_after_a_key_hides() -> void:
	rule.observe(_key(KEY_ESCAPE))
	rule.set_menu_open(1, true)
	assert_bool(rule.hidden).is_true()

func test_menu_opening_after_a_mouse_move_shows() -> void:
	rule.observe(_key(KEY_ESCAPE))
	rule.observe(_motion(Vector2(3, 0)))
	rule.set_menu_open(1, true)
	assert_bool(rule.hidden).is_false()

func test_mouse_move_shows_it_again() -> void:
	rule.set_menu_open(1, true)
	rule.observe(_key(KEY_DOWN))
	assert_bool(rule.hidden).is_true()
	rule.observe(_motion(Vector2(0, -2)))
	assert_bool(rule.hidden).is_false()

func test_zero_motion_is_not_a_move() -> void:
	rule.set_menu_open(1, true)
	rule.observe(_key(KEY_DOWN))
	rule.observe(_motion(Vector2.ZERO))
	assert_bool(rule.hidden).is_true()

func test_click_shows_it() -> void:
	rule.set_menu_open(1, true)
	rule.observe(_key(KEY_DOWN))
	rule.observe(_click())
	assert_bool(rule.hidden).is_false()

func test_echo_and_release_change_nothing() -> void:
	rule.set_menu_open(1, true)
	rule.observe(_motion(Vector2(1, 0)))
	rule.observe(_key(KEY_DOWN, true, true))
	assert_bool(rule.hidden).is_false()
	rule.observe(_key(KEY_DOWN, false))
	assert_bool(rule.hidden).is_false()

func test_pad_button_hides_and_its_release_does_not_show() -> void:
	rule.set_menu_open(1, true)
	rule.observe(_pad(JOY_BUTTON_DPAD_DOWN, true))
	assert_bool(rule.hidden).is_true()
	rule.observe(_pad(JOY_BUTTON_DPAD_DOWN, false))
	assert_bool(rule.hidden).is_true()

func test_stick_past_the_dead_zone_hides() -> void:
	rule.set_menu_open(1, true)
	rule.observe(_stick(0.1))
	assert_bool(rule.hidden).is_false()
	rule.observe(_stick(0.2))
	assert_bool(rule.hidden).is_true()

func test_closing_the_last_menu_shows_it() -> void:
	rule.set_menu_open(1, true)
	rule.set_menu_open(2, true)
	rule.observe(_key(KEY_DOWN))
	assert_bool(rule.hidden).is_true()
	rule.set_menu_open(1, false)
	assert_bool(rule.hidden).is_true()
	rule.set_menu_open(2, false)
	assert_bool(rule.hidden).is_false()
	rule.set_menu_open(2, true)
	assert_bool(rule.hidden).is_true()

func test_closing_an_unknown_menu_is_harmless() -> void:
	rule.set_menu_open(99, false)
	assert_bool(rule.hidden).is_false()

func test_forget_device_shows_it_and_keeps_menus() -> void:
	rule.set_menu_open(1, true)
	rule.observe(_key(KEY_DOWN))
	rule.forget_device()
	assert_bool(rule.hidden).is_false()
	assert_bool(rule.mouse_last).is_true()
	rule.observe(_key(KEY_DOWN))
	assert_bool(rule.hidden).is_true()

func test_changed_only_on_a_change() -> void:
	var seen: Array = []
	rule.changed.connect(func() -> void: seen.append(1))
	rule.set_menu_open(1, true)
	rule.observe(_key(KEY_DOWN))
	assert_int(seen.size()).is_equal(1)
	rule.observe(_key(KEY_UP))
	assert_int(seen.size()).is_equal(1)
	rule.observe(_motion(Vector2(1, 0)))
	assert_int(seen.size()).is_equal(2)

func test_is_move() -> void:
	assert_bool(PointerRule.is_move(_motion(Vector2(1, 0)))).is_true()
	assert_bool(PointerRule.is_move(_motion(Vector2.ZERO))).is_false()
	assert_bool(PointerRule.is_move(_click())).is_false()
	assert_bool(PointerRule.is_move(_key(KEY_DOWN))).is_false()
