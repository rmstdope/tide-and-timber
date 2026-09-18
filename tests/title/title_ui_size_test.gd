extends GdUnitTestSuite
## UI size on the title screen: the menu, the boxes and the Settings board grow; the picture does not.

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/title_none"   # never created
const EPS := Vector2(0.01, 0.01)

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var runner: GdUnitSceneRunner
var screen: TitleScreen
var board: SettingsBoard
var calls: Array[String] = []

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode

func _open() -> void:
	calls = []
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	screen.set_process(false)
	board = screen.get_node("%SettingsBoard") as SettingsBoard
	var recorded := calls
	screen.quit_game = func() -> void: recorded.append("quit")
	screen.start_new_game = func() -> void: recorded.append("new_game")
	screen.start_continue = func() -> void: recorded.append("continue")
	board.open_controls = func() -> void: recorded.append("controls")
	screen.read_save(NO_SAVE)

func _step(times: int) -> void:
	for i in times:
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_menu_top_at_normal_is_unchanged() -> void:
	assert_float(TitleScreen.menu_top_at(97, 60, 1.0)).is_equal(97.0)
	assert_float(TitleScreen.menu_top_at(83, 81, 1.0)).is_equal(83.0)
	assert_float(TitleScreen.menu_top_at(75, 92, 1.0)).is_equal(75.0)

func test_menu_top_at_keeps_clear_of_the_strip() -> void:
	# A strip high enough to reach the grown menu (158 and 152: a strip at s 1.5 and 2 on a 180-high picture).
	assert_float(TitleScreen.menu_top_at(97, 60, 1.5, -1.0, 158)).is_equal(66.0)
	assert_float(TitleScreen.menu_top_at(97, 60, 2.0, -1.0, 152)).is_equal(30.0)
	assert_float(TitleScreen.menu_top_at(83, 81, 1.5, -1.0, 158)).is_equal(34.0)
	assert_float(TitleScreen.menu_top_at(83, 81, 2.0, -1.0, 152)).is_equal(0.0)
	# On today's picture the default strip sits low enough that Largest only grows the menu about its centre:
	# 194 + 60 / 2 - 60 * 2 / 2 = 164, and its bottom 284 stays clear of the strip.
	assert_float(TitleScreen.menu_top_at(TitleScreen.MENU_TOP, 60, 2.0)).is_equal(TitleScreen.MENU_TOP - 30.0)

func test_menu_top_at_a_grown_menu_at_normal_ui() -> void:
	assert_float(TitleScreen.menu_top_at(83, 104, 1.0, 81, 164)).is_equal(58.0)
	assert_float(TitleScreen.menu_top_at(83, 81, 1.0, 81, 164)).is_equal(83.0)
	assert_float(TitleScreen.menu_top_at(75, 154, 1.0, 92, 164)).is_equal(8.0)
	assert_float(TitleScreen.menu_top_at(97, 60, 1.5, 60, 158)).is_equal(66.0)

func test_menu_grows_centred_and_clear_of_the_strip() -> void:
	_open()
	_step(2)
	await get_tree().process_frame
	var menu := screen.get_node("%Menu") as Control
	assert_vector(menu.scale).is_equal(Vector2(2, 2))
	assert_float(menu.position.x).is_equal(-Screen.CENTRE.x)
	assert_float(menu.get_global_rect().get_center().x).is_equal_approx(Screen.CENTRE.x, 0.01)
	assert_float(menu.get_global_rect().end.y).is_less_equal(screen.strip.get_global_rect().position.y - 2)

func test_boxes_and_board_grow_about_the_centre() -> void:
	_open()
	_step(2)
	await get_tree().process_frame   # the boxes are framed once the strip's own deferred layout has run
	for unique: String in ["StartOverBox", "ReplaceBox"]:   # framed to the room above the strip
		var c := screen.get_node("%" + unique) as Control
		assert_vector(c.scale).is_equal(Vector2(2, 2))
		assert_vector(c.position + c.pivot_offset).is_equal(Screen.CENTRE)
		# The strip no longer reaches a box at Largest on a 640x360 picture, so the room is the whole picture.
		assert_vector(c.get_global_rect().get_center()).is_equal_approx(Screen.CENTRE, EPS)
	var settings := screen.get_node("%SettingsBoard") as Control
	assert_vector(settings.scale).is_equal(Vector2(2, 2))
	assert_vector(settings.get_global_rect().get_center()).is_equal_approx(Screen.CENTRE, EPS)
	assert_vector((screen.get_node("%Version") as Control).scale).is_equal(Vector2.ONE)
	assert_vector((screen.get_node("Title") as Control).scale).is_equal(Vector2.ONE)

func test_back_to_normal_puts_the_title_back() -> void:
	_open()
	_step(2)
	await get_tree().process_frame
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	var menu := screen.get_node("%Menu") as Control
	assert_vector(menu.position).is_equal(Vector2(0, TitleScreen.MENU_TOP))
	assert_vector(menu.scale).is_equal(Vector2.ONE)
	assert_vector(board.scale).is_equal(Vector2.ONE)
	assert_vector(screen.strip.position).is_equal(Vector2(4, Screen.HEIGHT - 16))

func test_title_board_grows_while_ui_size_changes_and_keeps_the_highlight() -> void:
	_open()
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_RIGHT)
	assert_vector(board.scale).is_equal(Vector2(1.5, 1.5))
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)
	assert_bool(board.visible).is_true()
	assert_bool(screen.menu.settings_open).is_true()
	await get_tree().process_frame
	assert_vector(board.strip.get_global_transform_with_canvas().origin).is_equal_approx(Vector2(4, Screen.HEIGHT - 22), EPS)

func test_launched_at_largest_the_board_strip_is_in_the_corner() -> void:
	_step(2)
	_open()
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await get_tree().process_frame
	assert_vector(board.strip.get_global_transform_with_canvas().origin).is_equal_approx(Vector2(4, Screen.HEIGHT - 28), EPS)
	assert_vector(board.strip.get_global_transform_with_canvas().get_scale()).is_equal_approx(Vector2(2, 2), EPS)

func test_a_window_resize_regrows_the_title() -> void:
	_step(1)
	_open()
	get_tree().root.size = Vector2i(1920, 1080)
	await get_tree().process_frame
	assert_vector(board.scale).is_equal_approx(Vector2(5.0 / 3.0, 5.0 / 3.0), EPS)
	assert_vector((screen.get_node("%Menu") as Control).scale).is_equal_approx(Vector2(5.0 / 3.0, 5.0 / 3.0), EPS)
