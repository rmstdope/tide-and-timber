extends GdUnitTestSuite
## The open waiting box follows Text size, UI size and the window, without being reopened.

const A := Controls.Action
const D := Controls.Device
const S := DisplayPrefs.Setting

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
	pause.quit_to_title = func() -> void: pass
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK
	page.pad_connected = func() -> bool: return true

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _box() -> WaitingBox:
	return page.get_node("%WaitingBox") as WaitingBox

func _open_box() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_UP)   # the board opens on UI size; Up wraps to Controls
	await _tap(KEY_ENTER)
	for i in 5:
		await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	assert_bool(_box().visible).is_true()

func _size(setting: DisplayPrefs.Setting, steps: int) -> void:
	for i in absi(steps):
		Display.prefs.step(setting, signi(steps))

func test_text_size_change_regrows_the_open_box() -> void:
	await _open_box()
	var was := _box().layout.panel.size
	_size(S.TEXT_SIZE, 1)
	assert_float(_box().layout.rel).is_greater(1.0)
	assert_float(_box().layout.panel.size.x).is_greater(was.x)
	_size(S.TEXT_SIZE, -1)
	assert_float(_box().layout.rel).is_equal(1.0)
	assert_vector(_box().layout.panel.size).is_equal(was)

func test_ui_size_change_refits_the_open_box() -> void:
	await _open_box()
	_size(S.UI_SIZE, 2)
	assert_float(_box().layout.panel.size.x).is_equal(156.0)
	assert_float(_box().layout.panel.size.x * UiScale.current(Display.prefs, get_tree().root)) \
		.is_less_equal(320.0)

func test_the_ring_moves_with_the_words() -> void:
	await _open_box()
	_box().set_progress(0.5)
	var was := _box().ring.position
	_size(S.TEXT_SIZE, 1)
	assert_vector(_box().ring.position).is_equal(_box().layout.ring)
	assert_vector(_box().ring.position).is_not_equal(was)
	assert_bool(_box().ring.visible).is_true()
	assert_vector(_box().ring.scale).is_equal(Vector2.ONE)

func test_a_window_resize_refits_the_box() -> void:
	await _open_box()
	_size(S.TEXT_SIZE, 2)
	get_tree().root.size = Vector2i(640, 360)
	await await_idle_frame()
	assert_float(_box().layout.panel.size.y * UiScale.current(Display.prefs, get_tree().root)) \
		.is_less_equal(172.0)

func test_normal_text_draws_as_before() -> void:
	await _open_box()
	assert_that(_box().layout.panel).is_equal(WaitingBox.PANEL)
	assert_float(_box().ring.position.y).is_equal(96.0)
