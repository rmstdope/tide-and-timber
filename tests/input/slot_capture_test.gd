extends GdUnitTestSuite
## The waiting box's rules: which raw event goes into a slot, hold-to-cancel, unarmed and drained axes.

const D := Controls.Device

var cap: SlotCapture

func before_test() -> void:
	cap = SlotCapture.new()

func _key(code: Key, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	return e

func _button(index: JoyButton, pressed: bool = true) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = index
	e.pressed = pressed
	return e

func _axis(axis: JoyAxis, value: float, device: int = 0) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.device = device
	e.axis = axis
	e.axis_value = value
	return e

func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e

# --- keyboard

func test_a_key_press_is_taken() -> void:
	cap.open(D.KEYBOARD)
	assert_int(cap.read(_key(KEY_Q))).is_equal(SlotCapture.Result.TAKEN)
	assert_int((cap.taken as InputEventKey).physical_keycode).is_equal(KEY_Q)
	assert_bool(cap.is_open).is_false()

func test_releases_of_other_keys_wait() -> void:
	cap.open(D.KEYBOARD)
	assert_int(cap.read(_key(KEY_Q, false))).is_equal(SlotCapture.Result.WAITING)
	assert_bool(cap.is_open).is_true()

func test_esc_tap_goes_in() -> void:
	cap.open(D.KEYBOARD)
	assert_int(cap.read(_key(KEY_ESCAPE))).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.advance(0.5)).is_equal(SlotCapture.Result.WAITING)
	assert_float(cap.hold_progress).is_equal_approx(0.5, 0.0001)
	assert_int(cap.read(_key(KEY_ESCAPE, false))).is_equal(SlotCapture.Result.TAKEN)
	assert_int((cap.taken as InputEventKey).physical_keycode).is_equal(KEY_ESCAPE)

func test_esc_held_a_second_cancels() -> void:
	cap.open(D.KEYBOARD)
	cap.read(_key(KEY_ESCAPE))
	assert_int(cap.advance(0.6)).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.advance(0.6)).is_equal(SlotCapture.Result.CANCELLED)
	assert_object(cap.taken).is_null()
	assert_bool(cap.is_open).is_false()
	assert_float(cap.hold_progress).is_equal(0.0)
	assert_int(cap.read(_key(KEY_ESCAPE, false))).is_equal(SlotCapture.Result.WAITING)
	assert_object(cap.taken).is_null()

func test_another_key_while_holding_esc_goes_in() -> void:
	cap.open(D.KEYBOARD)
	cap.read(_key(KEY_ESCAPE))
	assert_int(cap.read(_key(KEY_Q))).is_equal(SlotCapture.Result.TAKEN)
	assert_int((cap.taken as InputEventKey).physical_keycode).is_equal(KEY_Q)

func test_advance_without_a_hold_does_nothing() -> void:
	cap.open(D.KEYBOARD)
	assert_int(cap.advance(5.0)).is_equal(SlotCapture.Result.WAITING)
	assert_bool(cap.is_open).is_true()

func test_echo_is_ignored() -> void:
	cap.open(D.KEYBOARD)
	assert_int(cap.read(_key(KEY_Q, true, true))).is_equal(SlotCapture.Result.WAITING)

func test_system_keys_are_ignored() -> void:
	cap.open(D.KEYBOARD)
	assert_int(cap.read(_key(KEY_META))).is_equal(SlotCapture.Result.WAITING)
	var none := _key(KEY_Q)
	none.physical_keycode = KEY_NONE
	assert_int(cap.read(none)).is_equal(SlotCapture.Result.WAITING)
	assert_bool(cap.is_open).is_true()

func test_wrong_device_on_keyboard() -> void:
	cap.open(D.KEYBOARD)
	assert_int(cap.read(_button(JOY_BUTTON_A))).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.read(_axis(JOY_AXIS_LEFT_Y, 1.0))).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.read(_click())).is_equal(SlotCapture.Result.WAITING)
	assert_bool(cap.is_open).is_true()

# --- controller

func test_a_button_press_is_taken() -> void:
	cap.open(D.CONTROLLER)
	assert_int(cap.read(_button(JOY_BUTTON_Y))).is_equal(SlotCapture.Result.TAKEN)
	assert_int((cap.taken as InputEventJoypadButton).button_index).is_equal(JOY_BUTTON_Y)

func test_start_and_dpad_are_taken() -> void:
	cap.open(D.CONTROLLER)
	assert_int(cap.read(_button(JOY_BUTTON_START))).is_equal(SlotCapture.Result.TAKEN)
	cap.open(D.CONTROLLER)
	assert_int(cap.read(_button(JOY_BUTTON_DPAD_LEFT))).is_equal(SlotCapture.Result.TAKEN)

func test_b_tap_goes_in() -> void:
	cap.open(D.CONTROLLER)
	assert_int(cap.read(_button(JOY_BUTTON_B))).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.read(_button(JOY_BUTTON_B, false))).is_equal(SlotCapture.Result.TAKEN)
	assert_int((cap.taken as InputEventJoypadButton).button_index).is_equal(JOY_BUTTON_B)

func test_b_held_a_second_cancels() -> void:
	cap.open(D.CONTROLLER)
	cap.read(_button(JOY_BUTTON_B))
	assert_int(cap.advance(1.0)).is_equal(SlotCapture.Result.CANCELLED)

func test_stick_inside_the_dead_zone_waits() -> void:
	cap.open(D.CONTROLLER)
	assert_int(cap.read(_axis(JOY_AXIS_LEFT_Y, 0.19))).is_equal(SlotCapture.Result.WAITING)

func test_stick_past_the_dead_zone_is_taken() -> void:
	cap.open(D.CONTROLLER)
	assert_int(cap.read(_axis(JOY_AXIS_LEFT_Y, -0.2))).is_equal(SlotCapture.Result.TAKEN)
	cap.open(D.CONTROLLER)
	assert_int(cap.read(_axis(JOY_AXIS_TRIGGER_RIGHT, 0.5))).is_equal(SlotCapture.Result.TAKEN)

func test_held_axis_waits_until_released() -> void:
	var held: Array[Vector2i] = [Vector2i(1, 1)]
	cap.open(D.CONTROLLER, held)
	assert_int(cap.read(_axis(JOY_AXIS_LEFT_Y, 0.9))).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.read(_axis(JOY_AXIS_LEFT_Y, -0.9))).is_equal(SlotCapture.Result.TAKEN)
	cap.open(D.CONTROLLER, held)
	assert_int(cap.read(_axis(JOY_AXIS_LEFT_Y, 0.05))).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.read(_axis(JOY_AXIS_LEFT_Y, 0.9))).is_equal(SlotCapture.Result.TAKEN)

func test_open_does_not_share_the_held_array() -> void:
	var held: Array[Vector2i] = [Vector2i(1, 1)]
	cap.open(D.CONTROLLER, held)
	cap.read(_axis(JOY_AXIS_LEFT_Y, 0.0))
	assert_array(held).has_size(1)

func test_taken_stick_is_drained() -> void:
	cap.open(D.CONTROLLER)
	cap.read(_axis(JOY_AXIS_LEFT_Y, 0.3))
	assert_bool(cap.swallows(_axis(JOY_AXIS_LEFT_X, 0.6))).is_false()
	assert_bool(cap.swallows(_axis(JOY_AXIS_LEFT_Y, 0.6, 1))).is_false()
	assert_bool(cap.swallows(_axis(JOY_AXIS_LEFT_Y, 0.6))).is_true()
	assert_bool(cap.swallows(_axis(JOY_AXIS_LEFT_Y, 0.1))).is_true()
	assert_bool(cap.swallows(_axis(JOY_AXIS_LEFT_Y, 0.6))).is_false()
	assert_bool(cap.swallows(_axis(JOY_AXIS_LEFT_X, 0.6))).is_false()
	assert_bool(cap.swallows(_axis(JOY_AXIS_LEFT_Y, 0.6, 1))).is_false()

func test_wrong_device_on_controller() -> void:
	cap.open(D.CONTROLLER)
	assert_int(cap.read(_key(KEY_ESCAPE))).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.read(_key(KEY_Q))).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.read(_click())).is_equal(SlotCapture.Result.WAITING)
	assert_bool(cap.is_open).is_true()

func test_close_stops_waiting() -> void:
	cap.open(D.CONTROLLER)
	cap.read(_button(JOY_BUTTON_B))
	cap.close()
	assert_int(cap.advance(2.0)).is_equal(SlotCapture.Result.WAITING)
	assert_int(cap.read(_button(JOY_BUTTON_Y))).is_equal(SlotCapture.Result.WAITING)
	assert_object(cap.taken).is_null()

func test_closed_capture_ignores_everything() -> void:
	assert_int(cap.read(_key(KEY_Q))).is_equal(SlotCapture.Result.WAITING)
	assert_object(cap.taken).is_null()

func test_no_pads_holds_nothing() -> void:
	assert_array(SlotCapture.held_axes_now()).is_empty()
