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
	InputDevice.set_menu_open(self, false)
	InputDevice.reset()
	_stick(JOY_AXIS_LEFT_X, 0.0)
	_stick(JOY_AXIS_LEFT_Y, 0.0)
	InputDevice.reset()

func _stick(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	return e

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

func test_menu_step_is_worked_out_before_handlers() -> void:
	var e := _stick(JOY_AXIS_LEFT_Y, 1.0)
	assert_int(InputDevice.menu_step(e)).is_equal(MenuPush.Step.DOWN)
	assert_int(InputDevice.menu_step(e)).is_equal(MenuPush.Step.DOWN)

func test_menu_step_held_stick_is_one_push() -> void:
	_stick(JOY_AXIS_LEFT_Y, 1.0)
	var e := _stick(JOY_AXIS_LEFT_Y, 0.9)
	assert_int(InputDevice.menu_step(e)).is_equal(MenuPush.Step.NONE)

func test_reset_rearms_the_stick() -> void:
	_stick(JOY_AXIS_LEFT_Y, 1.0)
	InputDevice.reset()
	var e := _stick(JOY_AXIS_LEFT_Y, 1.0)
	assert_int(InputDevice.menu_step(e)).is_equal(MenuPush.Step.DOWN)

# A mouse movement through the window, so InputDevice sees it.
func _mouse_moved() -> void:
	var move := InputEventMouseMotion.new()
	move.position = Vector2(4, 4)
	move.relative = Vector2(2, 0)
	Input.parse_input_event(move)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func test_key_through_the_window_hides_the_pointer_in_a_menu() -> void:
	InputDevice.set_menu_open(self, true)
	runner.simulate_key_pressed(KEY_E)
	await runner.await_input_processed()
	assert_bool(InputDevice.pointer.hidden).is_true()

func test_mouse_move_through_the_window_shows_it() -> void:
	InputDevice.set_menu_open(self, true)
	runner.simulate_key_pressed(KEY_E)
	await runner.await_input_processed()
	await _mouse_moved()
	assert_bool(InputDevice.pointer.hidden).is_false()

func test_no_menu_no_hiding() -> void:
	runner.simulate_key_pressed(KEY_E)
	await runner.await_input_processed()
	assert_bool(InputDevice.pointer.hidden).is_false()

func test_reset_forgets_the_device_but_keeps_menus() -> void:
	InputDevice.set_menu_open(self, true)
	runner.simulate_key_pressed(KEY_E)
	await runner.await_input_processed()
	assert_bool(InputDevice.pointer.hidden).is_true()
	InputDevice.reset()
	assert_bool(InputDevice.pointer.hidden).is_false()
	_pad(JOY_BUTTON_A, true)
	_pad(JOY_BUTTON_A, false)
	assert_bool(InputDevice.pointer.hidden).is_true()

func test_a_controls_change_tells_the_hints() -> void:
	InputDevice.use_controls(Controls.new())
	monitor_signals(InputDevice, false)
	InputDevice.controls.clear_slot(Controls.Action.USE, Controls.Device.KEYBOARD, 0)
	await assert_signal(InputDevice).is_emitted("changed")
	InputDevice.use_controls(Controls.new())

func test_the_gate_run_starts_at_defaults() -> void:
	assert_str(InputDevice.controls.path).is_equal("")
