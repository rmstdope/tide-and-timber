extends GdUnitTestSuite
## At larger Text size the pause Quit box's words grow; the box widens, then its lines wrap.
## At the default 1280x720 window (k = 2) the box reaches its widest only at UI Largest and Text Largest.

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
	get_tree().root.size = Vector2i(1280, 720)
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

## A panel of that size centred on the picture, as the box lays it out.
func _centred(size: Vector2) -> Rect2:
	return Rect2(((Screen.SIZE - size) / 2.0).floor(), size)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _open_box() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)

func _text_up(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	await await_idle_frame()
	await await_idle_frame()

func _line_count_at_normal() -> int:
	return (_node("SecondLine") as Label).get_line_count()

func test_largest_text_widens_the_box_and_wraps_the_second_line() -> void:
	_size_up(2)
	await _open_box()
	var normal_lines := _line_count_at_normal()
	await _text_up(2)
	var p := _panel_rect()
	assert_float(p.size.x).is_equal(BoxLayout.widest(2.0))
	assert_float(p.position.x).is_equal(Screen.CENTRE.x - BoxLayout.widest(2.0) / 2.0)
	assert_float(p.get_center().x).is_equal(Screen.CENTRE.x)
	assert_float(p.size.y).is_greater(96.0)
	assert_that(_node("FirstLine").scale).is_equal(Vector2(2, 2))
	assert_int((_node("SecondLine") as Label).get_line_count()).is_greater(normal_lines)

func test_text_normal_is_todays_layout() -> void:
	await _open_box()
	assert_that(_panel_rect()).is_equal(_centred(Vector2(296, 96)))
	assert_that(_rect("Stay")).is_equal(Rect2(40, 66, 104, 20))
	assert_that(_node("FirstLine").scale).is_equal(Vector2.ONE)
	assert_that(_node("SecondLine").scale).is_equal(Vector2.ONE)

func test_largest_text_keeps_the_box_on_screen() -> void:
	await _open_box()
	_size_up(2)
	await _text_up(2)
	var panel := _panel()
	var screen := panel.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, panel.size)
	# in the picture's units: the canvas is k = 2 screen pixels to the unit
	assert_float(screen.position.x / 2.0).is_greater_equal(0.0)
	assert_float(screen.end.x / 2.0).is_less_equal(Screen.WIDTH)

func test_left_and_right_still_choose_while_side_by_side() -> void:
	await _open_box()
	await _text_up(1)
	assert_bool(pause._quit_box.stacked).is_false()
	await _tap(KEY_LEFT)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.STAY)
	await _tap(KEY_RIGHT)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)
	await _tap(KEY_UP)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)
	await _tap(KEY_DOWN)
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)

func test_going_back_to_normal_restores_the_box() -> void:
	await _open_box()
	await _text_up(2)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, -1)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, -1)
	await await_idle_frame()
	await await_idle_frame()
	assert_that(_panel_rect()).is_equal(_centred(Vector2(296, 96)))
	assert_that(_node("FirstLine").scale).is_equal(Vector2.ONE)
	assert_that(_node("SecondLine").scale).is_equal(Vector2.ONE)
