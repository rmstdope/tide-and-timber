extends GdUnitTestSuite
## The Show page in the shipwreck story: the readout shows only FPS, and there are no outlines.

var runner: GdUnitSceneRunner
var intro: Intro
var pause: Pause

func before_test() -> void:
	Pause.debug_tools = true
	runner = scene_runner("res://src/intro/intro.tscn")
	intro = runner.scene() as Intro
	intro.end_story = func() -> void: pass
	pause = intro.get_node("%Pause")

func after_test() -> void:
	get_tree().paused = false
	Pause.debug_tools = OS.is_debug_build()
	DebugSwitches.readout = false
	DebugSwitches.collision_areas = false
	DebugSwitches.use_areas = false
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _open_show() -> DebugMenu:
	await _tap(KEY_ESCAPE)
	for i in 3:
		await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_Q)
	return (pause.get_node("%DebugPanel") as DebugPanel).rules

func test_story_show_page_turns_readout_on_with_fps_only() -> void:
	var rules: DebugMenu = await _open_show()
	assert_int(rules.page).is_equal(DebugMenu.Page.SHOW)
	assert_bool(rules.in_story).is_true()
	await _tap(KEY_RIGHT)
	assert_bool(DebugSwitches.readout).is_true()
	var ls: Array[String] = (intro.get_node("DebugReadoutLayer/Readout") as DebugReadout).lines()
	assert_int(ls.size()).is_equal(1)
	assert_str(ls[0]).starts_with("FPS ")

func test_story_has_no_outline_layer() -> void:
	assert_object(intro.get_node_or_null("DebugOutlineLayer")).is_null()
	await _open_show()
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	assert_bool(DebugSwitches.collision_areas).is_true()
	await runner.simulate_frames(2)
