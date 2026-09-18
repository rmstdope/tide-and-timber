extends GdUnitTestSuite
## The Controls page's box, too tall for the room above the Select / Back strip, scrolls its words and
## buttons a line per push, with ▲ / ▼. Wherever it fits, it is exactly as before.
## Reached the player's way: the default 1280x720 window (k = 2) at UI Largest and Text Largest, the only
## combination at which the box stacks and outgrows its band (tr-1o0.1, 640x360). There the Reset and Leaving
## boxes rest 312x136, their band is 133 deep and the view 113, over 118 units of content: they scroll 5 units,
## and both buttons are wholly in view at every offset. OK alone never scrolls at any UI size, Text size
## and window, so its scrolling, and anything needing a button out of view, was retired in tr-1o0.1.
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

# UI Largest and Text Largest: the smallest combination at which the box scrolls.
func _largest() -> void:
	_size_up(2)
	_text_up(2)

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

func _wheel(up: bool, times: int) -> void:
	for i in times:
		runner.simulate_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN)
		await runner.await_input_processed()

func _node(unique: String) -> Control:
	return page.get_node("%" + unique) as Control

func _panel() -> Control:
	return page.get_node("%Box/Panel") as Control

func _clip() -> Control:
	return page.get_node("%Box/Panel/Clip") as Control

func _content() -> Control:
	return page.get_node("%Box/Panel/Clip/Content") as Control

func _frame() -> BoxLayout:
	return page._box_frame

func _offset() -> int:
	return page._box_offset

func _rect(node: Control) -> Rect2:
	return Rect2(node.position, node.size)

# The rest panel framed to its band: at the band's top, as tall as the band.
func _band() -> Vector2:
	return ScrollWindow.band(_node("Box").get_global_transform_with_canvas(), page.strip.screen_top())

func _max_offset() -> int:
	return ceili(_frame().content_height() - _frame().clip.size.y)

# A button's (top, bottom) in content units, and whether it is wholly inside the view at `offset`.
func _in_view(button: Control, offset: int) -> bool:
	var top := button.position.y - _frame().content_top()
	return top >= offset and top + button.size.y <= offset + _frame().clip.size.y

func _assert_scrolls() -> void:
	assert_bool(_frame().scrolls).is_true()

func _is_highlighted(control: Control) -> bool:
	return is_same(control.get_theme_stylebox("panel"), ControlsPage.PLANK_HIGHLIGHT_STYLE)

func test_largest_opens_framed_at_the_top() -> void:
	_largest()
	await _open_reset()
	_assert_scrolls()
	var rest := page._box_layout.panel
	var b := _band()
	assert_that(_rect(_panel())).is_equal(Rect2(rest.position.x, b.x, rest.size.x, b.y - b.x))
	assert_that(_rect(_clip())).is_equal(Rect2(0, ScrollWindow.MARK_ROW, rest.size.x, b.y - b.x - 2.0 * ScrollWindow.MARK_ROW))
	assert_that(_rect(_content())).is_equal(Rect2(0, -_frame().content_top(), rest.size.x, rest.size.y))
	assert_int(_offset()).is_equal(0)
	assert_bool(_is_highlighted(_node("Safe"))).is_true()
	assert_bool(_frame().shows_mark_below()).is_true()
	assert_bool(_frame().shows_mark_above()).is_false()

func test_normal_fits_unchanged() -> void:
	await _open_reset()
	assert_that(_rect(_panel())).is_equal(Rect2(Screen.CENTRE - Vector2(148, 48), Vector2(296, 96)))   # the 296x96 box, centred
	assert_that(_clip().position).is_equal(Vector2.ZERO)
	assert_that(_content().position).is_equal(Vector2.ZERO)
	assert_bool(_frame().scrolls).is_false()
	assert_bool(_frame().shows_mark_above()).is_false()
	assert_bool(_frame().shows_mark_below()).is_false()

func test_the_buttons_stay_inside_the_content() -> void:
	_largest()
	await _open_leaving()
	_assert_scrolls()
	assert_bool(_frame().stacked).is_true()
	var w := _rect(_content()).size.x
	var safe := _rect(_node("Safe"))
	var other := _rect(_node("Other"))
	assert_float(safe.position.x).is_equal(roundf((w - safe.size.x) / 2.0))   # each button centred across the box
	assert_float(other.position.x).is_equal(roundf((w - other.size.x) / 2.0))
	assert_bool(safe.end.y < other.position.y).is_true()   # Set a key above Leave
	assert_bool(Rect2(Vector2.ZERO, _rect(_content()).size).encloses(other)).is_true()
	assert_that(_rect(_node("Lines")).position).is_equal(_frame().lines[0].position)
	assert_bool(is_same(_node("Safe").get_parent(), _content())).is_true()

func test_size_change_while_up_refits() -> void:
	_largest()
	await _open_reset()
	_assert_scrolls()
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	assert_that(_rect(_panel())).is_equal(Rect2(Screen.CENTRE - Vector2(148, 48), Vector2(296, 96)))
	assert_that(_content().position).is_equal(Vector2.ZERO)
	assert_bool(_frame().shows_mark_above()).is_false()
	assert_bool(_frame().shows_mark_below()).is_false()
	assert_bool(_is_highlighted(_node("Safe"))).is_true()

func test_reopening_starts_at_the_top() -> void:
	_largest()
	await _open_reset()
	_assert_scrolls()
	await _wheel(false, 3)
	assert_int(_offset()).is_greater(0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ENTER)
	await get_tree().process_frame
	assert_int(_offset()).is_equal(0)
	assert_float(_content().position.y).is_equal(-_frame().content_top())

func test_down_on_the_bottom_button_does_nothing() -> void:
	_largest()
	await _open_reset()
	_assert_scrolls()
	for i in 6:
		await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)
	assert_int(_offset()).is_equal(_max_offset())

func test_up_from_the_bottom_button_then_back_to_the_words() -> void:
	_largest()
	await _open_reset()
	_assert_scrolls()
	for i in 6:
		await _tap(KEY_DOWN)
	assert_int(_offset()).is_equal(_max_offset())
	await _tap(KEY_UP)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_bool(_in_view(_node("Safe"), _offset())).is_true()
	for i in 6:
		await _tap(KEY_UP)
	assert_int(_offset()).is_equal(0)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.RESET)
	assert_bool(_frame().shows_mark_below()).is_true()
	assert_bool(_frame().shows_mark_above()).is_false()

func test_left_and_right_move_and_show_the_button() -> void:
	_largest()
	await _open_reset()
	_assert_scrolls()
	await _tap(KEY_RIGHT)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)
	assert_int(_offset()).is_equal(_max_offset())   # Leave's bottom is the content's bottom
	await _tap(KEY_LEFT)
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_bool(_in_view(_node("Safe"), _offset())).is_true()

func test_the_wheel_scrolls_and_keeps_the_highlight() -> void:
	_largest()
	await _open_reset()
	_assert_scrolls()
	await _wheel(false, 1)
	var one := mini(int(BoxLayout.LINE_STEP), _max_offset())   # a line, or the rest of the content if less
	assert_int(_offset()).is_equal(one)
	assert_float(_content().position.y).is_equal(-(_frame().content_top() + one))
	assert_int(page.rules.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	await _wheel(true, 2)
	assert_int(_offset()).is_equal(0)

func test_right_then_select_leaves() -> void:
	_largest()
	await _open_leaving()
	_assert_scrolls()
	await _tap(KEY_RIGHT)
	assert_int(_offset()).is_equal(_max_offset())
	await _tap(KEY_ENTER)
	assert_bool(page.visible).is_false()
	assert_bool(board.visible).is_true()

func test_back_still_closes_while_scrolled() -> void:
	_largest()
	await _open_reset()
	_assert_scrolls()
	for i in 5:
		await _tap(KEY_DOWN)
	assert_int(_offset()).is_greater(0)
	await _tap(KEY_ESCAPE)
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.NONE)
	assert_bool(page.visible).is_true()
