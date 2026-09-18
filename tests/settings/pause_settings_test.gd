extends GdUnitTestSuite
## The Settings board opened from the Paused board: over the frozen game, Back returns, Start resumes.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var board: SettingsBoard
var calls: Array[String] = []
var resumed := 0

func before_test() -> void:
	Pause.debug_tools = false   # the release board; tests/debug covers the debug one
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	calls = []
	resumed = 0
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	board = pause.get_node("%SettingsBoard")
	var recorded := calls
	pause.quit_to_title = func() -> void: recorded.append("title")
	board.open_controls = func() -> void: recorded.append("controls")
	pause.resumed.connect(func() -> void: resumed += 1)
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
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

func _pad(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = button
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func _pause_node(unique: String) -> Control:
	return pause.get_node("%" + unique) as Control

func _board_node(unique: String) -> Control:
	return board.get_node("%" + unique) as Control

func _is_highlighted(plank: Control) -> bool:
	return is_same(plank.get_theme_stylebox("panel"), Pause.PLANK_HIGHLIGHT_STYLE)

func _row_highlighted(unique: String) -> void:
	assert_bool(_is_highlighted(_board_node(unique))).override_failure_message("%s is not highlighted" % unique).is_true()

func _open_settings() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)

func _assert_back_on_the_paused_board() -> void:
	assert_bool(board.visible).is_false()
	assert_bool(_pause_node("Board").visible).is_true()
	assert_bool(_is_highlighted(_pause_node("Settings"))).override_failure_message("Settings is not highlighted").is_true()
	assert_bool(get_tree().paused).is_true()
	await _tap(KEY_DOWN)
	assert_bool(_is_highlighted(_pause_node("QuitToTitle"))).override_failure_message("board takes no input").is_true()

func test_settings_opens_the_board_over_the_frozen_game() -> void:
	await _open_settings()
	assert_bool(get_tree().paused).is_true()
	assert_bool(board.visible).is_true()
	assert_bool(_pause_node("Board").visible).is_false()
	assert_str((board.get_node("%Heading") as Label).text).is_equal("Settings")
	assert_str((_board_node("Controls").get_node("Row/Label/Words") as Label).text).is_equal("Controls")
	assert_bool(is_same(_board_node("UiSize").get_theme_stylebox("panel"), SettingsBoard.PLANK_HIGHLIGHT_STYLE)).is_true()
	assert_that(_board_node("Panel").get_rect()).is_equal(Rect2(8, 21, 304, 138))
	assert_str(board.strip.text()).is_equal("[Enter] Select   [Esc] Back")

func test_board_fits_and_the_strip_clears_it() -> void:
	await _open_settings()
	var panel := _board_node("Panel").get_global_rect()
	assert_bool(Rect2(0, 0, 320, 180).encloses(panel)).is_true()
	assert_bool(panel.intersects(board.strip.get_global_rect())).is_false()

func test_up_and_down_move_between_rows() -> void:
	await _open_settings()
	await _tap(KEY_DOWN)
	_row_highlighted("TextSize")
	await _tap(KEY_UP)
	_row_highlighted("UiSize")
	await _tap(KEY_UP)
	_row_highlighted("Controls")

func test_esc_returns_to_the_paused_board_on_settings() -> void:
	await _open_settings()
	await _tap(KEY_ESCAPE)
	await _assert_back_on_the_paused_board()

func test_b_returns_too() -> void:
	await _open_settings()
	await _pad(JOY_BUTTON_B)
	await _assert_back_on_the_paused_board()

func test_start_resumes_play_at_once() -> void:
	await _open_settings()
	await _pad(JOY_BUTTON_START)
	assert_bool(get_tree().paused).is_false()
	assert_bool(board.visible).is_false()
	assert_bool(_pause_node("Board").visible).is_false()
	assert_bool(pause.rules.is_open).is_false()
	assert_int(resumed).is_equal(1)

func test_esc_is_back_not_resume() -> void:
	await _open_settings()
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_true()
	assert_int(resumed).is_equal(0)
	assert_bool(_pause_node("Board").visible).is_true()

func test_enter_on_controls_calls_the_seam_and_stays() -> void:
	await _open_settings()
	await _tap(KEY_UP)
	assert_array(calls).is_empty()
	await _tap(KEY_ENTER)
	assert_array(calls).is_equal(["controls"])
	assert_bool(board.visible).is_true()
	assert_bool(get_tree().paused).is_true()

func test_mouse_hovers_and_clicks_controls() -> void:
	await _open_settings()
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(1, 0)
	_board_node("Controls").gui_input.emit(move)
	_row_highlighted("Controls")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	_board_node("Controls").gui_input.emit(right)
	assert_array(calls).is_empty()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_board_node("Controls").gui_input.emit(click)
	assert_array(calls).is_equal(["controls"])

func test_losing_focus_changes_nothing() -> void:
	await _open_settings()
	pause._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_bool(board.visible).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_bool(_pause_node("Board").visible).is_false()

func test_reopening_after_start_opens_on_resume() -> void:
	await _open_settings()
	await _pad(JOY_BUTTON_START)
	_control()
	await _tap(KEY_ESCAPE)
	assert_bool(_pause_node("Board").visible).is_true()
	assert_bool(_is_highlighted(_pause_node("Resume"))).is_true()
	assert_bool(board.visible).is_false()

func test_changes_from_pause_are_kept_and_play_stays_paused() -> void:
	await _open_settings()
	await _tap(KEY_RIGHT)
	assert_int(Display.prefs.ui_size).is_equal(DisplayPrefs.Size.LARGE)
	assert_bool(get_tree().paused).is_true()
	await _tap(KEY_ESCAPE)
	assert_bool(_pause_node("Board").visible).is_true()
	assert_bool(_is_highlighted(_pause_node("Settings"))).is_true()
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()
	assert_int(Display.prefs.ui_size).is_equal(DisplayPrefs.Size.LARGE)
