extends GdUnitTestSuite
## One press and one release per push of a play action, sticks and triggers by sign.

const A := Controls.Action
const D := Controls.Device

var ap: ActionPress

func before_test() -> void:
	ap = ActionPress.new()
	InputDevice.use_controls(Controls.new())
	InputDevice.controls.set_slot(A.BUILD_LIST, D.CONTROLLER, 0, _motion(0, JOY_AXIS_RIGHT_Y, -1.0))
	InputDevice.controls.set_slot(A.USE, D.CONTROLLER, 0, _motion(0, JOY_AXIS_TRIGGER_RIGHT, 1.0))

func after_test() -> void:
	InputDevice.use_controls(Controls.new())

func _motion(device: int, axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.device = device
	e.axis = axis
	e.axis_value = value
	return e

func _read(e: InputEvent) -> InputEvent:
	ap.read(e)
	return e

func _ry(value: float, device := 0) -> InputEvent:
	return _read(_motion(device, JOY_AXIS_RIGHT_Y, value))

func test_key_press_and_release_edges() -> void:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_E
	e.pressed = true
	_read(e)
	assert_bool(ap.pressed(e, &"use")).is_true()
	assert_bool(ap.released(e, &"use")).is_false()
	var echo := e.duplicate() as InputEventKey
	echo.echo = true
	_read(echo)
	assert_bool(ap.pressed(echo, &"use")).is_false()
	var up := InputEventKey.new()
	up.physical_keycode = KEY_E
	_read(up)
	assert_bool(ap.released(up, &"use")).is_true()

func test_stick_press_is_one_edge() -> void:
	assert_bool(ap.pressed(_ry(-0.6), &"build")).is_true()
	assert_bool(ap.pressed(_ry(-0.9), &"build")).is_false()
	var e := _ry(-0.4)
	assert_bool(ap.pressed(e, &"build")).is_false()
	assert_bool(ap.released(e, &"build")).is_false()
	e = _ry(-0.2)
	assert_bool(ap.released(e, &"build")).is_true()
	assert_bool(ap.pressed(e, &"build")).is_false()
	assert_bool(ap.pressed(_ry(-0.6), &"build")).is_true()

func test_other_sign_does_nothing() -> void:
	var e := _ry(0.9)
	assert_bool(ap.pressed(e, &"build")).is_false()
	assert_bool(ap.released(e, &"build")).is_false()
	e = _ry(0.0)
	assert_bool(ap.pressed(e, &"build")).is_false()
	assert_bool(ap.released(e, &"build")).is_false()

func test_flip_in_one_event_releases() -> void:
	_ry(-0.9)
	var e := _ry(0.9)
	assert_bool(ap.released(e, &"build")).is_true()
	assert_bool(ap.pressed(e, &"build")).is_false()

func test_between_release_and_push_waits() -> void:
	assert_bool(ap.pressed(_ry(-0.45), &"build")).is_false()
	assert_bool(ap.pressed(_ry(-0.5), &"build")).is_true()

func test_pads_are_apart() -> void:
	assert_bool(ap.pressed(_ry(-0.9, 0), &"build")).is_true()
	assert_bool(ap.pressed(_ry(-0.9, 1), &"build")).is_true()
	assert_bool(ap.released(_ry(0.0, 0), &"build")).is_true()
	assert_bool(ap.pressed(_ry(-0.9, 1), &"build")).is_false()

func test_trigger() -> void:
	assert_bool(ap.pressed(_read(_motion(0, JOY_AXIS_TRIGGER_RIGHT, 0.9)), &"use")).is_true()
	assert_bool(ap.pressed(_read(_motion(0, JOY_AXIS_TRIGGER_RIGHT, 1.0)), &"use")).is_false()
	assert_bool(ap.released(_read(_motion(0, JOY_AXIS_TRIGGER_RIGHT, 0.0)), &"use")).is_true()

func test_unbound_axis_is_no_action() -> void:
	var e := _read(_motion(0, JOY_AXIS_LEFT_X, 0.9))
	for action: StringName in [&"use", &"build", &"pause"]:
		assert_bool(ap.pressed(e, action)).is_false()
