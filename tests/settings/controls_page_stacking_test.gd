extends GdUnitTestSuite
## The Controls page at a scale where its rows no longer fit across the screen: the name on top, the slots under it.

const A := Controls.Action
const D := Controls.Device

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
	assert_bool(ControlsPage.stacks_at(1.09)).is_false()
	assert_bool(ControlsPage.stacks_at(1.5)).is_true()
	assert_bool(ControlsPage.stacks_at(2.0)).is_true()

func test_stacked_rows_and_slots() -> void:
	assert_that(ControlsPage.row_rect(0, true)).is_equal(Rect2(86, 28, 148, 22))
	assert_that(ControlsPage.row_rect(8, true)).is_equal(Rect2(86, 204, 148, 22))
	assert_that(ControlsPage.slot_rect(3, 0, true)).is_equal(Rect2(96, 105, 60, 9))
	assert_that(ControlsPage.slot_rect(3, 1, true)).is_equal(Rect2(164, 105, 60, 9))
	for r in 8:
		for s in 2:
			assert_bool(ControlsPage.row_rect(r, true).encloses(ControlsPage.slot_rect(r, s, true))).is_true()
	assert_that(ControlsPage.row_rect(0)).is_equal(Rect2(16, 28, 288, 11))

func test_stacked_list_and_tabs_fit_a_2x_page() -> void:
	for r in ControlsMenu.ROWS:
		assert_float(ControlsPage.row_rect(r, true).position.x).is_greater_equal(82.0)
		assert_float(ControlsPage.row_rect(r, true).end.x).is_less_equal(238.0)
	for i in 2:
		assert_float(ControlsPage.tab_rect(i, true).position.x).is_greater_equal(82.0)
		assert_float(ControlsPage.tab_rect(i, true).end.x).is_less_equal(238.0)
		assert_float(_w(ControlsPage.TAB_NAMES[i])).is_less_equal(ControlsPage.tab_rect(i, true).size.x - 4)

func test_stacked_hit() -> void:
	assert_that(ControlsPage.hit(ControlsPage.slot_rect(3, 1, true).get_center(), D.KEYBOARD, true)).is_equal(Vector2i(3, 1))
	assert_that(ControlsPage.hit(ControlsPage.slot_rect(3, 1, true).get_center(), D.CONTROLLER, true)).is_equal(Vector2i(-1, -1))
	assert_that(ControlsPage.hit(Vector2(90, 28 + 3 * 22 + 5), D.KEYBOARD, true)).is_equal(Vector2i(-1, -1))
	assert_that(ControlsPage.hit(ControlsPage.row_rect(8, true).get_center(), D.KEYBOARD, true)).is_equal(Vector2i(8, -1))
	assert_int(ControlsPage.tab_at(ControlsPage.tab_rect(1, true).get_center(), true)).is_equal(1)

func test_name_lines() -> void:
	assert_array(Array(ControlsPage.name_lines("Reset controller to defaults", 140, font))).is_equal(["Reset controller", "to defaults"])
	assert_array(Array(ControlsPage.name_lines("Reset keyboard to defaults", 140, font))).is_equal(["Reset keyboard to", "defaults"])   # 136 wide: "to" fits on the first line
	assert_array(Array(ControlsPage.name_lines("Walk right", 140, font))).is_equal(["Walk right"])

func test_text_baselines() -> void:
	assert_array(ControlsPage.text_baselines()).is_equal([137.0, 147.0, 156.0])
	assert_array(ControlsPage.text_baselines(true)).is_equal([236.0, 246.0, 255.0])

# --- pause ---

func test_page_stacks_at_largest_and_unstacks_at_normal() -> void:
	_size(2)
	await _open_page()
	assert_bool(page.stacked).is_true()
	for i in 3:
		await _tap(KEY_DOWN)
	assert_int(page.rules.row).is_equal(3)
	_size(-2)
	await _settle()
	assert_bool(page.stacked).is_false()
	assert_int(page.rules.row).is_equal(3)
	_size(2)
	await _settle()
	assert_bool(page.stacked).is_true()
	assert_int(page.rules.row).is_equal(3)

func test_normal_page_is_not_stacked() -> void:
	await _open_page()
	assert_bool(page.stacked).is_false()

func test_stacked_mouse_hovers_and_clicks() -> void:
	_size(2)
	await _open_page()
	_motion(page, ControlsPage.slot_rect(4, 1, true).get_center())
	assert_int(page.rules.row).is_equal(4)
	assert_int(page.rules.slot).is_equal(1)
	_left_click(page, ControlsPage.tab_rect(1, true).get_center())
	assert_int(page.rules.device).is_equal(D.CONTROLLER)
	_left_click(page, ControlsPage.row_rect(8, true).get_center())
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.RESET)
