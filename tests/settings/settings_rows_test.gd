extends GdUnitTestSuite
## The Settings board's value rows, from the title: their words, the line under the list, stepping by key, pad,
## stick and mouse, dimmed ends, and values that stay.

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/rows_none"   # never created
const S := DisplayPrefs.Setting
const ROWS := ["UiSize", "TextSize", "ColourCues", "Controls"]
const LINE_UI := "Makes the clock, item bar, hints and menus bigger."

var runner: GdUnitSceneRunner
var screen: TitleScreen
var board: SettingsBoard

func before_test() -> void:
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	board = screen.get_node("%SettingsBoard") as SettingsBoard
	screen.quit_game = func() -> void: pass
	screen.start_new_game = func() -> void: pass
	screen.start_continue = func() -> void: pass
	board.open_controls = func() -> void: pass
	screen.read_save(NO_SAVE)

func after_test() -> void:
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())

func _tap(key: Key) -> void:
	runner.simulate_key_pressed(key)
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

func _stick(v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = JOY_AXIS_LEFT_X
	e.axis_value = v
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func _click(control: Control) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	control.gui_input.emit(click)

func _open() -> void:
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)

func _row(unique: String) -> Control:
	return board.get_node("%" + unique) as Control

func _text(path: String) -> String:
	return (board.get_node("%" + path) as Label).text

func _colour(path: String) -> Color:
	return (board.get_node("%" + path) as Label).get_theme_color("font_color")

func _highlighted(unique: String) -> void:
	for r: String in ROWS:
		var want := SettingsBoard.PLANK_HIGHLIGHT_STYLE if r == unique else SettingsBoard.PLANK_STYLE
		assert_bool(is_same(_row(r).get_theme_stylebox("panel"), want)) \
			.override_failure_message("%s highlight wrong (want %s)" % [r, unique]).is_true()

func _values() -> Array[String]:
	return [_text("UiSize/Row/Value"), _text("TextSize/Row/Value"), _text("ColourCues/Row/Value")]

func test_four_rows_in_order_with_their_words() -> void:
	await _open()
	assert_str((board.get_node("%Heading") as Label).text).is_equal("Settings")
	assert_str(_text("UiSize/Row/Label")).is_equal("UI size")
	assert_str(_text("TextSize/Row/Label")).is_equal("Text size")
	assert_str(_text("ColourCues/Row/Label")).is_equal("Colour cues")
	assert_str(_text("Controls/Row/Label")).is_equal("Controls")
	for i in ROWS.size() - 1:
		assert_float(_row(ROWS[i]).position.y).is_less(_row(ROWS[i + 1]).position.y)
	assert_str(_text("Controls/Row/Arrow")).is_equal("›")
	for r: String in ["UiSize", "TextSize", "ColourCues"]:
		assert_str(_text(r + "/Row/Prev")).is_equal("◀")
		assert_str(_text(r + "/Row/Next")).is_equal("▶")

func test_opens_on_ui_size_with_its_line() -> void:
	await _open()
	_highlighted("UiSize")
	assert_str(_text("Line")).is_equal(LINE_UI)
	assert_array(_values()).is_equal(["Normal", "Normal", "Standard"])

func test_the_line_follows_the_highlight() -> void:
	await _open()
	await _tap(KEY_DOWN)
	assert_str(_text("Line")).is_equal("Makes every word bigger.")
	await _tap(KEY_DOWN)
	assert_str(_text("Line")).is_equal("Adds shapes to warnings shown in colour.")
	await _tap(KEY_DOWN)
	assert_str(_text("Line")).is_equal("Change any key or controller button.")
	await _tap(KEY_DOWN)
	assert_str(_text("Line")).is_equal(LINE_UI)

func test_board_geometry() -> void:
	await _open()
	var panel := board.get_node("%Panel") as Control
	assert_that(panel.get_rect()).is_equal(Rect2(8, 21, 304, 138))
	for r: String in ROWS:
		assert_that(_row(r).size).is_equal(Vector2(200, 16))
		assert_float(_row(r).position.x).is_equal(52.0)
	for i in ROWS.size():
		await await_idle_frame()
		var line := board.get_node("%Line") as Label
		assert_int(line.get_line_count()).override_failure_message("%s wraps too far" % line.text).is_less_equal(2)
		await _tap(KEY_DOWN)
	var rect := panel.get_global_rect()
	assert_bool(Rect2(0, 0, 320, 180).encloses(rect)).is_true()
	assert_bool(rect.intersects(board.strip.get_global_rect())).is_false()

func test_right_steps_and_stops_at_the_end() -> void:
	await _open()
	await _tap(KEY_RIGHT)
	assert_str(_text("UiSize/Row/Value")).is_equal("Large")
	assert_int(Display.prefs.ui_size).is_equal(DisplayPrefs.Size.LARGE)
	await _tap(KEY_RIGHT)
	assert_str(_text("UiSize/Row/Value")).is_equal("Largest")
	await _tap(KEY_RIGHT)
	assert_str(_text("UiSize/Row/Value")).is_equal("Largest")
	assert_that(_colour("UiSize/Row/Next")).is_equal(SettingsBoard.ARROW_DIM)
	assert_that(_colour("UiSize/Row/Prev")).is_equal(SettingsBoard.TEXT)

func test_left_at_the_start_does_nothing_and_the_arrow_is_dim() -> void:
	await _open()
	await _tap(KEY_LEFT)
	assert_str(_text("UiSize/Row/Value")).is_equal("Normal")
	assert_dict(Display.prefs.to_dict()).is_equal(DisplayPrefs.new().to_dict())
	assert_that(_colour("UiSize/Row/Prev")).is_equal(SettingsBoard.ARROW_DIM)
	assert_that(_colour("UiSize/Row/Next")).is_equal(SettingsBoard.TEXT)

func test_d_and_a_step_too() -> void:
	await _open()
	await _tap(KEY_DOWN)
	await _tap(KEY_D)
	assert_str(_text("TextSize/Row/Value")).is_equal("Large")
	await _tap(KEY_A)
	assert_str(_text("TextSize/Row/Value")).is_equal("Normal")

func test_pad_d_pad_and_stick_step_once_per_push() -> void:
	await _open()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	assert_str(_text("ColourCues/Row/Value")).is_equal("Shapes")
	assert_that(_colour("ColourCues/Row/Prev")).is_equal(SettingsBoard.TEXT)
	assert_that(_colour("ColourCues/Row/Next")).is_equal(SettingsBoard.ARROW_DIM)
	await _pad(JOY_BUTTON_DPAD_LEFT)
	assert_str(_text("ColourCues/Row/Value")).is_equal("Standard")
	await _stick(0.9)
	assert_str(_text("ColourCues/Row/Value")).is_equal("Shapes")
	await _stick(0.95)
	assert_str(_text("ColourCues/Row/Value")).is_equal("Shapes")
	await _stick(0.0)
	await _stick(-0.9)
	await _stick(-0.95)
	assert_str(_text("ColourCues/Row/Value")).is_equal("Standard")
	await _stick(0.0)
	await _tap(KEY_UP)
	await _tap(KEY_UP)
	await _stick(0.9)
	await _stick(0.95)
	assert_str(_text("UiSize/Row/Value")).is_equal("Large")
	await _stick(0.0)

func test_enter_on_a_value_row_does_nothing() -> void:
	await _open()
	await _tap(KEY_ENTER)
	assert_array(_values()).is_equal(["Normal", "Normal", "Standard"])
	_highlighted("UiSize")
	assert_bool(board.visible).is_true()

func test_left_right_on_controls_do_nothing() -> void:
	await _open()
	await _tap(KEY_UP)
	await _tap(KEY_RIGHT)
	await _tap(KEY_LEFT)
	assert_array(_values()).is_equal(["Normal", "Normal", "Standard"])
	_highlighted("Controls")

func test_clicking_arrows_steps_and_highlights() -> void:
	await _open()
	_click(board.get_node("%TextSize/Row/Next") as Control)
	_highlighted("TextSize")
	assert_str(_text("TextSize/Row/Value")).is_equal("Large")
	_click(board.get_node("%TextSize/Row/Prev") as Control)
	assert_str(_text("TextSize/Row/Value")).is_equal("Normal")
	_click(board.get_node("%TextSize/Row/Prev") as Control)
	assert_str(_text("TextSize/Row/Value")).is_equal("Normal")

func test_clicking_a_value_row_highlights_it_only() -> void:
	await _open()
	_click(_row("ColourCues"))
	_highlighted("ColourCues")
	assert_str(_text("ColourCues/Row/Value")).is_equal("Standard")

func test_hovering_an_arrow_highlights_its_row() -> void:
	await _open()
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(1, 0)
	(board.get_node("%ColourCues/Row/Next") as Control).gui_input.emit(move)
	_highlighted("ColourCues")
	assert_str(_text("ColourCues/Row/Value")).is_equal("Standard")

func test_a_change_from_elsewhere_redraws() -> void:
	await _open()
	Display.prefs.step(S.CUES, 1)
	assert_str(_text("ColourCues/Row/Value")).is_equal("Shapes")

func test_values_survive_back_and_reopen() -> void:
	await _open()
	await _tap(KEY_RIGHT)
	await _tap(KEY_ESCAPE)
	assert_bool(board.visible).is_false()
	await _tap(KEY_ENTER)
	assert_bool(board.visible).is_true()
	assert_str(_text("UiSize/Row/Value")).is_equal("Large")
	_highlighted("UiSize")

func test_board_shows_the_prefs_it_opens_with() -> void:
	var p := DisplayPrefs.new()
	p.step(S.TEXT_SIZE, 2)
	p.step(S.CUES, 1)
	Display.use_prefs(p)
	await _open()
	assert_array(_values()).is_equal(["Normal", "Largest", "Shapes"])
	assert_that(_colour("TextSize/Row/Next")).is_equal(SettingsBoard.ARROW_DIM)
	assert_that(_colour("ColourCues/Row/Next")).is_equal(SettingsBoard.ARROW_DIM)
