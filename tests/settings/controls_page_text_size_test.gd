extends GdUnitTestSuite
## The Controls page at larger Text and UI sizes: its words grow, and the lines under the list wrap.
## On the default 1280x720 window (k = 2) at 640x360, UI size alone never stacks the page nor wraps its lines;
## the lines under the list wrap only at UI Largest and Text Largest, and there the Reset row and the lines
## under it fit the view together, so nothing reads on (reading on is tested on the pause host).

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/controls_page_text_size_none"   # never created

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

func test_normal_page_layout_is_todays() -> void:
	await _open_page()
	await _settle()
	assert_bool(page.stacked).is_false()
	assert_float(page.layout.rel).is_equal(1.0)
	assert_float(page.layout.content_bottom()).is_equal(ControlsPage.CONTENT_TOP + ControlsPage.CONTENT_H)
	assert_that(page.layout.tab_rect(1)).is_equal(ControlsPage.TAB_RECTS[1])

# UI Largest and Text Largest: the smallest combination at which the lines under the list wrap.
func test_largest_ui_page_wraps_the_lines_under_the_list() -> void:
	_size(2)
	_text(2)
	await _open_page()
	await _settle()
	assert_bool(page.stacked).is_true()
	assert_int(page.layout.no_key_lines).is_equal(2)
	assert_int(page.layout.fixed_lines).is_equal(3)
	# Text Largest's list (bottom 473 on the 320x180 page at UI Normal), moved down by TOP_SHIFT.
	assert_float(page.layout.content_bottom()).is_equal(473.0 + ControlsPage.TOP_SHIFT)

func test_text_largest_page_uses_the_grown_layout() -> void:
	_text(2)
	await _open_page()
	await _settle()
	assert_float(page.layout.rel).is_equal(2.0)
	assert_bool(page.stacked).is_true()
	assert_float(page.layout.row_h).is_equal(38.0)
	assert_float(page.layout.list_w).is_equal(272.0)
	assert_bool(page.scrolls).is_true()

func test_text_size_change_relays_out_with_the_highlight_unmoved() -> void:
	await _open_page()
	await _settle()
	for i in 3:
		await _press(KEY_DOWN)
	_text(2)
	await _settle()
	assert_bool(page.stacked).is_true()
	assert_float(page.layout.rel).is_equal(2.0)
	assert_int(page.rules.row).is_equal(3)
	_text(-2)
	await _settle()
	assert_bool(page.stacked).is_false()
	assert_float(page.layout.row_h).is_equal(11.0)
	assert_int(page.rules.row).is_equal(3)

func test_hover_and_click_land_on_grown_rows() -> void:
	_text(2)
	await _open_page()
	await _settle()
	for i in 2:
		await _press(KEY_DOWN)
	_motion(page, page.to_page(page.layout.slot_rect(2, 1).get_center()))
	assert_int(page.rules.row).is_equal(2)
	assert_int(page.rules.slot).is_equal(1)
	_left_click(page, page.to_page(page.layout.tab_rect(1).get_center()))
	assert_int(page.rules.device).is_equal(Controls.Device.CONTROLLER)

func test_largest_ui_and_text_keep_the_highlighted_slot_in_view() -> void:
	_size(2)
	_text(2)
	await _open_page()
	await _settle()
	for r in 8:
		assert_int(page.rules.row).is_equal(r)
		var c := page.layout.slot_rect(r, page.rules.slot)
		assert_bool(page.view.encloses(Rect2(page.to_page(c.position), c.size))).is_true()
		await _press(KEY_DOWN)
