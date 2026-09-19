extends GdUnitTestSuite
## The Settings board at a larger Text size: the heading, the row names, ◀ value ▶, › and the line under
## the list grow; planks widen and grow taller to fit, and a stacked row's cells flow onto further lines.
## At the default 1280x720 window the rows stack only at UI Largest and Text Largest, so that is where the
## stacked test runs.

const TITLE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/text_size_none"   # never created
const S := DisplayPrefs.Setting
const PLANKS := ["UiSize", "TextSize", "ColourCues", "Fullscreen", "Controls"]

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
	_title()
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _settle()

func _node(path: String) -> Control:
	return board.get_node("%" + path) as Control

# --- pure ---

func test_flow_height() -> void:
	assert_float(SettingsBoard.flow_height(
		[Vector2(4, 12), Vector2(56, 12), Vector2(12, 12), Vector2(64, 12), Vector2(12, 12)], 196)).is_equal(12.0)
	assert_float(SettingsBoard.flow_height(
		[Vector2(4, 12), Vector2(140, 12), Vector2(12, 12), Vector2(64, 12), Vector2(12, 12)], 144)).is_equal(24.0)
	assert_float(SettingsBoard.flow_height(
		[Vector2(4, 12), Vector2(140, 42), Vector2(24, 20), Vector2(128, 20), Vector2(24, 20)], 144)).is_equal(102.0)
	assert_float(SettingsBoard.flow_height([], 100)).is_equal(0.0)

# --- on the board ---

func test_large_text_rows_grow_side_by_side() -> void:
	Display.prefs.step(S.TEXT_SIZE, 1)
	await _open()
	assert_bool(board.stacked).is_false()
	assert_that(_node("UiSize").get_rect()).is_equal(Rect2(20, 32, 272, 20))
	assert_that(_node("ColourCues").get_rect()).is_equal(Rect2(20, 80, 272, 20))
	assert_that(_node("Fullscreen").get_rect()).is_equal(Rect2(20, 104, 272, 20))
	assert_that(_node("Controls").get_rect()).is_equal(Rect2(20, 128, 272, 20))
	assert_vector(_node("UiSize").get_node("Row/Value").get_combined_minimum_size()).is_equal(Vector2(96, 16))
	assert_vector(_node("Heading").scale).is_equal(Vector2(1.5, 1.5))
	var line := _node("Line")
	assert_vector(line.scale).is_equal(Vector2(1.5, 1.5))
	assert_vector(line.position).is_equal(Vector2(SettingsBoard.LINE_SIDE, 156))
	assert_float(line.size.y).is_equal(28.0)
	# 206 tall, centred on the picture; it fits the 360-tall picture, so it does not scroll.
	assert_that(board.rest_panel).is_equal(Rect2(SettingsBoard.BOARD_X, floorf((Screen.HEIGHT - 206.0) / 2.0),
			SettingsBoard.BOARD_W, 206))
	assert_bool(board.scrolls).is_false()
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)

func test_largest_ui_and_text_stack_and_nothing_leaves_the_panel() -> void:
	Display.prefs.step(S.UI_SIZE, 2)
	Display.prefs.step(S.TEXT_SIZE, 2)
	await _open()
	assert_bool(board.stacked).is_true()
	assert_float(board.rest_panel.size.x).is_equal(SettingsBoard.panel_width(2.0))
	# Retired in tr-1o0.1: the Colour cues line wrapping. No UI size, Text size and window wraps it at 640x360.
	assert_bool((_node("ColourCues").get_node("Row/Label") as GrownWords).wrapped).is_false()
	assert_bool((_node("UiSize").get_node("Row/Label") as GrownWords).wrapped).is_false()
	var h := _node(PLANKS[0]).size.y
	for name: String in PLANKS:
		var plank := _node(name)
		assert_float(plank.size.y).override_failure_message(name + " height").is_equal(h)
		assert_float(plank.get_rect().position.x).is_greater_equal(0.0)
		assert_float(plank.get_rect().end.x).is_less_equal(board.rest_panel.size.x)
		for child: Node in plank.get_node("Row").get_children():
			var c := child as Control
			if c != null and c.visible:
				assert_float(c.get_rect().end.x).override_failure_message(name + "/" + c.name) \
					.is_less_equal(plank.size.x - 4.0)
	var cues := _node("ColourCues")
	var sizes: Array[Vector2] = []
	for child: Node in cues.get_node("Row").get_children():
		var c := child as Control
		if c != null and c.visible:
			sizes.append(c.get_combined_minimum_size())
	var inner := board.rest_panel.size.x - 2.0 * SettingsBoard.PANEL_SIDE - SettingsBoard.PLANK_STYLE.get_minimum_size().x
	assert_float(cues.size.y).is_equal(4.0 + SettingsBoard.flow_height(sizes, inner))

func test_text_size_change_keeps_the_highlight_and_back_to_normal() -> void:
	await _open()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.COLOUR_CUES)
	Display.prefs.step(S.TEXT_SIZE, 1)
	await _settle()
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.COLOUR_CUES)
	assert_float(_node("UiSize").size.y).is_equal(20.0)
	Display.use_prefs(DisplayPrefs.new())
	await _settle()
	assert_that(_node("UiSize").get_rect()).is_equal(Rect2(SettingsBoard.PLANK_X, 28, 200, 16))
	assert_that(board.rest_panel).is_equal(Rect2(SettingsBoard.BOARD_X,
			floorf((Screen.HEIGHT - SettingsBoard.BOARD_H) / 2.0), SettingsBoard.BOARD_W, SettingsBoard.BOARD_H))
	assert_vector(_node("Line").scale).is_equal(Vector2.ONE)
