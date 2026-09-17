extends GdUnitTestSuite
## F1-F4 on the beach in a debug build.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var builder: Builder
var line: DebugKeyLine
var dn: DayNight

func before_test() -> void:
	Pause.debug_tools = true
	InputDevice.reset()
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	builder = waking.get_node("%Beach").get_node("%Builder")
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK
	line = waking.get_node("DebugKeyLayer/KeyLine") as DebugKeyLine
	line.set_process(false)
	dn = waking.get_node("%DayNight") as DayNight

func after_test() -> void:
	DebugSwitches.readout = false
	DebugSwitches.collision_areas = false
	DebugSwitches.use_areas = false
	DebugSwitches.walk_through = false
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _control() -> void:
	waking.tick(5.0)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _key(code: Key, echo := false) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		e.echo = echo and pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func _pad(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = button
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func test_f1_turns_the_readout_on_with_its_line() -> void:
	_control()
	await _key(KEY_F1)
	assert_bool(DebugSwitches.readout).is_true()
	assert_str(line.text).is_equal("Readout on")
	assert_bool(line.visible).is_true()
	await _key(KEY_F1)
	assert_bool(DebugSwitches.readout).is_false()
	assert_str(line.text).is_equal("Readout off")

func test_f2_turns_collision_areas_on() -> void:
	await _key(KEY_F2)
	assert_bool(DebugSwitches.collision_areas).is_true()
	assert_str(line.text).is_equal("Collision areas on")

func test_f3_cycles_speed_and_wraps() -> void:
	for i in 5:
		await _key(KEY_F3)
	assert_float(dn.time_scale).is_equal(32.0)
	assert_str(line.text).is_equal("Speed x32")
	await _key(KEY_F3)
	assert_float(dn.time_scale).is_equal(1.0)
	assert_str(line.text).is_equal("Speed x1")

func test_f3_speed_shows_on_the_time_page() -> void:
	await _key(KEY_F3)
	await _key(KEY_F3)
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	var rules := (pause.get_node("%DebugPanel") as DebugPanel).rules
	assert_str(rules.rows_of(DebugMenu.Page.TIME)[2].value_text()).is_equal("x4")

func test_f4_turns_walk_through_on() -> void:
	await _key(KEY_F4)
	assert_bool(DebugSwitches.walk_through).is_true()
	assert_str(line.text).is_equal("Walk through things on")

func test_keys_work_before_he_has_control() -> void:
	await _key(KEY_F1)
	assert_bool(DebugSwitches.readout).is_true()

func test_held_key_repeat_does_nothing() -> void:
	await _key(KEY_F3)
	await _key(KEY_F3, true)
	assert_float(dn.time_scale).is_equal(2.0)

func test_keys_do_nothing_while_paused() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_true()
	await _key(KEY_F1)
	await _key(KEY_F3)
	await _key(KEY_F4)
	assert_bool(DebugSwitches.readout).is_false()
	assert_bool(DebugSwitches.walk_through).is_false()
	assert_float(dn.time_scale).is_equal(1.0)
	assert_str(line.text).is_equal("")

func test_pad_buttons_do_nothing() -> void:
	for b: JoyButton in [JOY_BUTTON_BACK, JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK, JOY_BUTTON_MISC1]:
		await _pad(b)
	assert_bool(DebugSwitches.readout).is_false()
	assert_bool(DebugSwitches.collision_areas).is_false()
	assert_bool(DebugSwitches.use_areas).is_false()
	assert_bool(DebugSwitches.walk_through).is_false()
	assert_float(dn.time_scale).is_equal(1.0)
	assert_str(line.text).is_equal("")

func test_a_bound_key_still_does_its_action() -> void:
	var c := Controls.new()
	var f1 := InputEventKey.new()
	f1.physical_keycode = KEY_F1
	c.set_slot(Controls.Action.BUILD_LIST, Controls.Device.KEYBOARD, 0, f1)
	InputDevice.use_controls(c)
	_control()
	await _key(KEY_F1)
	assert_bool(DebugSwitches.readout).is_true()
	assert_int(builder.mode).is_equal(Builder.Mode.LIST)

func test_line_layer_is_under_the_pause_layer() -> void:
	assert_int((waking.get_node("DebugKeyLayer") as CanvasLayer).layer).is_less((pause as CanvasLayer).layer)
