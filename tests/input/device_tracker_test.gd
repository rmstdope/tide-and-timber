extends GdUnitTestSuite
## Which device the hints follow: the rules, with no nodes.

const K := DeviceTracker.Kind
const XBOX_NAME := "Xbox Series Controller"
const PS_NAME := "PS4 Controller"

func _names(names: Array) -> PackedStringArray:
	return PackedStringArray(names)

func _key(pressed: bool = true, echo: bool = false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = KEY_E
	e.physical_keycode = KEY_E
	e.pressed = pressed
	e.echo = echo
	return e

func _button(device: int = 0, button: JoyButton = JOY_BUTTON_A) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.device = device
	e.button_index = button
	e.pressed = true
	return e

func _axis(value: float, axis: JoyAxis = JOY_AXIS_LEFT_X) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e

func test_starts_on_keys_without_pads() -> void:
	assert_int(DeviceTracker.new().kind).is_equal(K.KEYBOARD)

func test_starts_on_the_first_connected_pad() -> void:
	assert_int(DeviceTracker.new(_names(["PS5 Controller"])).kind).is_equal(K.PLAYSTATION)

func test_family_of_names() -> void:
	assert_int(DeviceTracker.family_of("Xbox Series Controller")).is_equal(K.XBOX)
	assert_int(DeviceTracker.family_of("PS4 Controller")).is_equal(K.PLAYSTATION)
	assert_int(DeviceTracker.family_of("DualSense Wireless Controller")).is_equal(K.PLAYSTATION)
	assert_int(DeviceTracker.family_of("Nintendo Switch Pro Controller")).is_equal(K.NINTENDO)
	assert_int(DeviceTracker.family_of("Joy-Con (L/R)")).is_equal(K.NINTENDO)
	assert_int(DeviceTracker.family_of("8BitDo Generic")).is_equal(K.XBOX)
	assert_int(DeviceTracker.family_of("")).is_equal(K.XBOX)

func test_key_press_switches_to_keys() -> void:
	var tracker := DeviceTracker.new(_names([XBOX_NAME]))
	monitor_signals(tracker, false)
	tracker.observe(_key())
	assert_int(tracker.kind).is_equal(K.KEYBOARD)
	await assert_signal(tracker).is_emitted("changed")

func test_key_release_and_echo_do_not_switch() -> void:
	var tracker := DeviceTracker.new(_names([XBOX_NAME]))
	tracker.observe(_key(false))
	tracker.observe(_key(true, true))
	assert_int(tracker.kind).is_equal(K.XBOX)

func test_click_switches_to_keys_and_mouse_motion_does_not() -> void:
	var tracker := DeviceTracker.new(_names([XBOX_NAME]))
	tracker.observe(InputEventMouseMotion.new())
	assert_int(tracker.kind).is_equal(K.XBOX)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	tracker.observe(click)
	assert_int(tracker.kind).is_equal(K.KEYBOARD)

func test_any_pad_button_switches_to_that_family() -> void:
	var tracker := DeviceTracker.new()
	tracker.observe(_button(0, JOY_BUTTON_X), PS_NAME)
	assert_int(tracker.kind).is_equal(K.PLAYSTATION)

func test_stick_inside_dead_zone_does_not_switch() -> void:
	var tracker := DeviceTracker.new()
	tracker.observe(_axis(0.19), XBOX_NAME)
	assert_int(tracker.kind).is_equal(K.KEYBOARD)
	tracker.observe(_axis(0.2), XBOX_NAME)
	assert_int(tracker.kind).is_equal(K.XBOX)
	var other := DeviceTracker.new()
	other.observe(_axis(-0.5, JOY_AXIS_TRIGGER_LEFT), XBOX_NAME)
	assert_int(other.kind).is_equal(K.XBOX)

func test_dead_zone_matches_walking() -> void:
	assert_float(DeviceTracker.DEAD_ZONE).is_equal_approx(InputMap.action_get_deadzone(&"move_left"), 0.0001)

func test_last_pressed_of_two_pads_wins() -> void:
	var tracker := DeviceTracker.new()
	tracker.observe(_button(0), XBOX_NAME)
	tracker.observe(_button(1), PS_NAME)
	assert_int(tracker.kind).is_equal(K.PLAYSTATION)
	tracker.observe(_button(0), XBOX_NAME)
	assert_int(tracker.kind).is_equal(K.XBOX)

func test_no_signal_when_kind_unchanged() -> void:
	var tracker := DeviceTracker.new()
	monitor_signals(tracker, false)
	tracker.observe(_key())
	tracker.observe(_key())
	await assert_signal(tracker).wait_until(50).is_not_emitted("changed")

func test_last_pad_unplugged_goes_to_keys() -> void:
	var tracker := DeviceTracker.new(_names([XBOX_NAME]))
	tracker.pad_disconnected(0, _names([]))
	assert_int(tracker.kind).is_equal(K.KEYBOARD)

func test_reconnect_after_unplug_stays_on_keys() -> void:
	var tracker := DeviceTracker.new(_names([XBOX_NAME]))
	tracker.pad_disconnected(0, _names([]))
	tracker.pad_connected(0, XBOX_NAME)
	assert_int(tracker.kind).is_equal(K.KEYBOARD)

func test_connect_before_any_press_shows_the_pad() -> void:
	var tracker := DeviceTracker.new()
	tracker.pad_connected(0, "PS5 Controller")
	assert_int(tracker.kind).is_equal(K.PLAYSTATION)

func test_connect_after_a_key_press_stays_on_keys() -> void:
	var tracker := DeviceTracker.new()
	tracker.observe(_key())
	tracker.pad_connected(0, "PS5 Controller")
	assert_int(tracker.kind).is_equal(K.KEYBOARD)

func test_unplugging_the_pressed_pad_with_another_left_shows_the_other() -> void:
	var tracker := DeviceTracker.new()
	tracker.observe(_button(1), PS_NAME)
	tracker.pad_disconnected(1, _names([XBOX_NAME]))
	assert_int(tracker.kind).is_equal(K.XBOX)

func test_unplugging_another_pad_keeps_the_pressed_one() -> void:
	var tracker := DeviceTracker.new()
	tracker.observe(_button(1), PS_NAME)
	tracker.pad_disconnected(0, _names([PS_NAME]))
	assert_int(tracker.kind).is_equal(K.PLAYSTATION)
