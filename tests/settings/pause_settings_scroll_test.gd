extends GdUnitTestSuite
## The Settings board opened from pause when its content no longer fits: it is framed above the lifted
## Select / Back strip and scrolls to the highlight.
## In the default 1280x720 window a player reaches it at UI Largest and Text Largest; UI size alone never
## makes the board scroll.

const S := DisplayPrefs.Setting

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var board: SettingsBoard
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Pause.debug_tools = false   # the release board; tests/debug covers the debug one
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	board = pause.get_node("%SettingsBoard")
	pause.quit_to_title = func() -> void: pass
	board.open_controls = func() -> void: pass
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())
	Display.use_prefs(DisplayPrefs.new())

func _control() -> void:
	waking.tick(5.0)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()

func _open_settings() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _settle()

func _grow(ui: int, text: int) -> void:
	Display.prefs.step(S.UI_SIZE, ui)
	Display.prefs.step(S.TEXT_SIZE, text)

# get_global_rect ignores the pause CanvasLayer, so on-screen rectangles come from the canvas transform.
func _screen(unique: String) -> Rect2:
	var c := board.get_node("%" + unique) as Control
	return c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)

func test_largest_pause_board_stays_above_the_lifted_strip() -> void:
	_grow(2, 2)
	await _open_settings()
	assert_bool(board.scrolls).is_true()
	assert_bool(board.scrolls).is_true()
	# Drawn at 2 about the picture's centre, the band's on-screen 2 .. strip - 2 is board y 91 .. 212.
	assert_that((board.get_node("%Panel") as Control).get_rect()).is_equal(Rect2(SettingsBoard.BOARD_X, 91, SettingsBoard.BOARD_W, 121))
	assert_that((board.get_node("%Clip") as Control).get_rect()).is_equal(Rect2(0, ScrollWindow.MARK_ROW, SettingsBoard.BOARD_W, 121 - 2 * ScrollWindow.MARK_ROW))
	assert_int(board.offset).is_equal(0)   # UI size, with the heading, fits the 101-tall clip
	assert_bool(board.shows_mark_above()).is_false()
	assert_bool(board.shows_mark_below()).is_true()
	assert_float(_screen("Panel").position.y).is_equal(2.0)
	assert_float(_screen("Panel").end.y).is_equal(board.strip.screen_top() - 2.0)
	assert_float(board.strip.screen_top()).is_equal(246.0)   # lifted above the item bar, words at Text Largest
	assert_bool(_screen("Clip").encloses(_screen("UiSize"))).is_true()

func test_largest_pause_board_scrolls_to_controls_and_back() -> void:
	_grow(2, 2)
	await _open_settings()
	assert_bool(board.scrolls).is_true()
	# Plank bottoms in the content: 72, 120, 168, 216; Controls with its line under the list spans 220 .. 333, taller than the 101 clip, so its top, 220.
	for step: Array in [[19, "TextSize"], [67, "ColourCues"], [115, "Fullscreen"], [220, "Controls"]]:
		await _tap(KEY_DOWN)
		assert_int(board.offset).override_failure_message("at %s" % step[1]).is_equal(step[0])
		assert_bool(_screen("Clip").encloses(_screen(step[1] as String))) \
			.override_failure_message("%s is not wholly visible" % step[1]).is_true()
	await _tap(KEY_ESCAPE)
	assert_bool(board.visible).is_false()
	await _tap(KEY_ENTER)
	await _settle()
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)
	assert_int(board.offset).is_equal(0)
