extends GdUnitTestSuite
## The Controls page at a scale where its rows no longer fit across the screen: the name on top, the slots under it.
## The pure tests read the static Text-Normal geometry (ControlsLayout.STACKED_UI): the old 320x180 page's numbers
## plus O, the list and tabs centred on the picture and the block moved down by ControlsPage.TOP_SHIFT.
## The scene tests reach the stacked page the player's way: the default 1280x720 window (k = 2) at UI Normal and
## Text Large, the smallest combination that stacks it (UI size alone never does at 640x360, tr-1o0.1).

const A := Controls.Action
const D := Controls.Device

const O := Vector2(Screen.CENTRE.x - 160.0, ControlsPage.TOP_SHIFT)
const HALF_2X := 80.0 - ControlsPage.SCREEN_MARGIN   # half the 160 units the stacked list was made to fit, less a margin

var font: Font = load("res://assets/fonts/PressStart2P-Regular.ttf")
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

func _w(text: String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x

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

func _r(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(Vector2(x, y) + O, Vector2(w, h))

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

# --- pure ---

func test_stacks_at() -> void:
	assert_bool(ControlsPage.stacks_at(1.0)).is_false()
	assert_bool(ControlsPage.stacks_at(2.0)).is_false()   # UI Largest alone never stacks
	# the list and EDGE each side just fit the widest board
	assert_bool(ControlsPage.stacks_at(2.07)).is_false()
	assert_bool(ControlsPage.stacks_at(2.08)).is_true()
	assert_bool(ControlsPage.stacks_at(1.0, 1.5)).is_true()   # Text Large does

func test_stacked_rows_and_slots() -> void:
	assert_that(ControlsPage.row_rect(0, true)).is_equal(_r(86, 28, 148, 22))
	assert_that(ControlsPage.row_rect(8, true)).is_equal(_r(86, 204, 148, 22))
	assert_that(ControlsPage.slot_rect(3, 0, true)).is_equal(_r(96, 105, 60, 9))
	assert_that(ControlsPage.slot_rect(3, 1, true)).is_equal(_r(164, 105, 60, 9))
	for r in 8:
		for s in 2:
			assert_bool(ControlsPage.row_rect(r, true).encloses(ControlsPage.slot_rect(r, s, true))).is_true()
	assert_that(ControlsPage.row_rect(0)).is_equal(_r(16, 28, 288, 11))

func test_stacked_list_and_tabs_fit_a_2x_page() -> void:
	for r in ControlsMenu.ROWS:
		assert_float(ControlsPage.row_rect(r, true).position.x).is_greater_equal(Screen.CENTRE.x - HALF_2X)
		assert_float(ControlsPage.row_rect(r, true).end.x).is_less_equal(Screen.CENTRE.x + HALF_2X)
	for i in 2:
		assert_float(ControlsPage.tab_rect(i, true).position.x).is_greater_equal(Screen.CENTRE.x - HALF_2X)
		assert_float(ControlsPage.tab_rect(i, true).end.x).is_less_equal(Screen.CENTRE.x + HALF_2X)
		assert_float(_w(ControlsPage.TAB_NAMES[i])).is_less_equal(ControlsPage.tab_rect(i, true).size.x - 4)

func test_stacked_hit() -> void:
	assert_that(ControlsPage.hit(ControlsPage.slot_rect(3, 1, true).get_center(), D.KEYBOARD, true)).is_equal(Vector2i(3, 1))
	assert_that(ControlsPage.hit(ControlsPage.slot_rect(3, 1, true).get_center(), D.CONTROLLER, true)).is_equal(Vector2i(-1, -1))
	assert_that(ControlsPage.hit(Vector2(90, 28 + 3 * 22 + 5) + O, D.KEYBOARD, true)).is_equal(Vector2i(-1, -1))
	assert_that(ControlsPage.hit(ControlsPage.row_rect(8, true).get_center(), D.KEYBOARD, true)).is_equal(Vector2i(8, -1))
	assert_int(ControlsPage.tab_at(ControlsPage.tab_rect(1, true).get_center(), true)).is_equal(1)

func test_name_lines() -> void:
	var w := ControlsPage.NAME_WRAP_W
	assert_array(Array(ControlsPage.name_lines("Reset controller to defaults", w, font))).is_equal(["Reset controller", "to defaults"])
	assert_array(Array(ControlsPage.name_lines("Reset keyboard to defaults", w, font))).is_equal(["Reset keyboard", "to defaults"])
	assert_array(Array(ControlsPage.name_lines("Walk right", w, font))).is_equal(["Walk right"])

func test_text_baselines() -> void:
	var n := ControlsLayout.make(false, 1.0, 1.0)
	assert_array([n.no_key_baseline(), n.fixed_baseline(), n.content_bottom()]).is_equal([137.0 + O.y, 147.0 + O.y, ControlsPage.CONTENT_TOP + ControlsPage.CONTENT_H])
	var s := ControlsLayout.make(true, 1.0, 1.5)
	assert_array([s.no_key_baseline(), s.fixed_baseline(), s.content_bottom()]).is_equal([236.0 + O.y, 246.0 + O.y, 255.0 + O.y])

# --- pause ---

func test_page_stacks_at_largest_and_unstacks_at_normal() -> void:
	_text(1)
	await _open_page()
	assert_bool(page.stacked).is_true()
	for i in 3:
		await _tap(KEY_DOWN)
	assert_int(page.rules.row).is_equal(3)
	_text(-1)
	await _settle()
	assert_bool(page.stacked).is_false()
	assert_int(page.rules.row).is_equal(3)
	_text(1)
	await _settle()
	assert_bool(page.stacked).is_true()
	assert_int(page.rules.row).is_equal(3)

func test_normal_page_is_not_stacked() -> void:
	await _open_page()
	assert_bool(page.stacked).is_false()

func test_stacked_mouse_hovers_and_clicks() -> void:
	_text(1)
	await _open_page()
	assert_bool(page.stacked).is_true()
	assert_bool(page.scrolls).is_true()
	# The page scrolls here (tr-eg9.6.4.3), so the pointer goes where the rows are drawn, at Text Large's layout.
	_motion(page, page.to_page(page.layout.slot_rect(0, 1).get_center()))
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.rules.slot).is_equal(1)
	_left_click(page, page.to_page(page.layout.tab_rect(1).get_center()))
	assert_int(page.rules.device).is_equal(D.CONTROLLER)
	await _tap(KEY_UP)
	assert_int(page.rules.row).is_equal(ControlsMenu.RESET_ROW)
	assert_int(page.offset).is_greater(0)
	assert_int(page.offset).is_equal(ControlsPage.reset_span(page.layout, page.view.size.y).x)   # landing reads the row from its top
	_left_click(page, page.to_page(page.layout.row_rect(8).get_center()))
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.RESET)
