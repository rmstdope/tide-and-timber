extends GdUnitTestSuite
## The Controls page when its content is taller than the screen: it scrolls to the highlighted row, with ▲ / ▼.
## Reached the player's way on the default 1280x720 window (k = 2) at 640x360 (tr-1o0.1), where UI size alone
## never stacks the page: "largest" is UI Largest and Text Largest; "large" is UI Largest and Text Large, the
## smallest combination at which three pushes Down scroll the title's page.
## On the title, at every combination, the Reset row and the lines under the list fit the view together, so
## nothing reads on: the tests of reading on (controls-bottom c) assert that precondition first and stay red.
## The pause board's page does read on at UI Largest and Text Largest (pause_controls_scroll_test.gd).

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/controls_page_scroll_none"   # never created

var runner: GdUnitSceneRunner
var screen: TitleScreen
var board: SettingsBoard
var page: ControlsPage
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	board = screen.get_node("%SettingsBoard") as SettingsBoard
	page = board.get_node("%ControlsPage") as ControlsPage
	screen.quit_game = func() -> void: pass
	screen.start_new_game = func() -> void: pass
	screen.start_continue = func() -> void: pass
	screen.read_save(NO_SAVE)

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()

func _open_page() -> void:
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)
	await _press(KEY_UP)   # the board opens on UI size; Up wraps to Controls
	await _press(KEY_ENTER)

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

func _span() -> Vector2i:
	return ControlsPage.reset_span(page.layout, page.view.size.y)

# The offset that brings row r's extent's bottom to the view's bottom.
func _bottom_at(r: int) -> int:
	return ceili(page.layout.row_extent(r).y - page.view.size.y)

func _left_click(control: Control, at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	control.gui_input.emit(click)

func _motion(control: Control, at: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(1, 0)
	move.position = at
	control.gui_input.emit(move)

# Row r's rectangle where it is drawn now.
func _drawn(r: int) -> Rect2:
	var rect := page.layout.row_rect(r)
	return Rect2(page.to_page(rect.position), rect.size)

# Presses Down until the highlight leaves its row: on the Reset row Down first reads on to the page's bottom.
func _down_to_next_row() -> void:
	var from := page.rules.row
	for i in 10:
		await _press(KEY_DOWN)
		if page.rules.row != from:
			return
	fail("Down never left row %d" % from)

func _wheel(up: bool, times: int) -> void:
	for i in times:
		runner.simulate_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN)
		await runner.await_input_processed()

# --- pure ---

# UI 4: what UI Largest (2) was on the 320-wide picture; extents are from the content's top, so unchanged.
func test_content_bottom_and_row_extent() -> void:
	var stacked := ControlsLayout.make(true, 1.0, 4.0)
	assert_float(stacked.content_bottom()).is_equal(273.0 + ControlsPage.TOP_SHIFT)
	assert_float(ControlsLayout.make(false, 1.0, 1.0).content_bottom()).is_equal(ControlsPage.CONTENT_TOP + ControlsPage.CONTENT_H)
	assert_that(stacked.row_extent(0)).is_equal(Vector2(0, 47))
	assert_that(stacked.row_extent(1)).is_equal(Vector2(47, 69))
	assert_that(stacked.row_extent(8)).is_equal(Vector2(201, 270))
	assert_that(ControlsLayout.make(false, 1.0, 1.0).row_extent(3)).is_equal(Vector2(58, 69))

# --- title ---

func test_normal_title_page_does_not_scroll() -> void:
	await _open_page()
	await _settle()
	assert_bool(page.scrolls).is_false()
	assert_int(page.offset).is_equal(0)
	assert_that(page.view).is_equal(Rect2(Vector2.ZERO, Screen.SIZE))
	assert_bool(page.shows_mark_above()).is_false()
	assert_bool(page.shows_mark_below()).is_false()
	assert_that(page.to_page(Vector2(20, 30))).is_equal(Vector2(20, 30))

func test_largest_title_page_opens_at_the_top() -> void:
	_largest()
	await _open_page()
	await _settle()
	assert_bool(page.stacked).is_true()
	assert_bool(page.scrolls).is_true()
	assert_that(page.view).is_equal(_band_view())
	assert_int(page.offset).is_equal(0)
	assert_bool(page.shows_mark_above()).is_false()
	assert_bool(page.shows_mark_below()).is_true()
	assert_that(page.to_page(Vector2(0, ControlsPage.CONTENT_TOP))).is_equal(Vector2(0, page.view.position.y))
	assert_bool(page.view.encloses(_drawn(0))).is_true()

func test_moving_down_and_up_scrolls_to_the_highlight() -> void:
	_largest()
	await _open_page()
	await _settle()
	await _press(KEY_DOWN)
	assert_int(page.offset).is_equal(0)   # row 1 fits under the heading and tabs
	await _press(KEY_DOWN)
	assert_int(page.offset).is_equal(_bottom_at(2))
	assert_int(page.offset).is_greater(0)
	assert_bool(page.shows_mark_above()).is_true()
	assert_bool(page.shows_mark_below()).is_true()
	assert_bool(page.view.encloses(_drawn(2))).is_true()
	var scrolled := page.offset
	await _press(KEY_UP)
	assert_int(page.rules.row).is_equal(1)
	assert_int(page.offset).is_equal(scrolled)   # row 1 is still wholly visible
	await _press(KEY_UP)
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.offset).is_equal(0)
	assert_bool(page.shows_mark_above()).is_false()

func test_up_from_the_top_shows_the_reset_row() -> void:
	_largest()
	await _open_page()
	await _settle()
	await _press(KEY_UP)
	assert_int(page.rules.row).is_equal(8)
	assert_int(page.offset).is_equal(_span().x)
	assert_int(page.offset).is_greater(0)
	assert_bool(page.shows_mark_above()).is_true()
	assert_bool(page.view.encloses(_drawn(8))).is_true()

func test_every_row_is_drawn_inside_the_view() -> void:
	_largest()
	await _open_page()
	await _settle()
	assert_bool(page.scrolls).is_true()
	for r in ControlsMenu.ROWS:
		assert_int(page.rules.row).is_equal(r)
		assert_bool(page.view.encloses(_drawn(r))).is_true()
		await _down_to_next_row()
	assert_int(page.rules.row).is_equal(0)
	page.rules.switch_tab()
	page._refresh()
	assert_int(page.rules.device).is_equal(Controls.Device.CONTROLLER)
	for r in ControlsMenu.ROWS:
		assert_int(page.rules.row).is_equal(r)
		assert_bool(page.view.encloses(_drawn(r))).is_true()
		await _down_to_next_row()

func test_large_title_page_scrolls() -> void:
	_size(2)
	_text(1)
	await _open_page()
	await _settle()
	assert_bool(page.stacked).is_true()
	assert_bool(page.scrolls).is_true()
	assert_that(page.view).is_equal(_band_view())
	for i in 3:
		await _press(KEY_DOWN)
	assert_int(page.offset).is_equal(_bottom_at(3))
	assert_int(page.offset).is_greater(0)
	assert_bool(page.view.encloses(_drawn(3))).is_true()

func test_size_change_refollows_and_normal_stops_scrolling() -> void:
	_largest()
	await _open_page()
	await _settle()
	await _press(KEY_DOWN)
	await _press(KEY_DOWN)
	var scrolled := _bottom_at(2)
	assert_int(page.offset).is_equal(scrolled)
	assert_int(scrolled).is_greater(0)
	Display.use_prefs(DisplayPrefs.new())
	await _settle()
	assert_bool(page.scrolls).is_false()
	assert_int(page.offset).is_equal(0)
	assert_that(page.view).is_equal(Rect2(Vector2.ZERO, Screen.SIZE))
	assert_int(page.rules.row).is_equal(2)
	_largest()
	await _settle()
	assert_bool(page.scrolls).is_true()
	assert_int(page.offset).is_equal(scrolled)
	assert_bool(page.view.encloses(_drawn(2))).is_true()

func test_reopening_starts_at_the_top() -> void:
	_largest()
	await _open_page()
	await _settle()
	await _press(KEY_UP)
	assert_int(page.offset).is_equal(_span().x)
	assert_int(page.offset).is_greater(0)
	await _press(KEY_ESCAPE)
	await _press(KEY_ENTER)
	await _settle()
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.offset).is_equal(0)

# --- title: the pointer ---

func test_hover_lands_where_drawn() -> void:
	_largest()
	await _open_page()
	await _settle()
	await _press(KEY_DOWN)
	await _press(KEY_DOWN)
	var scrolled := page.offset
	assert_int(scrolled).is_greater(0)
	_motion(page, page.to_page(page.layout.slot_rect(1, 1).get_center()))
	assert_int(page.rules.row).is_equal(1)
	assert_int(page.rules.slot).is_equal(1)
	assert_int(page.offset).is_equal(scrolled)

func test_a_hidden_row_is_not_hovered() -> void:
	_largest()
	await _open_page()
	await _settle()
	assert_bool(page.scrolls).is_true()
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.offset).is_equal(0)
	# row 3's slot is drawn below the view
	var drawn := page.to_page(page.layout.slot_rect(3, 1).get_center())
	assert_bool(page.view.has_point(drawn)).is_false()
	_motion(page, drawn)
	assert_int(page.rules.row).is_equal(0)
	# row 4's unscrolled place is below the view too
	assert_bool(page.view.has_point(page.layout.slot_rect(4, 1).get_center())).is_false()
	_motion(page, page.layout.slot_rect(4, 1).get_center())
	assert_int(page.rules.row).is_equal(0)
	_motion(page, Vector2(Screen.CENTRE.x + 34, page.view.position.y - ScrollWindow.MARK_ROW / 2.0))   # the top mark row
	assert_int(page.rules.row).is_equal(0)

func test_clicks_land_where_drawn() -> void:
	_largest()
	await _open_page()
	await _settle()
	await _press(KEY_UP)
	assert_int(page.rules.row).is_equal(8)
	assert_int(page.offset).is_equal(_span().x)
	# The Controller tab's column, in the mark row above the view: outside the view, it hits nothing.
	_left_click(page, Vector2(page.layout.tab_rect(1).get_center().x, page.view.position.y - ScrollWindow.MARK_ROW / 2.0))
	assert_int(page.rules.device).is_equal(Controls.Device.KEYBOARD)
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.NONE)
	await _down_to_next_row()   # Down on Reset first reads on through anything under the list (controls-bottom c)
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.offset).is_equal(0)
	_left_click(page, page.to_page(page.layout.tab_rect(1).get_center()))
	assert_int(page.rules.device).is_equal(Controls.Device.CONTROLLER)
	await _press(KEY_UP)
	assert_int(page.offset).is_equal(_span().x)
	_left_click(page, page.to_page(page.layout.row_rect(8).get_center()))
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.RESET)

func test_an_unknown_band_leaves_the_page_unscrolled() -> void:
	# frame is public; with no strip to measure, _frame must not scroll against a band it does not know.
	_largest()
	await _open_page()
	await _settle()
	assert_bool(page.scrolls).is_true()
	var saved := page.strip
	page.strip = null   # the band cannot be measured
	page._frame()
	page.strip = saved
	assert_bool(page.scrolls).is_false()
	assert_int(page.offset).is_equal(0)
	assert_that(page.view).is_equal(Rect2(Vector2.ZERO, Screen.SIZE))

# --- the bottom of the page when it does not all fit (controls-bottom c) ---

# UI 4 and Text Largest at UI 2: what UI Largest and Text Largest at UI Normal were on the 320-wide picture.
# Spans are in content units, from the content's top, so unchanged.
func test_reset_span_and_read_on() -> void:
	assert_that(ControlsPage.reset_span(ControlsLayout.make(true, 1.0, 4.0), 54)).is_equal(Vector2i(201, 216))
	assert_that(ControlsPage.reset_span(ControlsLayout.make(true, 1.0, 4.0), 32)).is_equal(Vector2i(201, 238))
	assert_that(ControlsPage.reset_span(ControlsLayout.make(true, 2.0, 2.0), 100)).is_equal(Vector2i(345, 370))
	assert_that(ControlsPage.reset_span(ControlsLayout.make(true, 2.0, 2.0), 200)).is_equal(Vector2i(270, 270))
	assert_that(ControlsPage.reset_span(ControlsLayout.make(false, 1.0, 1.0), Screen.HEIGHT)).is_equal(Vector2i(0, 0))
	var s := Vector2i(201, 216)
	assert_int(ControlsPage.read_on(201, 1, 9, s)).is_equal(210)
	assert_int(ControlsPage.read_on(210, 1, 9, s)).is_equal(216)
	assert_int(ControlsPage.read_on(216, 1, 9, s)).is_equal(216)
	assert_int(ControlsPage.read_on(216, -1, 9, s)).is_equal(207)
	assert_int(ControlsPage.read_on(207, -1, 9, s)).is_equal(201)
	assert_int(ControlsPage.read_on(201, -1, 9, s)).is_equal(201)

# Opens the page at UI Largest and Text Largest and lands on the Reset row; asserts there is more to read.
func _land_on_reset() -> void:
	_largest()
	await _open_page()
	await _settle()
	await _press(KEY_UP)
	assert_int(page.rules.row).is_equal(8)
	assert_bool(_span().x < _span().y).is_true()   # precondition: the lines under the list do not fit with the row
	assert_int(page.offset).is_equal(_span().x)

func _step() -> int:
	return int(page.layout.line_step())

func test_down_on_reset_reads_to_the_bottom_then_wraps() -> void:
	await _land_on_reset()
	assert_bool(page.shows_mark_below()).is_true()
	var expected := _span().x
	while expected < _span().y:
		expected = mini(expected + _step(), _span().y)
		await _press(KEY_DOWN)
		assert_int(page.rules.row).is_equal(8)
		assert_int(page.offset).is_equal(expected)
		assert_bool(page.shows_mark_above()).is_true()
	assert_bool(page.shows_mark_below()).is_false()
	assert_bool(page.view.has_point(page.to_page(Vector2(Screen.CENTRE.x, page.layout.content_bottom() - 1)))).is_true()
	await _press(KEY_DOWN)
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.offset).is_equal(0)

func test_up_on_reset_reads_back_then_moves_to_pause() -> void:
	await _land_on_reset()
	while page.offset < _span().y:
		await _press(KEY_DOWN)
	var expected := _span().y
	while expected > _span().x:
		expected = maxi(expected - _step(), _span().x)
		await _press(KEY_UP)
		assert_int(page.rules.row).is_equal(8)
		assert_int(page.offset).is_equal(expected)
	assert_bool(page.view.encloses(_drawn(8))).is_true()
	await _press(KEY_UP)
	assert_int(page.rules.row).is_equal(7)
	assert_bool(page.view.encloses(_drawn(7))).is_true()

func test_wheel_reads_the_bottom_without_moving_the_highlight() -> void:
	_largest()
	await _open_page()
	await _settle()
	await _wheel(false, 1)
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.offset).is_equal(0)
	await _press(KEY_UP)
	assert_bool(_span().x < _span().y).is_true()   # precondition: there is more to read under the Reset row
	await _wheel(false, 30)
	assert_int(page.rules.row).is_equal(8)
	assert_int(page.offset).is_equal(_span().y)
	await _wheel(true, 30)
	assert_int(page.rules.row).is_equal(8)
	assert_int(page.offset).is_equal(_span().x)

func test_a_read_down_reset_row_is_pointed_at_where_drawn() -> void:
	await _land_on_reset()
	while page.offset < _span().y:
		await _press(KEY_DOWN)
	var bottom := page.offset
	var row := page.layout.row_rect(8)
	var above := Vector2(Screen.CENTRE.x, page.view.position.y - 1.0 - page.shift())   # scrolled above the view
	_left_click(page, page.to_page(above))
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.NONE)
	var shown := Vector2(Screen.CENTRE.x, maxf(row.position.y, above.y + 2.0))   # the row's part still drawn
	assert_bool(row.has_point(shown)).is_true()
	_motion(page, page.to_page(shown))
	assert_int(page.rules.row).is_equal(8)
	assert_int(page.offset).is_equal(bottom)
	_left_click(page, page.to_page(shown))
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.RESET)
	assert_int(page.offset).is_equal(bottom)

func test_tab_and_size_changes_keep_a_read_down_page_in_range() -> void:
	await _land_on_reset()
	while page.offset < _span().y:
		await _press(KEY_DOWN)
	page.rules.switch_tab()
	page._refresh()
	assert_int(page.rules.row).is_equal(8)
	assert_int(page.offset).is_equal(_span().y)
	Display.use_prefs(DisplayPrefs.new())
	await _settle()
	assert_bool(page.scrolls).is_false()
	assert_int(page.offset).is_equal(0)
	assert_int(page.rules.row).is_equal(8)
	_largest()
	await _settle()
	assert_int(page.rules.row).is_equal(8)
	assert_int(page.offset).is_equal(_span().x)
