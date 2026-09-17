extends GdUnitTestSuite
## The pause board and its quit box on a pad: one step per push, B goes back.

const P := PauseMenu.Plank

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause

func before_test() -> void:
	InputDevice.reset()
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	pause.quit_to_title = func() -> void: pass
	pause.open_settings = func() -> void: pass
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK
	waking.tick(5.0)
	await _tap(JOY_BUTTON_START)

func after_test() -> void:
	get_tree().paused = false
	InputDevice.reset()
	_send_stick(JOY_AXIS_RIGHT_Y, 0.0)
	InputDevice.use_controls(Controls.new())
	_send_stick(JOY_AXIS_LEFT_X, 0.0)
	_send_stick(JOY_AXIS_LEFT_Y, 0.0)
	InputDevice.reset()

func _send_stick(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _stick(axis: JoyAxis, value: float) -> void:
	_send_stick(axis, value)
	await runner.await_input_processed()

func _tap(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = button
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func test_board_is_open() -> void:
	assert_bool(pause.rules.is_open).is_true()

func test_held_stick_moves_one_plank() -> void:
	await _stick(JOY_AXIS_LEFT_Y, 0.6)
	await _stick(JOY_AXIS_LEFT_Y, 1.0)
	assert_int(pause.rules.highlighted).is_equal(pause.rules.items[1])

func test_d_pad_up_wraps() -> void:
	await _tap(JOY_BUTTON_DPAD_UP)
	assert_int(pause.rules.highlighted).is_equal(pause.rules.items[-1])

func test_b_resumes() -> void:
	await _tap(JOY_BUTTON_B)
	assert_bool(pause.rules.is_open).is_false()
	assert_bool(get_tree().paused).is_false()

func test_stick_in_the_quit_box_stops_at_the_ends() -> void:
	await _tap(JOY_BUTTON_DPAD_UP)
	assert_int(pause.rules.highlighted).is_equal(P.QUIT_TO_TITLE)
	await _tap(JOY_BUTTON_A)
	assert_bool(pause.rules.box_open).is_true()
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	await _stick(JOY_AXIS_LEFT_X, -1.0)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.STAY)
	await _tap(JOY_BUTTON_B)
	assert_bool(pause.rules.box_open).is_false()

func test_pause_on_a_stick_toggles_once_per_push() -> void:
	await _tap(JOY_BUTTON_B)
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_RIGHT_Y
	m.axis_value = -1.0
	InputDevice.controls.set_slot(Controls.Action.PAUSE, Controls.Device.CONTROLLER, 0, m)
	await _stick(JOY_AXIS_RIGHT_Y, -0.9)
	assert_bool(get_tree().paused).is_true()
	await _stick(JOY_AXIS_RIGHT_Y, -1.0)
	assert_bool(get_tree().paused).is_true()
	await _stick(JOY_AXIS_RIGHT_Y, 0.9)
	assert_bool(get_tree().paused).is_true()
	await _stick(JOY_AXIS_RIGHT_Y, 0.0)
	await _stick(JOY_AXIS_RIGHT_Y, -0.9)
	assert_bool(get_tree().paused).is_false()
