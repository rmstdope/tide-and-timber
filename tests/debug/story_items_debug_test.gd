extends GdUnitTestSuite
## The Debug panel's Items page during the shipwreck story: every item at 0, inert.

const SCENE := "res://src/intro/intro.tscn"

var runner: GdUnitSceneRunner
var intro: Intro
var pause: Pause

func before_test() -> void:
	Pause.debug_tools = true
	runner = scene_runner(SCENE)
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

func test_story_items_page_lists_every_item_at_zero_and_ignores_right() -> void:
	await _tap(KEY_ESCAPE)
	for i in 3:
		await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_E)
	var panel := pause.get_node("%DebugPanel") as DebugPanel
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.ITEMS)
	assert_bool(panel.rules.in_story).is_true()
	var rows := panel.rules.rows_of(DebugMenu.Page.ITEMS)
	assert_array(rows.map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Driftwood", "Shellfish", "Coconut", "Empty shell", "Fresh water", "Empty his bag"])
	for i in Item.Kind.size():
		assert_str(rows[i].value_text()).is_equal("0")
	await _tap(KEY_RIGHT)
	assert_str(rows[0].value_text()).is_equal("0")
