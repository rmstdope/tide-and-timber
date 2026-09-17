extends GdUnitTestSuite
## The Place page in the shipwreck story: all six rows listed, and none of them does anything.

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
	DebugSwitches.walk_through = false
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_story_place_page_lists_rows_and_ignores_them() -> void:
	await _tap(KEY_ESCAPE)
	for i in 3:
		await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_E)
	await _tap(KEY_E)
	var rules := (pause.get_node("%DebugPanel") as DebugPanel).rules
	assert_int(rules.page).is_equal(DebugMenu.Page.PLACE)
	assert_bool(rules.in_story).is_true()
	var rows := rules.rows_of(DebugMenu.Page.PLACE)
	assert_array(rows.map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Walk through things", "Where he woke", "Wreck", "Beach", "Spring", "Camp"])
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_bool(DebugSwitches.walk_through).is_false()
	for i in range(1, 6):
		assert_bool(rows[i].select.is_valid()).is_false()
