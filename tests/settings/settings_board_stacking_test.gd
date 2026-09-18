extends GdUnitTestSuite
## The Settings board at a scale where its rows no longer fit across the screen: every row goes onto two lines
## inside the panel (which narrows to fit when the screen is narrower than it); at a scale where they fit,
## they stay side by side.
## At the default 1280x720 window a player stacks the rows at UI Largest and Text Largest, the one
## combination that does; UI Largest and Text Large is the step below, where they stay side by side.

const TITLE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/stacking_none"   # never created
const S := DisplayPrefs.Setting
const PLANKS := ["UiSize", "TextSize", "ColourCues", "Controls"]

var runner: GdUnitSceneRunner
var screen: TitleScreen
var board: SettingsBoard
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())

func _title() -> void:
	runner = scene_runner(TITLE)
	screen = runner.scene() as TitleScreen
	board = screen.get_node("%SettingsBoard") as SettingsBoard
	screen.quit_game = func() -> void: pass
	screen.start_new_game = func() -> void: pass
	screen.start_continue = func() -> void: pass
	board.open_controls = func() -> void: pass
	screen.read_save(NO_SAVE)

func _tap(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()

func _open() -> void:
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _settle()

func _grow(ui: int, text: int) -> void:
	Display.prefs.step(S.UI_SIZE, ui)
	Display.prefs.step(S.TEXT_SIZE, text)

func _node(path: String) -> Control:
	return board.get_node("%" + path) as Control

func _click(control: Control) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	control.gui_input.emit(click)

func _planks_at(step: float, rect_of: Callable) -> void:
	for i in PLANKS.size():
		assert_that(_node(PLANKS[i]).get_rect()).override_failure_message("plank %d" % i) \
			.is_equal(rect_of.call(i))

# --- pure ---

func test_panel_width_follows_the_scale() -> void:
	assert_float(SettingsBoard.panel_width(2.0)).is_equal(304.0)
	assert_float(SettingsBoard.panel_width(3.0)).is_equal(209.0)   # floor(640 / 3 - 4)
	assert_float(SettingsBoard.panel_width(4.0)).is_equal(156.0)   # 640 / 4 - 4

func test_stacks_only_when_too_wide() -> void:
	# (widest + 12) * s against the 640-wide picture
	assert_bool(SettingsBoard.stacks(200, 2.0)).is_false()
	assert_bool(SettingsBoard.stacks(200, 3.0)).is_false()
	assert_bool(SettingsBoard.stacks(200, 4.0)).is_true()
	assert_bool(SettingsBoard.stacks(220, 3.0)).is_true()

func test_line_count_matches_the_label() -> void:
	var font: Font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	var ui: String = SettingsBoard.LINES[SettingsMenu.Plank.UI_SIZE]
	assert_int(SettingsBoard.line_count(ui, 280, font, 8)).is_equal(2)
	assert_int(SettingsBoard.line_count(ui, 132, font, 8)).is_equal(4)
	assert_int(SettingsBoard.line_count(ui, 185, font, 8)).is_equal(3)
	assert_int(SettingsBoard.line_count(SettingsBoard.LINES[SettingsMenu.Plank.TEXT_SIZE], 280, font, 8)).is_equal(1)
	assert_int(SettingsBoard.line_count(SettingsBoard.LINES[SettingsMenu.Plank.COLOUR_CUES], 185, font, 8)).is_equal(3)

# --- the title ---

func _centred(h: float) -> Rect2:
	return Rect2(SettingsBoard.BOARD_X, floorf((Screen.HEIGHT - h) / 2.0), SettingsBoard.BOARD_W, h)

func _plank_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for name: String in PLANKS:
		rects.append(_node(name).get_rect())
	return rects

func test_normal_layout_is_unchanged() -> void:
	_title()
	await _open()
	assert_bool(board.stacked).is_false()
	assert_that(_node("Panel").get_rect()).is_equal(_centred(SettingsBoard.BOARD_H))
	_planks_at(20, func(i: int) -> Rect2: return Rect2(52, 28 + 20 * i, 200, 16))
	assert_that(_node("UiSize/Row/Value").get_rect()).is_equal(Rect2(120, 0, 64, 12))
	assert_that(_node("Controls/Row/Arrow").get_rect()).is_equal(Rect2(184, 0, 12, 12))
	assert_that(_node("Line").position).is_equal(Vector2(12, 112))
	assert_float(_node("Line").size.x).is_equal(280.0)

func test_title_board_stacks_at_largest_inside_the_screen() -> void:
	_grow(2, 2)
	_title()
	await _open()
	assert_bool(board.stacked).is_true()
	# Text Largest draws the words at 2: the first plank moves down by the heading's growth (8), and each plank is
	# 44 tall (two 20-tall lines of cells and the plank's 4) with the 4 gap below it.
	var top := SettingsBoard.PLANK_TOP + 8.0
	assert_that(board.rest_panel).is_equal(_centred(top + 3 * 48 + 44 + SettingsBoard.LINE_GAP + 56 + SettingsBoard.BOTTOM_MARGIN))   # the line: 3 lines (28) drawn at 2
	var w := SettingsBoard.BOARD_W - 2.0 * SettingsBoard.PANEL_SIDE   # a stacked plank spans the panel
	_planks_at(48, func(i: int) -> Rect2: return Rect2(SettingsBoard.PANEL_SIDE, top + 48 * i, w, 44))
	assert_float(_node("UiSize/Row/Label").get_rect().position.y).is_equal(0.0)
	assert_float(_node("UiSize/Row/Value").get_rect().position.y).is_greater(0.0)   # on the line below the name
	assert_that(_node("UiSize/Row/Value").get_rect()).is_equal(Rect2(82, 20, 128, 20))   # the second line, centred between the arrows
	assert_that(_node("Controls/Row/Arrow").get_rect()).is_equal(Rect2(w - 4.0 - 24.0, 0, 24, 20))   # › flush with the plank's inner right edge
	assert_that(_node("Line").position).is_equal(Vector2(SettingsBoard.LINE_SIDE, top + 3 * 48 + 44 + SettingsBoard.LINE_GAP))
	assert_float(_node("Line").size.x * _node("Line").scale.x).is_equal(SettingsBoard.BOARD_W - 2.0 * SettingsBoard.LINE_SIDE)
	var r := _node("Panel").get_global_rect()
	assert_float(r.position.x).is_greater_equal(0.0)
	assert_float(r.end.x).is_less_equal(Screen.WIDTH)
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)
	assert_bool(is_same(_node("UiSize").get_theme_stylebox("panel"), SettingsBoard.PLANK_HIGHLIGHT_STYLE)).is_true()

func test_large_in_a_big_window_stays_side_by_side() -> void:
	_grow(2, 1)
	_title()
	await _open()
	assert_bool(board.stacked).is_false()
	assert_that(board.rest_panel).is_equal(_centred(182))   # 32 + 3 * 24 + 20, the line's gap, 28 and margin
	var widest := board.side_by_side_width()
	# Text Large: words at 1.5, the heading 4 taller, planks 20 tall on a 24 step.
	var top := SettingsBoard.PLANK_TOP + 4.0
	_planks_at(24, func(i: int) -> Rect2: return Rect2(floorf((SettingsBoard.BOARD_W - widest) / 2.0), top + 24 * i, widest, 20))
	var r := _node("Panel").get_global_rect()
	assert_float(r.position.x).is_greater_equal(0.0)
	assert_float(r.end.x).is_less_equal(Screen.WIDTH)

func test_changing_size_on_the_board_stacks_and_unstacks_with_the_highlight_unmoved() -> void:
	_grow(0, 2)
	_title()
	await _open()
	assert_bool(board.stacked).is_false()
	var before := _plank_rects()
	await _tap(KEY_RIGHT)
	await _tap(KEY_RIGHT)
	await _settle()
	assert_bool(board.stacked).is_true()
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)
	await _tap(KEY_LEFT)
	await _tap(KEY_LEFT)
	await _settle()
	assert_bool(board.stacked).is_false()
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)
	assert_array(_plank_rects()).is_equal(before)

func test_a_window_resize_restacks() -> void:
	# UNREACHED at 640x360 (navigator decision, tr-1o0.1): UI Large draws at 1.5 in the 1280x720 window (k 2)
	# and rounds up to 2 at 640x360 (k 1), the only window resize that changes the drawn scale, yet with
	# Text Largest the rows still fit there. No UI / Text combination stacks in one window and not another.
	_grow(1, 2)
	_title()
	await _open()
	assert_bool(board.stacked).is_false()
	get_tree().root.size = Vector2i(640, 360)
	await _settle()
	assert_bool(board.stacked).is_true()
	get_tree().root.size = Vector2i(1280, 720)
	await _settle()
	assert_bool(board.stacked).is_false()

func test_clicking_a_stacked_arrow_steps_the_value() -> void:
	_grow(2, 2)
	_title()
	await _open()
	assert_bool(board.stacked).is_true()
	_click(_node("TextSize/Row/Prev"))
	assert_int(Display.prefs.text_size).is_equal(DisplayPrefs.Size.LARGE)
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.TEXT_SIZE)
	assert_str((_node("TextSize/Row/Value/Words") as Label).text).is_equal("Large")

# --- pause ---

func test_pause_board_stacks_at_largest_inside_the_screen() -> void:
	_grow(2, 2)
	Pause.debug_tools = false
	runner = scene_runner("res://src/waking/waking.tscn")
	var waking := runner.scene() as Waking
	waking.set_process(false)
	var pause: Pause = waking.get_node("%Pause")
	board = pause.get_node("%SettingsBoard")
	pause.quit_to_title = func() -> void: pass
	board.open_controls = func() -> void: pass
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _settle()
	assert_bool(board.stacked).is_true()
	var panel := _node("Panel")
	assert_float((panel.get_global_transform_with_canvas() * Vector2.ZERO).x).is_greater_equal(0.0)
	assert_float((panel.get_global_transform_with_canvas() * Vector2(panel.size.x, 0)).x).is_less_equal(Screen.WIDTH)
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
