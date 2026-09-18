extends GdUnitTestSuite
## The Controls page box stacks its buttons, left on top, when side by side is wider than the screen; OK alone follows.

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

func _assert_normal_box() -> void:
	assert_that(_panel_rect()).is_equal(Rect2(12, 42, 296, 96))
	assert_that(_rect("Lines")).is_equal(Rect2(8, 8, 280, 48))
	assert_that(_rect("Safe")).is_equal(Rect2(40, 66, 104, 20))
	assert_that(_rect("Other")).is_equal(Rect2(152, 66, 104, 20))

func test_normal_is_todays_layout() -> void:
	await _open_reset()
	assert_bool(_box_node("Box").visible).is_true()
	_assert_normal_box()

func test_reset_box_stacks_at_largest() -> void:
	_size_up(2)
	await _open_reset()
	assert_bool(_box_node("Box").visible).is_true()
	assert_that(_panel_rect()).is_equal(Rect2(84, 28, 152, 124))
	assert_that(_rect("Lines")).is_equal(Rect2(8, 8, 136, 48))
	assert_that(_rect("Safe")).is_equal(Rect2(24, 66, 104, 20))
	assert_that(_rect("Other")).is_equal(Rect2(24, 94, 104, 20))
	assert_bool(_is_highlighted(_box_node("Safe"))).is_true()
	assert_str(_box_label("Safe")).is_equal("Keep mine")
	assert_str(_box_label("Other")).is_equal("Reset")

func test_leaving_box_stacks_at_large() -> void:
	_size_up(1)
	await _open_leaving()
	assert_that(_panel_rect()).is_equal(Rect2(58, 28, 204, 124))
	assert_that(_rect("Lines")).is_equal(Rect2(8, 8, 188, 48))
	assert_that(_rect("Safe")).is_equal(Rect2(50, 66, 104, 20))
	assert_that(_rect("Other")).is_equal(Rect2(50, 94, 104, 20))
	assert_str(_box_label("Safe")).is_equal("Set a key")
	assert_str(_box_label("Other")).is_equal("Leave")

func test_stacking_while_up_keeps_the_highlight() -> void:
	await _open_reset()
	await _tap(KEY_RIGHT)
	_size_up(2)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)
	assert_bool(_is_highlighted(_box_node("Other"))).is_true()
	assert_that(_rect("Other").position).is_equal(Vector2(24, 94))
	Display.use_prefs(DisplayPrefs.new())
	_assert_normal_box()
	assert_bool(_is_highlighted(_box_node("Other"))).is_true()

func test_window_resize_refits() -> void:
	_size_up(1)
	await _open_reset()
	assert_float(_panel().size.x).is_equal(204.0)
	get_tree().root.size = Vector2i(640, 360)
	assert_float(_panel().size.x).is_equal(152.0)
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
	_size_up(2)
	await _open_leaving()
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_bool(page.visible).is_false()
	assert_bool(board.visible).is_true()

func test_back_and_click_when_stacked() -> void:
	_size_up(2)
	await _open_reset()
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
	_size_up(2)
	await _open_leaving()
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
	assert_that(_panel_rect()).is_equal(Rect2(12, 42, 296, 96))
	assert_that(_rect("Lines")).is_equal(Rect2(8, 8, 280, 48))
	assert_that(_rect("Safe")).is_equal(Rect2(96, 66, 104, 20))

func test_ok_alone_stacked_at_largest() -> void:
	_size_up(2)
	await _open_no_pad()
	assert_that(_panel_rect()).is_equal(Rect2(84, 42, 152, 96))
	assert_that(_rect("Lines")).is_equal(Rect2(8, 8, 136, 48))
	assert_that(_rect("Safe")).is_equal(Rect2(24, 66, 104, 20))
	assert_bool(_box_node("Other").visible).is_false()
	assert_bool(_is_highlighted(_box_node("Safe"))).is_true()

func test_ok_alone_stacked_at_large() -> void:
	_size_up(1)
	await _open_no_pad()
	assert_that(_panel_rect()).is_equal(Rect2(58, 42, 204, 96))
	assert_that(_rect("Lines")).is_equal(Rect2(8, 8, 188, 48))
	assert_that(_rect("Safe")).is_equal(Rect2(50, 66, 104, 20))

func test_ok_alone_up_down_keep_ok() -> void:
	_size_up(2)
	await _open_no_pad()
	await _tap(KEY_DOWN)
	await _tap(KEY_UP)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_bool(_box_node("Box").visible).is_true()
	await _tap(KEY_ENTER)
	assert_bool(_box_node("Box").visible).is_false()

func test_ok_then_two_button_box_refits() -> void:
	_size_up(2)
	await _open_no_pad()
	await _tap(KEY_ENTER)
	await _tap(KEY_E)
	await _down(8)
	await _tap(KEY_ENTER)
	assert_that(_panel_rect()).is_equal(Rect2(84, 28, 152, 124))
	assert_bool(_box_node("Other").visible).is_true()
	assert_that(_rect("Other").position).is_equal(Vector2(24, 94))

func test_size_change_while_ok_alone_is_up_keeps_one_button() -> void:
	await _open_no_pad()
	_size_up(2)
	assert_that(_panel_rect()).is_equal(Rect2(84, 42, 152, 96))
	assert_that(_rect("Safe")).is_equal(Rect2(24, 66, 104, 20))
	assert_bool(_box_node("Other").visible).is_false()
