extends GdUnitTestSuite
## The shipwreck story on a pad: A taps and holds, B does nothing, Start pauses, a lost pad pauses.

const SCENE := "res://src/intro/intro.tscn"
const P := IntroStory.Phase

var runner: GdUnitSceneRunner
var intro: Intro
var calls: Array[String] = []

func before_test() -> void:
	calls = []
	runner = scene_runner(SCENE)
	intro = runner.scene() as Intro
	var recorded := calls
	intro.end_story = func() -> void: recorded.append("end")

func after_test() -> void:
	get_tree().paused = false
	InputDevice.reset()
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _node(unique: String) -> Node:
	return intro.get_node("%" + unique)

func _board() -> Node:
	return _node("Pause").get_node("%Board")

func _pad(button: JoyButton, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = button
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func _tap(button: JoyButton) -> void:
	await _pad(button, true)
	await _pad(button, false)
	# a timer that runs through a pause: gdUnit4's await_millis stops with the paused tree
	await get_tree().create_timer(0.05, true).timeout

func _disconnect(connected: bool = false) -> void:
	Input.joy_connection_changed.emit(0, connected)
	await runner.await_input_processed()

func test_a_taps_to_the_next_panel() -> void:
	await _tap(JOY_BUTTON_A)
	assert_int(_node("Picture").picture).is_equal(1)
	assert_str(_node("Caption").text).is_equal("Then the storm found us.")

func test_holding_a_fills_the_ring_and_skips() -> void:
	await _pad(JOY_BUTTON_A, true)
	intro.tick(0.5)
	assert_float(_node("SkipRing").progress).is_between(0.5, 0.7)
	assert_array(calls).is_empty()
	intro.tick(0.6)
	assert_int(intro.story.phase).is_equal(P.SKIPPING)
	intro.tick(0.6)
	assert_array(calls).is_equal(["end"])
	await _pad(JOY_BUTTON_A, false)
	assert_int(_node("Picture").picture).is_equal(0)

func test_b_does_nothing() -> void:
	await _tap(JOY_BUTTON_B)
	assert_int(_node("Picture").picture).is_equal(0)
	assert_int(intro.story.phase).is_equal(P.PLAYING)
	assert_bool(_node("SkipHint").visible).is_false()

func test_start_pauses_and_a_resumes() -> void:
	await _tap(JOY_BUTTON_START)
	assert_bool(_board().visible).is_true()
	assert_int(intro.story.phase).is_equal(P.PAUSED)
	assert_bool(get_tree().paused).is_equal(true)
	await _tap(JOY_BUTTON_A)
	assert_bool(_board().visible).is_false()
	assert_int(intro.story.phase).is_equal(P.PLAYING)
	assert_bool(get_tree().paused).is_equal(false)

func test_b_resumes_the_board() -> void:
	await _tap(JOY_BUTTON_START)
	await _tap(JOY_BUTTON_B)
	assert_int(intro.story.phase).is_equal(P.PLAYING)
	assert_bool(get_tree().paused).is_false()

func test_start_again_resumes() -> void:
	await _tap(JOY_BUTTON_START)
	await _tap(JOY_BUTTON_START)
	assert_int(intro.story.phase).is_equal(P.PLAYING)
	assert_bool(get_tree().paused).is_equal(false)

func test_disconnect_pauses_the_story() -> void:
	await _disconnect()
	assert_int(intro.story.phase).is_equal(P.PAUSED)
	assert_bool(get_tree().paused).is_equal(true)
	assert_bool(_board().visible).is_true()

func test_disconnect_mid_hold_clears_the_ring() -> void:
	await _pad(JOY_BUTTON_A, true)
	intro.tick(0.5)
	await _disconnect()
	assert_float(_node("SkipRing").progress).is_equal(0.0)
	assert_bool(get_tree().paused).is_true()
	await _pad(JOY_BUTTON_A, false)

func test_disconnect_while_paused_stays_paused() -> void:
	await runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.await_input_processed()
	assert_int(intro.story.phase).is_equal(P.PAUSED)
	assert_bool(get_tree().paused).is_equal(true)
	await _disconnect()
	assert_int(intro.story.phase).is_equal(P.PAUSED)
	assert_bool(get_tree().paused).is_equal(true)

func test_connect_does_not_pause() -> void:
	await _disconnect(true)
	assert_int(intro.story.phase).is_equal(P.PLAYING)
	assert_bool(get_tree().paused).is_equal(false)

func test_a_released_while_space_held_keeps_the_hold() -> void:
	runner.simulate_key_press(KEY_SPACE)
	await runner.await_input_processed()
	intro.tick(0.3)
	await _pad(JOY_BUTTON_A, true)
	await _pad(JOY_BUTTON_A, false)
	intro.tick(0.3)
	assert_float(_node("SkipRing").progress).is_greater(0.4)
	runner.simulate_key_release(KEY_SPACE)
	await runner.await_input_processed()

func test_the_players_use_button_taps() -> void:
	var y := InputEventJoypadButton.new()
	y.button_index = JOY_BUTTON_Y
	InputDevice.controls.set_slot(Controls.Action.USE, Controls.Device.CONTROLLER, 0, y)
	await _tap(JOY_BUTTON_Y)
	assert_int(_node("Picture").picture).is_equal(1)
	await _tap(JOY_BUTTON_A)
	assert_int(_node("Picture").picture).is_equal(2)

func _stick(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func test_the_players_use_stick_holds_once() -> void:
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_RIGHT_Y
	m.axis_value = -1.0
	InputDevice.controls.set_slot(Controls.Action.USE, Controls.Device.CONTROLLER, 0, m)
	await _stick(JOY_AXIS_RIGHT_Y, -0.9)
	await _stick(JOY_AXIS_RIGHT_Y, -1.0)
	assert_int(intro.story.held_count).is_equal(1)
	await _stick(JOY_AXIS_RIGHT_Y, 0.9)
	assert_int(intro.story.held_count).is_equal(0)
	assert_int(_node("Picture").picture).is_equal(1)
