extends GdUnitTestSuite
## The Survival page in the shipwreck story: all four rows listed, and none of them does anything.

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
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_story_survival_page_lists_four_inert_rows() -> void:
	await _tap(KEY_ESCAPE)
	for i in 3:
		await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_Q)
	await _tap(KEY_Q)
	var panel := pause.get_node("%DebugPanel") as DebugPanel
	var rules := panel.rules
	assert_int(rules.page).is_equal(DebugMenu.Page.SURVIVAL)
	assert_bool(rules.in_story).is_true()
	assert_array(rules.rows_of(DebugMenu.Page.SURVIVAL).map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Place lean-to", "Place fire", "Remove builds", "Collapse now"])
	for i in 4:
		if i > 0:
			await _tap(KEY_DOWN)
		await _tap(KEY_ENTER)
		assert_bool(get_tree().paused).is_true()
		assert_bool(panel.visible).is_true()
		assert_int(panel.shaking_row).is_equal(-1)
