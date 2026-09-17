extends GdUnitTestSuite
## MenuPush: one menu step per push, from keys, pad buttons and the stick.

const S := MenuPush.Step

var push: MenuPush

func before_test() -> void:
	push = MenuPush.new()

func _key(k: Key, pressed := true, echo := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.pressed = pressed
	e.echo = echo
	return e

func _button(b: JoyButton, pressed := true) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = b
	e.pressed = pressed
	return e

func _motion(axis: JoyAxis, value: float, device := 0) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.device = device
	e.axis = axis
	e.axis_value = value
	return e

func _steps(events: Array) -> Array:
	var out := []
	for e: InputEvent in events:
		out.append(push.read(e))
	return out

func test_keys_give_their_step() -> void:
	assert_array(_steps([_key(KEY_UP), _key(KEY_W), _key(KEY_DOWN), _key(KEY_S), _key(KEY_LEFT),
			_key(KEY_RIGHT), _key(KEY_ENTER), _key(KEY_SPACE), _key(KEY_ESCAPE)])) \
		.is_equal([S.UP, S.UP, S.DOWN, S.DOWN, S.LEFT, S.RIGHT, S.SELECT, S.SELECT, S.BACK])

func test_key_echo_and_release_give_none() -> void:
	assert_int(push.read(_key(KEY_DOWN, true, true))).is_equal(S.NONE)
	assert_int(push.read(_key(KEY_DOWN, false))).is_equal(S.NONE)

func test_pad_buttons_give_their_step() -> void:
	assert_array(_steps([_button(JOY_BUTTON_DPAD_UP), _button(JOY_BUTTON_DPAD_DOWN), _button(JOY_BUTTON_DPAD_LEFT),
			_button(JOY_BUTTON_DPAD_RIGHT), _button(JOY_BUTTON_A), _button(JOY_BUTTON_B)])) \
		.is_equal([S.UP, S.DOWN, S.LEFT, S.RIGHT, S.SELECT, S.BACK])
	assert_array(_steps([_button(JOY_BUTTON_A, false), _button(JOY_BUTTON_START), _button(JOY_BUTTON_Y)])) \
		.is_equal([S.NONE, S.NONE, S.NONE])

func test_held_stick_is_one_push() -> void:
	var events := []
	for v: float in [0.3, 0.6, 0.9, 1.0, 0.7]:
		events.append(_motion(JOY_AXIS_LEFT_Y, v))
	assert_array(_steps(events)).is_equal([S.NONE, S.DOWN, S.NONE, S.NONE, S.NONE])

func test_stick_pushes_again_after_returning_to_centre() -> void:
	assert_array(_steps([_motion(JOY_AXIS_LEFT_Y, 1.0), _motion(JOY_AXIS_LEFT_Y, 0.3), _motion(JOY_AXIS_LEFT_Y, 1.0)])) \
		.is_equal([S.DOWN, S.NONE, S.DOWN])

func test_stick_not_back_inside_release_does_not_rearm() -> void:
	assert_array(_steps([_motion(JOY_AXIS_LEFT_Y, 1.0), _motion(JOY_AXIS_LEFT_Y, 0.4), _motion(JOY_AXIS_LEFT_Y, 1.0)])) \
		.is_equal([S.DOWN, S.NONE, S.NONE])

func test_small_nudge_moves_nothing() -> void:
	assert_array(_steps([_motion(JOY_AXIS_LEFT_X, 0.2), _motion(JOY_AXIS_LEFT_X, 0.45), _motion(JOY_AXIS_LEFT_X, 0.0)])) \
		.is_equal([S.NONE, S.NONE, S.NONE])

func test_flick_across_counts_both_ways() -> void:
	assert_array(_steps([_motion(JOY_AXIS_LEFT_X, 1.0), _motion(JOY_AXIS_LEFT_X, -1.0)])).is_equal([S.RIGHT, S.LEFT])

func test_axes_and_pads_are_separate() -> void:
	assert_array(_steps([_motion(JOY_AXIS_LEFT_X, 1.0), _motion(JOY_AXIS_LEFT_Y, -1.0)])).is_equal([S.RIGHT, S.UP])
	push = MenuPush.new()
	assert_array(_steps([_motion(JOY_AXIS_LEFT_X, 1.0, 0), _motion(JOY_AXIS_LEFT_X, 1.0, 1)])).is_equal([S.RIGHT, S.RIGHT])

func test_unbound_axes_give_none() -> void:
	assert_array(_steps([_motion(JOY_AXIS_RIGHT_X, 1.0), _motion(JOY_AXIS_RIGHT_Y, 1.0),
			_motion(JOY_AXIS_TRIGGER_LEFT, 1.0), _motion(JOY_AXIS_TRIGGER_RIGHT, 1.0)])) \
		.is_equal([S.NONE, S.NONE, S.NONE, S.NONE])

func test_mouse_gives_none() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert_array(_steps([InputEventMouseMotion.new(), click])).is_equal([S.NONE, S.NONE])
