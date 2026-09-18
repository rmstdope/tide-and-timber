extends GdUnitTestSuite
## A Paused board with a fourth plank (a debug build) scrolls the same way: its own suite, because
## Pause.debug_tools must be set before the scene is built, and a second scene in one test leaks an
## item bar that lifts other scenes' strips.
## Reached the player's way: the default 1280x720 window (k = 2) at UI Largest and Text Largest, the
## only combination at 640x360 whose four-plank board does not fit above the strip.

const S := DisplayPrefs.Setting

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Pause.debug_tools = true
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause") as Pause
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode

func _size(steps: int) -> void:
	for i in absi(steps):
		Display.prefs.step(S.UI_SIZE, signi(steps))

func _tap(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _node(unique: String) -> Control:
	return pause.get_node("%" + unique) as Control

func _screen(n: Control) -> Rect2:
	return n.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, n.size)

func _shown(unique: String) -> bool:
	return _screen(_node("Clip")).encloses(_screen(_node(unique)))

func _open() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await await_idle_frame()
	await await_idle_frame()

func test_a_four_plank_board_scrolls_to_its_last_plank() -> void:
	_size(2)
	Display.prefs.step(S.TEXT_SIZE, 2)
	await _open()
	assert_bool(pause.scrolls).override_failure_message("precondition: the board does not scroll").is_true()
	assert_int(pause.rules.items.size()).is_equal(4)
	# 236x156: four 212x24 planks at Text Largest, step 28, below a heading grown to 16, centred
	assert_that(pause.rest_panel).is_equal(Rect2(((Screen.SIZE - Vector2(236, 156)) / 2.0).floor(), Vector2(236, 156)))
	assert_int(pause.scroll_offset).is_equal(0)   # the first plank's extent reaches up to the content's top
	assert_bool(_shown("Resume")).is_true()
	for i in 3:
		await _tap(KEY_DOWN)
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.QUIT_TO_TITLE)
	# the last plank's extent runs to the content's end: the view sits flush with it
	assert_int(pause.scroll_offset).is_equal(int(pause.rest_panel.size.y - Pause.HEADING_TOP
			- Pause.BOTTOM_MARGIN - _node("Clip").size.y))
	assert_bool(_shown("QuitToTitle")).is_true()
	assert_bool(pause.shows_mark_above()).is_true()
	assert_bool(pause.shows_mark_below()).is_false()

func test_the_dev_tag_is_not_scrolled() -> void:
	await _open()
	assert_object(_node("DevTag").get_parent()).is_same(_node("Panel"))
	assert_bool(_node("Clip").is_ancestor_of(_node("DevTag"))).is_false()
