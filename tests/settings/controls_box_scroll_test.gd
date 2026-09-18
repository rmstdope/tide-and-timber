extends GdUnitTestSuite
## The Controls page's box, too tall for the room above the Select / Back strip, scrolls its words and
## buttons a line per push, with ▲ / ▼. Wherever it fits, it is exactly as before.

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
	get_tree().root.size = Vector2i(2560, 1440)
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
	await get_tree().process_frame

func _open_leaving() -> void:
	await _open_page()
	await _down(6)
	await _tap(KEY_DELETE)
	await _tap(KEY_ESCAPE)
	await get_tree().process_frame

func _open_no_pad() -> void:
	page.pad_connected = func() -> bool: return false
	await _open_page()
	await _tap(KEY_E)
	await _tap(KEY_ENTER)
	await get_tree().process_frame

func _wheel(up: bool, times: int) -> void:
	for i in times:
		runner.simulate_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN)
		await runner.await_input_processed()

func _move_mouse(to: Vector2) -> void:
	runner.simulate_mouse_move(to)
	await runner.await_input_processed()

func _node(unique: String) -> Control:
	return page.get_node("%" + unique) as Control

func _panel() -> Control:
	return page.get_node("%Box/Panel") as Control

func _clip() -> Control:
	return page.get_node("%Box/Panel/Clip") as Control

func _content() -> Control:
	return page.get_node("%Box/Panel/Clip/Content") as Control

func _marks() -> Control:
	return page.get_node("%Box/Panel/Marks") as Control

func _frame() -> BoxLayout:
	return page._box_frame

func _offset() -> int:
	return page._box_offset

func _rect(node: Control) -> Rect2:
	return Rect2(node.position, node.size)

func _is_highlighted(control: Control) -> bool:
	return is_same(control.get_theme_stylebox("panel"), ControlsPage.PLANK_HIGHLIGHT_STYLE)

func test_largest_opens_framed_at_the_top() -> void:
	_size_up(2)
	await _open_reset()
	assert_float(page.strip.screen_top()).is_equal(108.0)
	assert_that(_rect(_panel())).is_equal(Rect2(84, 46, 152, 52))
	assert_that(_rect(_clip())).is_equal(Rect2(0, 10, 152, 32))
	assert_that(_rect(_content())).is_equal(Rect2(0, -8, 152, 124))
	assert_int(_offset()).is_equal(0)
	assert_bool(_is_highlighted(_node("Safe"))).is_true()
	assert_bool(_frame().shows_mark_below()).is_true()
	assert_bool(_frame().shows_mark_above()).is_false()

func test_large_is_framed_too() -> void:
	_size_up(1)
	await _open_reset()
	assert_that(_rect(_panel())).is_equal(Rect2(58, 32, 204, 80))
	assert_that(_rect(_clip())).is_equal(Rect2(0, 10, 204, 60))
	assert_that(_rect(_content())).is_equal(Rect2(0, -8, 204, 124))

func test_normal_fits_unchanged() -> void:
	await _open_reset()
	assert_that(_rect(_panel())).is_equal(Rect2(12, 42, 296, 96))
	assert_that(_clip().position).is_equal(Vector2.ZERO)
	assert_that(_content().position).is_equal(Vector2.ZERO)
	assert_bool(_frame().scrolls).is_false()
	assert_bool(_frame().shows_mark_above()).is_false()
	assert_bool(_frame().shows_mark_below()).is_false()

func test_ok_alone_is_framed() -> void:
	_size_up(2)
	await _open_no_pad()
	assert_that(_rect(_panel())).is_equal(Rect2(84, 46, 152, 52))
	assert_that(_rect(_content())).is_equal(Rect2(0, -8, 152, 96))
	assert_bool(_frame().shows_mark_below()).is_true()
	assert_bool(_frame().shows_mark_above()).is_false()

func test_the_buttons_stay_inside_the_content() -> void:
	_size_up(2)
	await _open_leaving()
	assert_that(_rect(_node("Safe"))).is_equal(Rect2(24, 66, 104, 20))
	assert_that(_rect(_node("Other"))).is_equal(Rect2(24, 94, 104, 20))
	assert_that(_rect(_node("Lines"))).is_equal(Rect2(8, 8, 136, 48))
	assert_bool(is_same(_node("Safe").get_parent(), _content())).is_true()

func test_size_change_while_up_refits() -> void:
	_size_up(2)
	await _open_reset()
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	assert_that(_rect(_panel())).is_equal(Rect2(12, 42, 296, 96))
	assert_that(_content().position).is_equal(Vector2.ZERO)
	assert_bool(_frame().shows_mark_above()).is_false()
	assert_bool(_frame().shows_mark_below()).is_false()
	assert_bool(_is_highlighted(_node("Safe"))).is_true()

func test_reopening_starts_at_the_top() -> void:
	_size_up(2)
	await _open_reset()
	await _wheel(false, 3)
	assert_int(_offset()).is_greater(0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ENTER)
	await get_tree().process_frame
	assert_int(_offset()).is_equal(0)
	assert_float(_content().position.y).is_equal(-8.0)

# The box at Largest in the waking scene: a 52-unit band, a 32-unit view and 106 units of content,
# so the greatest offset is 74. Safe spans content 58..78 and Other 86..106.
func test_down_scrolls_to_the_top_button_then_moves_on() -> void:
	_size_up(2)
	await _open_reset()
	for i in 5:
		await _tap(KEY_DOWN)
	assert_int(_offset()).is_equal(46)
	assert_float(_content().position.y).is_equal(-54.0)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	await _tap(KEY_DOWN)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)
	assert_int(_offset()).is_equal(74)
	assert_float(_content().position.y).is_equal(-82.0)
	assert_bool(_frame().shows_mark_above()).is_true()
	assert_bool(_frame().shows_mark_below()).is_false()

func test_down_on_the_bottom_button_does_nothing() -> void:
	_size_up(2)
	await _open_reset()
	for i in 6:
		await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)
	assert_int(_offset()).is_equal(74)

func test_up_from_the_bottom_button_then_back_to_the_words() -> void:
	_size_up(2)
	await _open_reset()
	for i in 6:
		await _tap(KEY_DOWN)
	await _tap(KEY_UP)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_int(_offset()).is_equal(58)
	for i in 6:
		await _tap(KEY_UP)
	assert_int(_offset()).is_equal(0)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.RESET)
	assert_bool(_frame().shows_mark_below()).is_true()
	assert_bool(_frame().shows_mark_above()).is_false()

func test_left_and_right_move_and_show_the_button() -> void:
	_size_up(2)
	await _open_reset()
	await _tap(KEY_RIGHT)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)
	assert_int(_offset()).is_equal(74)
	await _tap(KEY_LEFT)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_int(_offset()).is_equal(58)

func test_the_wheel_scrolls_and_keeps_the_highlight() -> void:
	_size_up(2)
	await _open_reset()
	await _wheel(false, 1)
	assert_int(_offset()).is_equal(11)
	assert_float(_content().position.y).is_equal(-19.0)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	await _wheel(true, 2)
	assert_int(_offset()).is_equal(0)

func test_select_presses_an_out_of_sight_button() -> void:
	_size_up(2)
	await _open_page()
	await _tap(KEY_DELETE)   # clear the highlighted slot, so Keep mine has something to keep
	await _down(8)
	await _tap(KEY_ENTER)
	await get_tree().process_frame
	assert_int(_offset()).is_equal(0)   # Keep mine, at content 58..78, is below the 0..32 view
	await _tap(KEY_ENTER)
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.NONE)
	assert_bool(page.visible).is_true()
	assert_object(InputDevice.controls.slot(0 as Controls.Action, Controls.Device.KEYBOARD, 0)).is_null()

func test_right_then_select_leaves() -> void:
	_size_up(2)
	await _open_leaving()
	await _tap(KEY_RIGHT)
	assert_int(_offset()).is_equal(74)
	await _tap(KEY_ENTER)
	assert_bool(page.visible).is_false()
	assert_bool(board.visible).is_true()

func test_ok_alone_ignores_right_and_scrolls() -> void:
	_size_up(2)
	await _open_no_pad()
	await _tap(KEY_RIGHT)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_int(_offset()).is_equal(46)

func test_back_still_closes_while_scrolled() -> void:
	_size_up(2)
	await _open_reset()
	for i in 5:
		await _tap(KEY_DOWN)
	await _tap(KEY_ESCAPE)
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.NONE)
	assert_bool(page.visible).is_true()

func test_hover_lands_only_on_the_drawn_part() -> void:
	_size_up(2)
	await _open_reset()
	await _tap(KEY_RIGHT)
	await _wheel(true, 7)
	assert_int(_offset()).is_equal(0)
	var safe := _node("Safe")
	await _move_mouse(safe.get_global_rect().get_center())
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)
	assert_int(_offset()).is_equal(0)
	await _wheel(false, 6)
	assert_int(_offset()).is_equal(66)
	await _move_mouse(Vector2(safe.get_global_rect().get_center().x,
			_clip().get_global_rect().position.y + 2.0))
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_int(_offset()).is_equal(66)
