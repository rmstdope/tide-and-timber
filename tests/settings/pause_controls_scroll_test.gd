extends GdUnitTestSuite
## The Controls page opened from pause when its content is taller than the screen above the lifted strip.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var board: SettingsBoard
var page: ControlsPage
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(640, 360)
	Pause.debug_tools = false
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _scene() -> void:
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	board = pause.get_node("%SettingsBoard")
	page = board.get_node("%ControlsPage")
	page.change_slot = func() -> void: pass
	pause.quit_to_title = func() -> void: pass
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()

func _open_page() -> void:
	_scene()
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)
	await _settle()

func _size(steps: int) -> void:
	for i in absi(steps):
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, signi(steps))

# Row r's rectangle where it is drawn now.
func _drawn(r: int) -> Rect2:
	var rect := ControlsPage.row_rect(r, true)
	return Rect2(page.to_page(rect.position), rect.size)

func test_largest_pause_page_stays_above_the_lifted_strip() -> void:
	_size(2)
	await _open_page()
	assert_bool(page.scrolls).is_true()
	assert_float(page.strip.screen_top()).is_equal(108.0)
	assert_that(page.view).is_equal(Rect2(0, 56, 320, 32))
	assert_int(page.offset).is_equal(15)
	assert_bool(page.shows_mark_above()).is_true()
	assert_bool(page.shows_mark_below()).is_true()
	var t := page.get_global_transform_with_canvas()
	assert_float((t * Vector2(0, page.view.position.y - ScrollWindow.MARK_ROW)).y).is_equal(2.0)
	assert_float((t * Vector2(0, page.view.end.y + ScrollWindow.MARK_ROW)).y).is_equal(106.0)
	assert_bool(page.view.encloses(_drawn(0))).is_true()

func test_largest_pause_page_scrolls_down_and_back() -> void:
	_size(2)
	await _open_page()
	for expected: int in [37, 59, 81, 103]:
		await _tap(KEY_DOWN)
		assert_int(page.offset).is_equal(expected)
		assert_bool(page.view.encloses(_drawn(page.rules.row))).is_true()
	await _tap(KEY_UP)
	assert_int(page.offset).is_equal(91)

func test_normal_pause_page_does_not_scroll() -> void:
	await _open_page()
	assert_bool(page.scrolls).is_false()
	assert_that(page.view).is_equal(Rect2(0, 0, 320, 180))
