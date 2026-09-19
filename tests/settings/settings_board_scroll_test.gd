extends GdUnitTestSuite
## The Settings board on the title when its content no longer fits above the Select / Back strip:
## the panel is framed to the band, the content scrolls to the highlight, and ▲ / ▼ show where rows are hidden.
## In the default 1280x720 window a player reaches it at UI Largest and Text Large (rows side by side) and at
## UI Largest and Text Largest (rows stacked); UI size alone never makes the board scroll.

const TITLE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/scroll_none"   # never created
const S := DisplayPrefs.Setting

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

func _centred(h: float) -> Rect2:
	return Rect2(SettingsBoard.BOARD_X, floorf((Screen.HEIGHT - h) / 2.0), SettingsBoard.BOARD_W, h)

func _node(unique: String) -> Control:
	return board.get_node("%" + unique) as Control

func _visible(unique: String) -> bool:
	return _node("Clip").get_global_rect().encloses(_node(unique).get_global_rect())

func test_normal_board_does_not_scroll() -> void:
	_title()
	await _open()
	assert_bool(board.scrolls).is_false()
	assert_int(board.offset).is_equal(0)
	assert_bool(board.shows_mark_above()).is_false()
	assert_bool(board.shows_mark_below()).is_false()
	assert_that(_node("Panel").get_rect()).is_equal(_centred(SettingsBoard.BOARD_H))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 0, 304, 158))
	assert_that(_node("Content").position).is_equal(Vector2.ZERO)

func test_largest_title_board_opens_at_the_top() -> void:
	_grow(2, 2)
	_title()
	await _open()
	assert_that(board.rest_panel).is_equal(_centred(364))   # stacked, 364 tall: taller than the band
	# Drawn at 2 about the picture's centre, the band's on-screen 2 .. strip - 2 is board y 91 .. 246.
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(SettingsBoard.BOARD_X, 91, SettingsBoard.BOARD_W, 155))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, ScrollWindow.MARK_ROW, SettingsBoard.BOARD_W, 155 - 2 * ScrollWindow.MARK_ROW))
	assert_int(board.offset).is_equal(0)
	assert_that(_node("Content").position).is_equal(Vector2(0, -8))
	assert_bool(board.shows_mark_above()).is_false()
	assert_bool(board.shows_mark_below()).is_true()
	assert_bool(_visible("UiSize")).is_true()
	assert_float(_node("Panel").get_global_rect().position.y).is_equal(2.0)
	assert_float(_node("Panel").get_global_rect().end.y).is_equal(board.strip.screen_top() - 2.0)

func test_moving_down_and_up_scrolls_to_the_highlight() -> void:
	_grow(2, 2)
	_title()
	await _open()
	assert_bool(board.scrolls).is_true()
	# Content y of the planks: 28, 76, 124, 172, 220 (44 tall); the clip is 135 tall; content 348, so at most 213.
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(0)   # Text size is already wholly in the clip
	assert_bool(board.shows_mark_above()).is_false()
	assert_bool(board.shows_mark_below()).is_true()
	assert_bool(_visible("TextSize")).is_true()
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(33)   # Colour cues' bottom 168 - 135
	assert_bool(board.shows_mark_above()).is_true()
	assert_bool(_visible("ColourCues")).is_true()
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(81)   # Fullscreen's bottom 216 - 135
	assert_bool(_visible("Fullscreen")).is_true()
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(213)   # Controls with the line under the list: the end of the content
	assert_bool(_visible("Controls")).is_true()
	assert_bool(board.shows_mark_below()).is_false()
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.CONTROLS)
	await _tap(KEY_UP)
	assert_int(board.offset).is_equal(172)   # Fullscreen's top
	await _tap(KEY_UP)
	assert_int(board.offset).is_equal(124)   # Colour cues' top
	await _tap(KEY_UP)
	assert_int(board.offset).is_equal(76)   # Text size's top
	await _tap(KEY_UP)
	assert_int(board.offset).is_equal(0)
	assert_bool(board.shows_mark_above()).is_false()
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)

func test_large_title_board_scrolls_side_by_side() -> void:
	_grow(2, 1)
	_title()
	await _open()
	assert_bool(board.stacked).is_false()
	assert_that(board.rest_panel).is_equal(_centred(206))
	# Drawn at 2: the band is board y 91 .. 250 (this strip sits 4 lower than the stacked board's).
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(SettingsBoard.BOARD_X, 91, SettingsBoard.BOARD_W, 159))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, ScrollWindow.MARK_ROW, SettingsBoard.BOARD_W, 159 - 2 * ScrollWindow.MARK_ROW))
	for i in 4:
		await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(51)   # content 206 - 16 = 190, less the 139 clip
	assert_bool(board.shows_mark_above()).is_true()
	assert_bool(board.shows_mark_below()).is_false()
	assert_bool(_visible("Controls")).is_true()

func test_hovering_a_row_scrolls_to_it() -> void:
	_grow(2, 2)
	_title()
	await _open()
	assert_bool(board.scrolls).is_true()
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(1, 0)
	_node("ColourCues").gui_input.emit(move)
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.COLOUR_CUES)
	assert_int(board.offset).is_equal(33)   # Colour cues' bottom 168 - the 135 clip
	assert_bool(_visible("ColourCues")).is_true()

func test_size_change_refollows_and_back_to_normal_stops_scrolling() -> void:
	_grow(2, 2)
	_title()
	await _open()
	assert_bool(board.scrolls).is_true()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(33)   # Colour cues' bottom 168 - the 135 clip
	Display.prefs.step(S.UI_SIZE, -2)
	Display.prefs.step(S.TEXT_SIZE, -2)
	await _settle()
	assert_bool(board.scrolls).is_false()
	assert_int(board.offset).is_equal(0)
	assert_that(_node("Panel").get_rect()).is_equal(_centred(SettingsBoard.BOARD_H))
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.COLOUR_CUES)
	_grow(2, 2)
	await _settle()
	assert_bool(board.scrolls).is_true()
	assert_int(board.offset).is_equal(33)
	assert_bool(_visible("ColourCues")).is_true()

func test_rows_are_clipped() -> void:
	_title()
	await _open()
	var clip := _node("Clip")
	assert_bool(clip.clip_contents).is_true()
	for unique: String in ["Heading", "UiSize", "TextSize", "ColourCues", "Fullscreen", "Controls", "Line"]:
		assert_bool(clip.is_ancestor_of(_node(unique))) \
			.override_failure_message("%s is not inside the clip" % unique).is_true()
	assert_bool(clip.is_ancestor_of(_node("ControlsPage"))).is_false()

func test_the_marks_are_wired_and_centred_in_their_rows() -> void:
	_grow(2, 2)
	_title()
	await _open()
	assert_bool(board.scrolls).is_true()
	var marks := _node("Marks")
	assert_that(marks.get_rect()).is_equal(Rect2(0, 0, SettingsBoard.BOARD_W, 155))
	assert_int(marks.get_signal_connection_list("draw").size()) \
		.override_failure_message("%Marks has no draw handler, so no mark is ever drawn").is_greater(0)
	# The centres _draw_marks draws on: the panel's horizontal centre, in the top and bottom mark rows
	# of the 155-tall panel. Pinned as literals, so moving either mark out of its row fails here.
	assert_that(board.mark_centre(true)).is_equal(Vector2(152, 5))
	assert_that(board.mark_centre(false)).is_equal(Vector2(152, 150))
	var font := load("res://assets/fonts/PressStart2P-Regular.ttf") as Font
	assert_that(ScrollWindow.mark_origin(font, board.mark_centre(true), true)).is_equal(Vector2(148, 9))
	assert_that(ScrollWindow.mark_origin(font, board.mark_centre(false), false)).is_equal(Vector2(148, 154))
