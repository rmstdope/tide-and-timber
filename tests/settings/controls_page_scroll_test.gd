extends GdUnitTestSuite
## The Controls page when its content is taller than the screen: it scrolls to the highlighted row, with ▲ / ▼.

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
	get_tree().root.size = Vector2i(640, 360)
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
	var rect := ControlsPage.row_rect(r, true)
	return Rect2(page.to_page(rect.position), rect.size)

# --- pure ---

func test_content_bottom_and_row_extent() -> void:
	assert_float(ControlsPage.content_bottom(true)).is_equal(255.0)
	assert_float(ControlsPage.content_bottom()).is_equal(156.0)
	assert_that(ControlsPage.row_extent(0, true)).is_equal(Vector2(0, 47))
	assert_that(ControlsPage.row_extent(1, true)).is_equal(Vector2(47, 69))
	assert_that(ControlsPage.row_extent(8, true)).is_equal(Vector2(201, 252))
	assert_that(ControlsPage.row_extent(3)).is_equal(Vector2(58, 69))

# --- title ---

func test_normal_title_page_does_not_scroll() -> void:
	await _open_page()
	await _settle()
	assert_bool(page.scrolls).is_false()
	assert_int(page.offset).is_equal(0)
	assert_that(page.view).is_equal(Rect2(0, 0, 320, 180))
	assert_bool(page.shows_mark_above()).is_false()
	assert_bool(page.shows_mark_below()).is_false()
	assert_that(page.to_page(Vector2(20, 30))).is_equal(Vector2(20, 30))

func test_largest_title_page_opens_at_the_top() -> void:
	_size(2)
	await _open_page()
	await _settle()
	assert_bool(page.stacked).is_true()
	assert_bool(page.scrolls).is_true()
	assert_float(page.strip.screen_top()).is_equal(152.0)
	assert_that(page.view).is_equal(Rect2(0, 56, 320, 54))
	assert_int(page.offset).is_equal(0)
	assert_bool(page.shows_mark_above()).is_false()
	assert_bool(page.shows_mark_below()).is_true()
	assert_that(page.to_page(Vector2(0, 3))).is_equal(Vector2(0, 56))
	assert_bool(page.view.encloses(_drawn(0))).is_true()

func test_moving_down_and_up_scrolls_to_the_highlight() -> void:
	_size(2)
	await _open_page()
	await _settle()
	await _press(KEY_DOWN)
	assert_int(page.offset).is_equal(15)
	assert_bool(page.shows_mark_above()).is_true()
	assert_bool(page.shows_mark_below()).is_true()
	assert_bool(page.view.encloses(_drawn(1))).is_true()
	await _press(KEY_DOWN)
	assert_int(page.offset).is_equal(37)
	await _press(KEY_UP)
	assert_int(page.rules.row).is_equal(1)
	assert_int(page.offset).is_equal(37)   # row 1 is still wholly visible
	await _press(KEY_UP)
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.offset).is_equal(0)
	assert_bool(page.shows_mark_above()).is_false()

func test_up_from_the_top_shows_reset_and_the_fixed_lines() -> void:
	_size(2)
	await _open_page()
	await _settle()
	await _press(KEY_UP)
	assert_int(page.rules.row).is_equal(8)
	assert_int(page.offset).is_equal(198)
	assert_bool(page.shows_mark_above()).is_true()
	assert_bool(page.shows_mark_below()).is_false()
	assert_bool(page.view.encloses(_drawn(8))).is_true()

func test_every_row_is_drawn_inside_the_view() -> void:
	_size(2)
	await _open_page()
	await _settle()
	for r in ControlsMenu.ROWS:
		assert_int(page.rules.row).is_equal(r)
		assert_bool(page.view.encloses(_drawn(r))).is_true()
		await _press(KEY_DOWN)
	assert_int(page.rules.row).is_equal(0)
	page.rules.switch_tab()
	page._refresh()
	assert_int(page.rules.device).is_equal(Controls.Device.CONTROLLER)
	for r in ControlsMenu.ROWS:
		assert_int(page.rules.row).is_equal(r)
		assert_bool(page.view.encloses(_drawn(r))).is_true()
		await _press(KEY_DOWN)

func test_large_title_page_scrolls() -> void:
	_size(1)
	await _open_page()
	await _settle()
	assert_bool(page.stacked).is_true()
	# 1.5x scale makes the on-screen top 158.000015; ScrollWindow.band already rounds inwards past it
	assert_float(page.strip.screen_top()).is_equal_approx(158.0, 0.001)
	assert_that(page.view).is_equal(Rect2(0, 42, 320, 82))
	for i in 3:
		await _press(KEY_DOWN)
	assert_int(page.offset).is_equal(31)
	assert_bool(page.view.encloses(_drawn(3))).is_true()

func test_size_change_refollows_and_normal_stops_scrolling() -> void:
	_size(2)
	await _open_page()
	await _settle()
	await _press(KEY_DOWN)
	await _press(KEY_DOWN)
	assert_int(page.offset).is_equal(37)
	_size(-2)
	await _settle()
	assert_bool(page.scrolls).is_false()
	assert_int(page.offset).is_equal(0)
	assert_that(page.view).is_equal(Rect2(0, 0, 320, 180))
	assert_int(page.rules.row).is_equal(2)
	_size(2)
	await _settle()
	assert_bool(page.scrolls).is_true()
	assert_int(page.offset).is_equal(37)
	assert_bool(page.view.encloses(_drawn(2))).is_true()

func test_reopening_starts_at_the_top() -> void:
	_size(2)
	await _open_page()
	await _settle()
	await _press(KEY_UP)
	assert_int(page.offset).is_equal(198)
	await _press(KEY_ESCAPE)
	await _press(KEY_ENTER)
	await _settle()
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.offset).is_equal(0)
