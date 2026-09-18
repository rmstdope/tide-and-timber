extends GdUnitTestSuite
## The pause Quit box, too tall for the room above the Select / Back strip, scrolls its words and
## buttons a line per push, with ▲ / ▼.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var calls: Array[String] = []
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(2560, 1440)
	Display.use_prefs(DisplayPrefs.new())
	Pause.debug_tools = false
	InputDevice.reset()
	calls = []
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	var recorded := calls
	pause.quit_to_title = func() -> void: recorded.append("title")
	pause.open_settings = func() -> void: recorded.append("settings")
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

func _node(unique: String) -> Control:
	return pause.get_node("%" + unique)

func _panel() -> Control:
	return pause.get_node("%QuitBox/Panel")

func _clip() -> Control:
	return pause.get_node("%QuitBox/Panel/Clip")

func _content() -> Control:
	return pause.get_node("%QuitBox/Panel/Clip/Content")

func _frame() -> BoxLayout:
	return pause._quit_frame

func _rect(node: Control) -> Rect2:
	return Rect2(node.position, node.size)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _wheel(down: bool, times: int) -> void:
	for i in times:
		await runner.simulate_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN if down else MOUSE_BUTTON_WHEEL_UP)
		await runner.await_input_processed()

func _open_box() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)
	await get_tree().process_frame

func _highlighted(unique: String) -> void:
	assert_bool(is_same(_node(unique).get_theme_stylebox("panel"), Pause.PLANK_HIGHLIGHT_STYLE)) \
		.override_failure_message(unique + " is not highlighted").is_true()

func test_largest_opens_framed_at_the_top() -> void:
	_size_up(2)
	await _open_box()
	assert_float(pause.strip.screen_top()).is_equal(108.0)
	assert_that(_rect(_panel())).is_equal(Rect2(84, 46, 152, 52))
	assert_that(_rect(_clip())).is_equal(Rect2(0, 10, 152, 32))
	assert_that(_rect(_content())).is_equal(Rect2(0, -8, 152, 124))
	_highlighted("Stay")
	assert_bool(_frame().shows_mark_below()).is_true()
	assert_bool(_frame().shows_mark_above()).is_false()

func test_down_scrolls_to_stay_then_moves_to_quit() -> void:
	_size_up(2)
	await _open_box()
	for i in 5:
		await _tap(KEY_DOWN)
	assert_float(_content().position.y).is_equal(-54.0)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.STAY)
	await _tap(KEY_DOWN)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)
	assert_float(_content().position.y).is_equal(-82.0)
	assert_bool(_frame().shows_mark_above()).is_true()
	assert_bool(_frame().shows_mark_below()).is_false()

func test_up_from_quit_to_stay_then_back_to_the_words() -> void:
	_size_up(2)
	await _open_box()
	await _tap(KEY_RIGHT)
	assert_int(pause._quit_offset).is_equal(74)
	await _tap(KEY_UP)
	_highlighted("Stay")
	assert_float(_content().position.y).is_equal(-66.0)
	for i in 6:
		await _tap(KEY_UP)
	assert_float(_content().position.y).is_equal(-8.0)
	_highlighted("Stay")
	assert_bool(_node("QuitBox").visible).is_true()

func test_select_presses_a_hidden_highlight() -> void:
	_size_up(2)
	await _open_box()
	await _tap(KEY_RIGHT)
	await _tap(KEY_LEFT)
	assert_int(pause._quit_offset).is_equal(58)
	await _wheel(true, 2)
	assert_int(pause._quit_offset).is_equal(74)
	await _tap(KEY_ENTER)
	assert_bool(_node("QuitBox").visible).is_false()
	assert_bool(pause.rules.quitting).is_false()
	_highlighted("QuitToTitle")

func test_right_then_enter_quits() -> void:
	_size_up(2)
	await _open_box()
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_bool(pause.rules.quitting).is_true()

func test_wheel_scrolls_and_keeps_the_highlight() -> void:
	_size_up(2)
	await _open_box()
	await _wheel(true, 1)
	assert_int(pause._quit_offset).is_equal(11)
	assert_float(_content().position.y).is_equal(-19.0)
	_highlighted("Stay")

func test_hover_lands_only_on_the_drawn_part() -> void:
	_size_up(2)
	await _open_box()
	await _tap(KEY_RIGHT)
	await _wheel(false, 7)
	assert_int(pause._quit_offset).is_equal(0)
	var stay_centre := _node("Stay").get_global_rect().get_center()
	runner.simulate_mouse_move(stay_centre)
	await runner.await_input_processed()
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)
	assert_int(pause._quit_offset).is_equal(0)
	await _wheel(true, 6)
	assert_int(pause._quit_offset).is_equal(66)
	runner.simulate_mouse_move(Vector2(_node("Stay").get_global_rect().get_center().x,
			_clip().get_global_rect().position.y + 2))
	await runner.await_input_processed()
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.STAY)
	assert_int(pause._quit_offset).is_equal(66)

func test_normal_fits_unchanged() -> void:
	await _open_box()
	assert_that(_rect(_panel())).is_equal(Rect2(12, 42, 296, 96))
	assert_that(_content().position).is_equal(Vector2.ZERO)
	assert_bool(_frame().shows_mark_above()).is_false()
	assert_bool(_frame().shows_mark_below()).is_false()

func test_size_change_while_up_refits() -> void:
	_size_up(2)
	await _open_box()
	for i in 3:
		await _tap(KEY_DOWN)
	assert_int(pause._quit_offset).is_equal(33)
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	assert_that(_rect(_panel())).is_equal(Rect2(12, 42, 296, 96))
	assert_bool(_frame().shows_mark_above()).is_false()
	assert_bool(_frame().shows_mark_below()).is_false()
	_highlighted("Stay")
	assert_that(_content().position).is_equal(Vector2.ZERO)

func test_reopening_starts_at_the_top() -> void:
	_size_up(2)
	await _open_box()
	await _tap(KEY_RIGHT)
	assert_int(pause._quit_offset).is_equal(74)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ENTER)
	await get_tree().process_frame
	assert_float(_content().position.y).is_equal(-8.0)
	_highlighted("Stay")
