extends GdUnitTestSuite
## F1-F4 in the shipwreck story: F1 and F2 work, F3 and F4 do nothing.

var runner: GdUnitSceneRunner
var intro: Intro
var line: DebugKeyLine

func before_test() -> void:
	Pause.debug_tools = true
	runner = scene_runner("res://src/intro/intro.tscn")
	intro = runner.scene() as Intro
	intro.end_story = func() -> void: pass
	line = intro.get_node("DebugKeyLayer/KeyLine") as DebugKeyLine
	line.set_process(false)

func after_test() -> void:
	DebugSwitches.readout = false
	DebugSwitches.collision_areas = false
	DebugSwitches.use_areas = false
	DebugSwitches.walk_through = false
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func test_story_f1_flips_the_readout() -> void:
	await _key(KEY_F1)
	assert_bool(DebugSwitches.readout).is_true()
	assert_str(line.text).is_equal("Readout on")

func test_story_f2_flips_collision_areas() -> void:
	await _key(KEY_F2)
	assert_bool(DebugSwitches.collision_areas).is_true()
	assert_str(line.text).is_equal("Collision areas on")

func test_story_f3_and_f4_do_nothing() -> void:
	await _key(KEY_F3)
	await _key(KEY_F4)
	assert_bool(DebugSwitches.walk_through).is_false()
	assert_str(line.text).is_equal("")
	assert_bool(line.visible).is_false()
