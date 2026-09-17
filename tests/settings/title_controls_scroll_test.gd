extends GdUnitTestSuite
## The Controls page's box on the title, where the strip sits lower than in the waking scene, is framed
## to its own band.

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/title_controls_scroll_none"   # never created

var runner: GdUnitSceneRunner
var screen: TitleScreen
var board: SettingsBoard
var page: ControlsPage
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(640, 360)
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	board = screen.get_node("%SettingsBoard") as SettingsBoard
	page = board.get_node("%ControlsPage") as ControlsPage
	screen.quit_game = func() -> void: pass
	screen.start_new_game = func() -> void: pass
	screen.start_continue = func() -> void: pass
	screen.read_save(NO_SAVE)

func after_test() -> void:
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _size_up(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _open_page() -> void:
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)
	await _press(KEY_UP)   # the board opens on UI size; Up wraps to Controls
	await _press(KEY_ENTER)

func _rect(node: Control) -> Rect2:
	return Rect2(node.position, node.size)

func test_title_largest_is_framed_to_its_own_band() -> void:
	_size_up(2)
	await _open_page()
	for i in 8:
		await _press(KEY_DOWN)
	await _press(KEY_ENTER)
	await get_tree().process_frame
	assert_float(page.strip.screen_top()).is_equal(152.0)
	assert_that(_rect(page.get_node("%Box/Panel") as Control)).is_equal(Rect2(84, 46, 152, 74))
	assert_that(_rect(page.get_node("%Box/Panel/Clip") as Control)).is_equal(Rect2(0, 10, 152, 54))
	assert_that(_rect(page.get_node("%Box/Panel/Clip/Content") as Control)).is_equal(Rect2(0, -8, 152, 124))
	await _press(KEY_RIGHT)   # the bottom button, so the greatest offset this band allows
	assert_int(page._box_offset).is_equal(52)
