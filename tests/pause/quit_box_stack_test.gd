extends GdUnitTestSuite
## The pause Quit box stacks its buttons, left on top, when side by side is wider than the screen.

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

func _rect(unique: String) -> Rect2:
	var n := _node(unique)
	return Rect2(n.position, n.size)

## The rest layout, before framing: the box now scrolls whenever it stacks in the waking scene.
func _panel_rect() -> Rect2:
	return pause._quit_box.panel

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _open_box() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)

func _highlighted(unique: String) -> void:
	assert_bool(is_same(_node(unique).get_theme_stylebox("panel"), Pause.PLANK_HIGHLIGHT_STYLE)) \
		.override_failure_message(unique + " is not highlighted").is_true()

func _assert_normal() -> void:
	assert_that(_panel_rect()).is_equal(Rect2(12, 42, 296, 96))
	assert_that(_rect("FirstLine")).is_equal(Rect2(8, 8, 280, 12))
	assert_that(_rect("SecondLine")).is_equal(Rect2(8, 28, 280, 28))
	assert_that(_rect("Stay")).is_equal(Rect2(40, 66, 104, 20))
	assert_that(_rect("Quit")).is_equal(Rect2(152, 66, 104, 20))

func test_normal_is_todays_layout() -> void:
	await _open_box()
	_assert_normal()

func test_stacks_at_largest() -> void:
	_size_up(2)
	await _open_box()
	assert_that(_panel_rect()).is_equal(Rect2(84, 28, 152, 124))
	assert_that(_rect("FirstLine")).is_equal(Rect2(8, 8, 136, 12))
	assert_that(_rect("SecondLine")).is_equal(Rect2(8, 28, 136, 28))
	assert_that(_rect("Stay")).is_equal(Rect2(24, 66, 104, 20))
	assert_that(_rect("Quit")).is_equal(Rect2(24, 94, 104, 20))
	_highlighted("Stay")
	assert_bool(_node("QuitBox").visible).is_true()
	assert_bool(get_tree().paused).is_true()

func test_stacks_at_large() -> void:
	_size_up(1)
	await _open_box()
	assert_that(_panel_rect()).is_equal(Rect2(58, 28, 204, 124))
	assert_that(_rect("SecondLine")).is_equal(Rect2(8, 28, 188, 28))
	assert_that(_rect("Stay")).is_equal(Rect2(50, 66, 104, 20))
	assert_that(_rect("Quit")).is_equal(Rect2(50, 94, 104, 20))

func test_stacking_while_up_keeps_the_highlight() -> void:
	await _open_box()
	await _tap(KEY_RIGHT)
	_size_up(2)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)
	_highlighted("Quit")
	assert_that(_rect("Quit").position).is_equal(Vector2(24, 94))
	Display.use_prefs(DisplayPrefs.new())
	_assert_normal()
	_highlighted("Quit")

func test_window_resize_refits() -> void:
	_size_up(1)
	await _open_box()
	assert_float(_panel().size.x).is_equal(204.0)
	get_tree().root.size = Vector2i(1280, 720)
	assert_float(_panel().size.x).is_equal(152.0)
	get_tree().root.size = Vector2i(2560, 1440)

func test_second_line_change_refits() -> void:
	_size_up(2)
	await _open_box()
	assert_float(_node("SecondLine").size.y).is_equal(28.0)
	pause.has_saved = func() -> bool: return true
	await _tap(KEY_LEFT)
	assert_str((_node("SecondLine") as Label).text).is_equal("Anything since this morning will be lost.")
	assert_that(_rect("SecondLine")).is_equal(Rect2(8, 28, 136, 30))
	assert_that(_rect("Stay")).is_equal(Rect2(24, 68, 104, 20))
	assert_that(_rect("Quit")).is_equal(Rect2(24, 96, 104, 20))
	assert_that(_panel_rect()).is_equal(Rect2(84, 27, 152, 126))

func test_up_down_do_nothing_side_by_side() -> void:
	await _open_box()
	await _tap(KEY_DOWN)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.STAY)
	assert_bool(_node("QuitBox").visible).is_true()
	await _tap(KEY_RIGHT)
	await _tap(KEY_UP)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)

func test_stacked_buttons_do_not_overlap() -> void:
	_size_up(2)
	await _open_box()
	var stay := _node("Stay").get_global_rect()
	var quit := _node("Quit").get_global_rect()
	var content := (pause.get_node("%QuitBox/Panel/Clip/Content") as Control).get_global_rect()
	assert_bool(stay.intersects(quit)).is_false()
	assert_bool(content.encloses(stay)).is_true()
	assert_bool(content.encloses(quit)).is_true()

func test_select_when_stacked_quits() -> void:
	_size_up(2)
	await _open_box()
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_bool(pause.rules.quitting).is_true()

func test_back_when_stacked_closes_the_box() -> void:
	_size_up(2)
	await _open_box()
	await _tap(KEY_ESCAPE)
	assert_bool(_node("QuitBox").visible).is_false()
	_highlighted("QuitToTitle")
