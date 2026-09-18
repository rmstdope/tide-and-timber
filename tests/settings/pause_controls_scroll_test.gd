extends GdUnitTestSuite
## The Controls page opened from pause when its content is taller than the screen above the lifted strip.
## Reached the player's way on the default 1280x720 window (k = 2) at 640x360 (tr-1o0.1): "largest" is UI
## Largest and Text Largest, the only combination at which the Reset row reads on through the lines under the
## list; "large" is UI Normal and Text Large, the smallest at which the page stacks and scrolls.

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
	get_tree().root.size = Vector2i(1280, 720)
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

func _text(steps: int) -> void:
	for i in absi(steps):
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, signi(steps))

# UI Largest and Text Largest.
func _largest() -> void:
	_size(2)
	_text(2)

# The view the page's band gives: the band less a mark row at each end.
func _band_view() -> Rect2:
	var b := ScrollWindow.band(page.get_global_transform_with_canvas(), page.strip.screen_top())
	return Rect2(0, b.x + ScrollWindow.MARK_ROW, Screen.WIDTH, b.y - b.x - 2.0 * ScrollWindow.MARK_ROW)

# Row r's rectangle where it is drawn now.
func _drawn(r: int) -> Rect2:
	var rect := page.layout.row_rect(r)
	return Rect2(page.to_page(rect.position), rect.size)

func test_largest_pause_page_stays_above_the_lifted_strip() -> void:
	_largest()
	await _open_page()
	assert_bool(page.scrolls).is_true()
	assert_that(page.view).is_equal(_band_view())
	assert_int(page.offset).is_equal(0)   # the heading, the tabs and row 0 fit the view from the top
	assert_bool(page.shows_mark_above()).is_false()
	assert_bool(page.shows_mark_below()).is_true()
	var t := page.get_global_transform_with_canvas()
	assert_float((t * Vector2(0, page.view.position.y - ScrollWindow.MARK_ROW)).y).is_equal(ScrollWindow.EDGE)
	assert_float((t * Vector2(0, page.view.end.y + ScrollWindow.MARK_ROW)).y).is_equal(page.strip.screen_top() - ScrollWindow.EDGE)
	assert_bool(page.view.encloses(_drawn(0))).is_true()

func test_largest_pause_page_scrolls_down_and_back() -> void:
	_largest()
	await _open_page()
	assert_bool(page.scrolls).is_true()
	# Row 1's bottom is 4 below the 113-unit view; each further row is one stacked row (38) lower.
	for expected: int in [4, 42, 80, 118]:
		await _tap(KEY_DOWN)
		assert_int(page.offset).is_equal(expected)
		assert_bool(page.view.encloses(_drawn(page.rules.row))).is_true()
	await _tap(KEY_UP)
	assert_int(page.rules.row).is_equal(3)
	assert_int(page.offset).is_equal(118)   # row 3 is still wholly in the 113-unit view, so the page does not move
	assert_bool(page.view.encloses(_drawn(page.rules.row))).is_true()

func test_normal_pause_page_does_not_scroll() -> void:
	await _open_page()
	assert_bool(page.scrolls).is_false()
	assert_that(page.view).is_equal(Rect2(Vector2.ZERO, Screen.SIZE))

func test_a_box_does_not_move_the_scrolled_page() -> void:
	_largest()
	await _open_page()
	assert_bool(page.scrolls).is_true()
	await _tap(KEY_UP)   # the Reset row, at the bottom of the content
	var scrolled := page.offset
	assert_int(scrolled).is_equal(ControlsPage.reset_span(page.layout, page.view.size.y).x)
	assert_int(scrolled).is_greater(0)
	await _tap(KEY_ENTER)
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.RESET)
	assert_int(page.offset).is_equal(scrolled)   # the box is a child node; the page under it does not move
	assert_that(page.view).is_equal(_band_view())
	await _tap(KEY_ESCAPE)
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.NONE)
	assert_int(page.offset).is_equal(scrolled)

func test_large_pause_page_scrolls_inside_its_band() -> void:
	_text(1)
	await _open_page()
	assert_bool(page.stacked).is_true()
	assert_bool(page.scrolls).is_true()
	# The view is the band less one mark row at each end: on screen, 2 from the top of the screen
	# and 2 above the strip, both inset by a mark row at this scale.
	var t := page.get_global_transform_with_canvas()
	var scale := t.get_scale().y
	var top_on_screen := (t * Vector2(0, page.view.position.y)).y
	var bottom_on_screen := (t * Vector2(0, page.view.end.y)).y
	assert_float(top_on_screen).is_equal_approx(2.0 + ScrollWindow.MARK_ROW * scale, 1.0 + scale)
	assert_float(bottom_on_screen).is_equal_approx(
			page.strip.screen_top() - 2.0 - ScrollWindow.MARK_ROW * scale, 1.0 + scale)
	assert_bool(page.view.encloses(_drawn(page.rules.row))).is_true()

func test_largest_pause_reads_the_bottom_in_more_pushes() -> void:
	_largest()
	await _open_page()
	await _tap(KEY_UP)
	var span := ControlsPage.reset_span(page.layout, page.view.size.y)
	assert_bool(span.x < span.y).is_true()   # there is more under the Reset row than the view shows
	assert_int(page.offset).is_equal(span.x)
	var expected := span.x
	while expected < span.y:
		expected = mini(expected + int(page.layout.line_step()), span.y)   # one line a push, stopping at the bottom
		await _tap(KEY_DOWN)
		assert_int(page.rules.row).is_equal(8)
		assert_int(page.offset).is_equal(expected)
	assert_bool(page.shows_mark_below()).is_false()
	await _tap(KEY_DOWN)
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.offset).is_equal(0)   # row 0's place from pause, as on opening
