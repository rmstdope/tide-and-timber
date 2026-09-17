extends GdUnitTestSuite
## A release build has no F1-F4.

var runner: GdUnitSceneRunner
var waking: Waking

func before_test() -> void:
	Pause.debug_tools = false
	InputDevice.reset()
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	DebugSwitches.readout = false
	DebugSwitches.collision_areas = false
	DebugSwitches.use_areas = false
	DebugSwitches.walk_through = false
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	InputDevice.reset()

func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func test_release_has_no_debug_keys() -> void:
	assert_object(waking.get_node_or_null("DebugKeyLayer")).is_null()
	for k: Key in [KEY_F1, KEY_F2, KEY_F3, KEY_F4]:
		await _key(k)
	assert_bool(DebugSwitches.readout).is_false()
	assert_bool(DebugSwitches.collision_areas).is_false()
	assert_bool(DebugSwitches.walk_through).is_false()
	assert_float((waking.get_node("%DayNight") as DayNight).time_scale).is_equal(1.0)
