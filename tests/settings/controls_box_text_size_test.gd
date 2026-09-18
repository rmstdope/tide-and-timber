extends GdUnitTestSuite
## At larger Text size the Controls page box grows its words and widens; OK alone stays centred.

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
	get_tree().root.size = Vector2i(640, 360)
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

func _text_up(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	await await_idle_frame()
	await await_idle_frame()

func test_largest_text_widens_the_box() -> void:
	await _open_reset()
	await _text_up(2)
	assert_float(_panel_rect().size.x).is_equal(312.0)
	assert_that(_box_node("Lines").scale).is_equal(Vector2(2, 2))

func test_ok_alone_stays_centred() -> void:
	await _open_no_pad()
	await _text_up(2)
	assert_bool(_box_node("Other").visible).is_false()
	var panel := _panel_rect()
	assert_float(_rect("Safe").position.x).is_equal(roundf((panel.size.x - _rect("Safe").size.x) / 2.0))

func test_the_box_words_still_read_the_same() -> void:
	await _open_reset()
	await _text_up(2)
	assert_str(_box_label("Safe")).is_equal("Keep mine")

func test_the_no_pad_box_words_still_read_the_same() -> void:
	await _open_no_pad()
	await _text_up(2)
	assert_str(_box_label("Safe")).is_equal("OK")
