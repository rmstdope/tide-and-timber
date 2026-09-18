extends GdUnitTestSuite
## The Controls page box stacks its buttons, left on top, when side by side is wider than the screen; OK alone follows.
## Reached the player's way: the default 1280x720 window (k = 2) at UI Largest and Text Largest, the only
## combination at which the Reset and Leaving boxes stack (tr-1o0.1, 640x360); there they rest 312x136.
## OK alone never stacks at any UI size, Text size and window, and nothing stacks at UI Large, so those
## layouts were retired in tr-1o0.1.

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
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	board = pause.get_node("%SettingsBoard")
	page = board.get_node("%ControlsPage")
	page.pad_connected = func() -> bool: return true
	pause.quit_to_title = func() -> void: pass
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _size_up(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)

func _text_up(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)

# UI Largest and Text Largest: the smallest combination at which the box stacks.
func _largest() -> void:
	_size_up(2)
	_text_up(2)

func _control() -> void:
	waking.tick(5.0)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _left_click(control: Control, at: Vector2 = Vector2.ZERO) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	control.gui_input.emit(click)

func _open_settings() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_UP)   # the board opens on UI size; Up wraps to Controls

func _open_page() -> void:
	await _open_settings()
	await _tap(KEY_ENTER)

func _down(times: int) -> void:
	for i in times:
		await _tap(KEY_DOWN)

func _open_reset() -> void:
	await _open_page()
	await _down(8)
	await _tap(KEY_ENTER)

func _open_leaving() -> void:
	await _open_page()
	await _down(6)
	await _tap(KEY_DELETE)
	await _tap(KEY_ESCAPE)

func _open_no_pad() -> void:
	page.pad_connected = func() -> bool: return false
	await _open_page()
	await _tap(KEY_E)
	await _tap(KEY_ENTER)

func _is_highlighted(control: Control) -> bool:
	return is_same(control.get_theme_stylebox("panel"), ControlsPage.PLANK_HIGHLIGHT_STYLE)

func _box_node(unique: String) -> Control:
	return page.get_node("%" + unique) as Control

func _box_label(unique: String) -> String:
	return (_box_node(unique).get_node("Label") as GrownWords).text

func _panel() -> Control:
	return page.get_node("%Box/Panel") as Control

func _rect(unique: String) -> Rect2:
	var n := _box_node(unique)
	return Rect2(n.position, n.size)

# The rest layout: what _fit_box laid out, before the box is framed to the room above the strip.
func _panel_rect() -> Rect2:
	return page._box_layout.panel

func _ui() -> float:
	return UiScale.current(Display.prefs, get_tree().root)

# A panel of size `size`, centred on the picture.
func _centred(size: Vector2) -> Rect2:
	return Rect2((Screen.CENTRE - size / 2.0).round(), size)

func _assert_stacked() -> void:
	assert_bool(page._box_layout.stacked).is_true()

# The stacked two-button box at UI Largest and Text Largest: as wide as the picture allows at that scale;
# 136 tall = 8 + 60 of grown lines + 10 + 20 (top button) + 8 + 20 (bottom button) + 10.
func _assert_stacked_box() -> void:
	assert_that(_panel_rect()).is_equal(_centred(Vector2(BoxLayout.widest(_ui()), 136)))
	var w := _panel_rect().size.x
	assert_that(_rect("Safe")).is_equal(Rect2(roundf((w - _rect("Safe").size.x) / 2.0), 78, _rect("Safe").size.x, 20))
	assert_that(_rect("Other")).is_equal(Rect2(roundf((w - 104.0) / 2.0), 106, 104, 20))

func _assert_normal_box() -> void:
	assert_that(_panel_rect()).is_equal(_centred(Vector2(296, 96)))
	assert_that(_rect("Lines")).is_equal(Rect2(8, 8, 280, 48))
	assert_that(_rect("Safe")).is_equal(Rect2(40, 66, 104, 20))
	assert_that(_rect("Other")).is_equal(Rect2(152, 66, 104, 20))

func test_normal_is_todays_layout() -> void:
	await _open_reset()
	assert_bool(_box_node("Box").visible).is_true()
	_assert_normal_box()

# The first layout of a freshly opened box measures the buttons' grown words before the buttons' own
# minimum has caught up with them; the stacked Safe button must be centred from the start, not after a push.
func test_the_stacked_safe_button_is_centred_on_first_open() -> void:
	_size_up(2)
	for i in 2:
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	await _open_reset()
	_assert_stacked()
	var w := _panel_rect().size.x
	var safe := _rect("Safe")
	assert_float(safe.size.x).is_equal(_box_node("Safe").get_combined_minimum_size().x)
	assert_float(safe.position.x).is_equal(roundf((w - safe.size.x) / 2.0))

func test_reset_box_stacks_at_largest() -> void:
	_largest()
	await _open_reset()
	_assert_stacked()
	assert_bool(_box_node("Box").visible).is_true()
	_assert_stacked_box()
	assert_that(_rect("Lines").position).is_equal(Vector2(8, 8))
	assert_float(_rect("Lines").size.x * _box_node("Lines").scale.x).is_equal(_panel_rect().size.x - 16.0)   # the panel less 8 a side
	assert_bool(_is_highlighted(_box_node("Safe"))).is_true()
	assert_str(_box_label("Safe")).is_equal("Keep mine")
	assert_str(_box_label("Other")).is_equal("Reset")

func test_leaving_box_stacks_at_largest() -> void:
	_largest()
	await _open_leaving()
	_assert_stacked()
	_assert_stacked_box()
	assert_str(_box_label("Safe")).is_equal("Set a key")
	assert_str(_box_label("Other")).is_equal("Leave")

func test_stacking_while_up_keeps_the_highlight() -> void:
	await _open_reset()
	await _tap(KEY_RIGHT)
	_largest()
	_assert_stacked()
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)
	assert_bool(_is_highlighted(_box_node("Other"))).is_true()
	assert_that(_rect("Other").position).is_equal(Vector2(roundf((_panel_rect().size.x - 104.0) / 2.0), 106))
	Display.use_prefs(DisplayPrefs.new())
	_assert_normal_box()
	assert_bool(_is_highlighted(_box_node("Other"))).is_true()

# UI Large and Text Largest: the box is as wide as the picture allows, and follows the window's scale.
func test_window_resize_refits() -> void:
	_size_up(1)
	_text_up(2)
	await _open_reset()
	assert_float(_ui()).is_equal(1.5)
	assert_float(_panel().size.x).is_equal(BoxLayout.widest(1.5))   # 418
	get_tree().root.size = Vector2i(640, 360)   # k = 1: UI Large rounds up to 2
	assert_float(_ui()).is_equal(2.0)
	assert_float(_panel().size.x).is_equal(BoxLayout.widest(2.0))   # 312
	get_tree().root.size = Vector2i(1280, 720)

func test_up_down_do_nothing_side_by_side() -> void:
	await _open_reset()
	await _tap(KEY_DOWN)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_bool(_box_node("Box").visible).is_true()
	assert_int(page.rules.row).is_equal(ControlsMenu.RESET_ROW)
	await _tap(KEY_RIGHT)
	await _tap(KEY_UP)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)

func test_select_when_stacked() -> void:
	_largest()
	await _open_leaving()
	_assert_stacked()
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_bool(page.visible).is_false()
	assert_bool(board.visible).is_true()

func test_back_and_click_when_stacked() -> void:
	_largest()
	await _open_reset()
	_assert_stacked()
	await _tap(KEY_ESCAPE)
	assert_bool(_box_node("Box").visible).is_false()
	assert_bool(page.visible).is_true()
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.NONE)
	await _tap(KEY_ENTER)
	assert_bool(_box_node("Box").visible).is_true()
	_left_click(_box_node("Other"))
	assert_bool(_box_node("Box").visible).is_false()
	assert_bool(page.visible).is_true()
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)

func test_stacked_buttons_do_not_overlap() -> void:
	_largest()
	await _open_leaving()
	_assert_stacked()
	var safe := _box_node("Safe").get_global_rect()
	var other := _box_node("Other").get_global_rect()
	assert_bool(safe.intersects(other)).is_false()
	var content := page.get_node("%Box/Panel/Clip/Content") as Control
	assert_bool(content.get_global_rect().encloses(safe)).is_true()
	assert_bool(content.get_global_rect().encloses(other)).is_true()

func test_ok_alone_side_by_side_is_todays_layout() -> void:
	await _open_no_pad()
	assert_str(_box_label("Safe")).is_equal("OK")
	assert_bool(_box_node("Other").visible).is_false()
	assert_that(_panel_rect()).is_equal(_centred(Vector2(296, 96)))
	assert_that(_rect("Lines")).is_equal(Rect2(8, 8, 280, 48))
	assert_that(_rect("Safe")).is_equal(Rect2(96, 66, 104, 20))

func test_ok_then_two_button_box_refits() -> void:
	_largest()
	await _open_no_pad()
	await _tap(KEY_ENTER)
	await _tap(KEY_E)
	await _down(8)
	await _tap(KEY_ENTER)
	_assert_stacked()
	assert_that(_panel_rect()).is_equal(_centred(Vector2(BoxLayout.widest(_ui()), 136)))
	assert_bool(_box_node("Other").visible).is_true()
	assert_that(_rect("Other").position).is_equal(Vector2(roundf((_panel_rect().size.x - 104.0) / 2.0), 106))
