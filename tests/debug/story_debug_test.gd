extends GdUnitTestSuite
## The Debug plank and panel on the shipwreck story's pause board: five planks, and four pages dimmed.

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

func _node(unique: String) -> Node:
	return pause.get_node("%" + unique)

func _tap(key: Key = KEY_SPACE) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_story_board_has_debug_fourth_of_five() -> void:
	await _tap(KEY_ESCAPE)
	var names := ["Resume", "SkipStory", "Settings", "Debug", "QuitToTitle"]
	var board := _node("Panel") as Control
	for i in names.size():
		var plank := _node(names[i]) as Control
		assert_bool(plank.visible).is_true()
		assert_float(plank.position.y + plank.size.y).is_less_equal(board.size.y)
		if i > 0:
			assert_float((_node(names[i - 1]) as Control).position.y).is_less(plank.position.y)
	assert_float(board.position.y + board.size.y).is_less_equal(180.0)

func test_story_panel_dims_time_items_place_surv() -> void:
	var called: Array[String] = []
	var menu := pause.debug_menu()
	for page: DebugMenu.Page in [DebugMenu.Page.PLACE, DebugMenu.Page.STORY]:
		for i in 2:
			menu.add_row(page, DebugRow.new("R", Callable(), func(_d: int) -> void: called.append("step"),
					func() -> DebugRow.Result: called.append("select %d" % page); return DebugRow.Result.DONE))
	await _tap(KEY_ESCAPE)
	for i in 3:
		await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	var panel := _node("DebugPanel") as DebugPanel
	assert_bool(panel.visible).is_true()
	assert_bool(panel.rules.in_story).is_true()
	panel.rules.set_page(DebugMenu.Page.PLACE)
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_array(called).is_empty()
	await _tap(KEY_DOWN)
	assert_int(panel.rules.highlighted).is_equal(1)
	await _tap(KEY_E)
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.STORY)
	await _tap(KEY_ENTER)
	assert_array(called).is_equal(["select %d" % DebugMenu.Page.STORY])
