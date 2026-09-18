extends GdUnitTestSuite
## The Settings board on the title when its content no longer fits above the Select / Back strip:
## the panel is framed to the band, the content scrolls to the highlight, and ▲ / ▼ show where rows are hidden.

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
	get_tree().root.size = Vector2i(2560, 1440)
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

func _size(steps: int) -> void:
	for i in steps:
		Display.prefs.step(S.UI_SIZE, 1)

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
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(8, 21, 304, 138))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 0, 304, 138))
	assert_that(_node("Content").position).is_equal(Vector2.ZERO)

func test_largest_title_board_opens_at_the_top() -> void:
	_size(2)
	_title()
	await _open()
	assert_that(board.rest_panel).is_equal(Rect2(82, -13, 156, 206))
	assert_bool(board.scrolls).is_true()
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(82, 46, 156, 74))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 10, 156, 54))
	assert_int(board.offset).is_equal(0)
	assert_that(_node("Content").position).is_equal(Vector2(0, -8))
	assert_bool(board.shows_mark_above()).is_false()
	assert_bool(board.shows_mark_below()).is_true()
	assert_bool(_visible("UiSize")).is_true()
	assert_float(_node("Panel").get_global_rect().position.y).is_equal(2.0)
	assert_float(_node("Panel").get_global_rect().end.y).is_equal(board.strip.screen_top() - 2.0)

func test_moving_down_and_up_scrolls_to_the_highlight() -> void:
	_size(2)
	_title()
	await _open()
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(26)
	assert_bool(board.shows_mark_above()).is_true()
	assert_bool(board.shows_mark_below()).is_true()
	assert_bool(_visible("TextSize")).is_true()
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(58)
	assert_bool(_visible("ColourCues")).is_true()
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(116)
	assert_bool(_visible("Controls")).is_true()
	assert_bool(board.shows_mark_below()).is_true()
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.CONTROLS)
	await _tap(KEY_UP)
	assert_int(board.offset).is_equal(84)
	await _tap(KEY_UP)
	assert_int(board.offset).is_equal(52)
	await _tap(KEY_UP)
	assert_int(board.offset).is_equal(0)
	assert_bool(board.shows_mark_above()).is_false()
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)

func test_large_title_board_scrolls_side_by_side() -> void:
	_size(1)
	_title()
	await _open()
	assert_bool(board.stacked).is_false()
	assert_bool(board.scrolls).is_true()
	assert_that(board.rest_panel).is_equal(Rect2(55, 16, 209, 148))
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(55, 32, 209, 102))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 10, 209, 82))
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(50)
	assert_bool(board.shows_mark_above()).is_true()
	assert_bool(board.shows_mark_below()).is_false()
	assert_bool(_visible("Controls")).is_true()

func test_hovering_a_row_scrolls_to_it() -> void:
	_size(2)
	_title()
	await _open()
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(1, 0)
	_node("TextSize").gui_input.emit(move)
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.TEXT_SIZE)
	assert_int(board.offset).is_equal(26)
	assert_bool(_visible("TextSize")).is_true()

func test_size_change_refollows_and_back_to_normal_stops_scrolling() -> void:
	_size(2)
	_title()
	await _open()
	await _tap(KEY_DOWN)
	assert_int(board.offset).is_equal(26)
	Display.prefs.step(S.UI_SIZE, -1)
	Display.prefs.step(S.UI_SIZE, -1)
	await _settle()
	assert_bool(board.scrolls).is_false()
	assert_int(board.offset).is_equal(0)
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(8, 21, 304, 138))
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.TEXT_SIZE)
	Display.prefs.step(S.UI_SIZE, 1)
	Display.prefs.step(S.UI_SIZE, 1)
	await _settle()
	assert_bool(board.scrolls).is_true()
	assert_int(board.offset).is_equal(26)
	assert_bool(_visible("TextSize")).is_true()

func test_rows_are_clipped() -> void:
	_title()
	await _open()
	var clip := _node("Clip")
	assert_bool(clip.clip_contents).is_true()
	for unique: String in ["Heading", "UiSize", "TextSize", "ColourCues", "Controls", "Line"]:
		assert_bool(clip.is_ancestor_of(_node(unique))) \
			.override_failure_message("%s is not inside the clip" % unique).is_true()
	assert_bool(clip.is_ancestor_of(_node("ControlsPage"))).is_false()

func test_the_marks_are_wired_and_centred_in_their_rows() -> void:
	_size(2)
	_title()
	await _open()
	var marks := _node("Marks")
	assert_that(marks.get_rect()).is_equal(Rect2(0, 0, 156, 74))
	assert_int(marks.get_signal_connection_list("draw").size()) \
		.override_failure_message("%Marks has no draw handler, so no mark is ever drawn").is_greater(0)
	# The centres _draw_marks draws on: the panel's horizontal centre, in the top and bottom mark rows
	# of the 74-tall panel. Pinned as literals, so moving either mark out of its row fails here.
	assert_that(board.mark_centre(true)).is_equal(Vector2(78, 5))
	assert_that(board.mark_centre(false)).is_equal(Vector2(78, 69))
	var font := load("res://assets/fonts/PressStart2P-Regular.ttf") as Font
	assert_that(ScrollWindow.mark_origin(font, board.mark_centre(true), true)).is_equal(Vector2(74, 9))
	assert_that(ScrollWindow.mark_origin(font, board.mark_centre(false), false)).is_equal(Vector2(74, 73))
