extends GdUnitTestSuite
## The InputDevice autoload sees every event at the root window, even ones a handler consumes.

const K := DeviceTracker.Kind

var runner: GdUnitSceneRunner
var beach: Beach

func before_test() -> void:
	InputDevice.reset()
	runner = scene_runner("res://src/beach/beach.tscn")
	beach = runner.scene() as Beach

func after_test() -> void:
	InputDevice.reset()

func _pad(button: JoyButton, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 7
	e.button_index = button
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func test_a_key_press_through_the_window_counts() -> void:
	InputDevice.reset(PackedStringArray(["Xbox Series Controller"]))
	runner.simulate_key_pressed(KEY_E)
	await runner.await_input_processed()
	assert_int(InputDevice.kind()).is_equal(K.KEYBOARD)

func test_a_pad_press_through_the_window_counts() -> void:
	_pad(JOY_BUTTON_BACK, true)
	_pad(JOY_BUTTON_BACK, false)
	assert_int(InputDevice.kind()).is_equal(K.XBOX)

func test_mouse_motion_through_the_window_does_not_count() -> void:
	InputDevice.reset(PackedStringArray(["Xbox Series Controller"]))
	runner.simulate_mouse_move(Vector2(40, 40))
	await runner.await_input_processed()
	assert_int(InputDevice.kind()).is_equal(K.XBOX)

func test_counts_even_during_the_build_fade() -> void:
	var builder := beach.get_node("%Builder") as Builder
	builder.set_process(false)
	builder.mode = Builder.Mode.BUILDING
	_pad(JOY_BUTTON_A, true)
	assert_int(InputDevice.kind()).is_equal(K.XBOX)
	_pad(JOY_BUTTON_A, false)
	builder.mode = Builder.Mode.CLOSED

func test_disconnect_signal_with_no_pads_goes_to_keys() -> void:
	InputDevice.reset(PackedStringArray(["Xbox Series Controller"]))
	Input.joy_connection_changed.emit(0, false)
	assert_int(InputDevice.kind()).is_equal(K.KEYBOARD)

func test_reset_emits_changed() -> void:
	monitor_signals(InputDevice, false)
	InputDevice.reset()
	await assert_signal(InputDevice).is_emitted("changed")
