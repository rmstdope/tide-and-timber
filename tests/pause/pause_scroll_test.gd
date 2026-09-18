extends GdUnitTestSuite
## The Paused board when it no longer fits above its lifted Select / Back strip: the panel is framed to
## the band, the planks scroll to the highlight, and ▲ / ▼ show where planks are hidden.
## Since tr-1o0.1 (640x360) the three-plank board a player sees fits at every UI size, Text size and window
## (pause_text_size_test.gd holds that), so this suite builds the four-plank debug board, the one that still
## scrolls: at UI Largest and Text Largest in the default 1280x720 window (k = 2) it rests 236x156 over a
## 133-deep band, a 113-unit view over 136 of content, so it scrolls 23 units, only for the last plank.

const S := DisplayPrefs.Setting

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Pause.debug_tools = true   # the four-plank board: the only one that still scrolls
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause") as Pause
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode

func _size(steps: int) -> void:
	for i in absi(steps):
		Display.prefs.step(S.UI_SIZE, signi(steps))

## UI Largest and Text Largest, set before _open(); _assert_scrolls() then checks the precondition.
func _largest() -> void:
	_size(2)
	Display.prefs.step(S.TEXT_SIZE, 2)

func _assert_scrolls() -> void:
	assert_bool(pause.scrolls).override_failure_message("precondition: the board does not scroll").is_true()

## How far the content scrolls at most: the view flush with the content's end.
func _max_offset() -> int:
	return int(pause.rest_panel.size.y - Pause.HEADING_TOP - Pause.BOTTOM_MARGIN - _node("Clip").size.y)

## The band above the strip the board is framed to, in board units.
func _band() -> Vector2:
	return ScrollWindow.band(_node("Board").get_global_transform_with_canvas(), pause.strip.screen_top())

## A board of that size centred on the picture, as lay_out() rests it.
func _centred(size: Vector2) -> Rect2:
	return Rect2(((Screen.SIZE - size) / 2.0).floor(), size)

func _tap(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()

func _open() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _settle()

func _node(unique: String) -> Control:
	return pause.get_node("%" + unique) as Control

func _screen(n: Control) -> Rect2:
	return n.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, n.size)

# gdUnit's simulate_mouse_move takes window coordinates; _screen returns the picture's canvas coordinates.
func _to_window(canvas_point: Vector2) -> Vector2:
	return get_tree().root.get_final_transform() * canvas_point

func _shown(unique: String) -> bool:
	return _screen(_node("Clip")).encloses(_screen(_node(unique)))

func test_normal_board_does_not_scroll() -> void:
	await _open()
	assert_bool(pause.scrolls).is_false()
	assert_int(pause.scroll_offset).is_equal(0)
	assert_that(_node("Panel").get_rect()).is_equal(_centred(Vector2(144, 116)))   # four 128x16 planks, step 20
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 0, 144, 116))
	assert_that(_node("Content").position).is_equal(Vector2.ZERO)
	assert_bool(pause.shows_mark_above()).is_false()
	assert_bool(pause.shows_mark_below()).is_false()

func test_largest_board_is_framed_above_the_lifted_strip() -> void:
	_largest()
	await _open()
	_assert_scrolls()
	assert_that(pause.rest_panel).is_equal(_centred(Vector2(236, 156)))
	var b := _band()
	assert_that(b).is_equal(Vector2(91, 224))
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(pause.rest_panel.position.x, b.x, 236, b.y - b.x))
	assert_that(_node("Clip").get_rect()).is_equal(
			Rect2(0, ScrollWindow.MARK_ROW, 236, b.y - b.x - 2.0 * ScrollWindow.MARK_ROW))
	assert_int(pause.scroll_offset).is_equal(0)   # the first plank's extent reaches up to the content's top
	assert_that(_node("Content").position).is_equal(Vector2(0, -Pause.HEADING_TOP))
	assert_bool(pause.shows_mark_above()).is_false()
	assert_bool(pause.shows_mark_below()).is_true()
	assert_bool(_shown("Resume")).is_true()
	assert_bool(_shown("QuitToTitle")).is_false()
	assert_float(_screen(_node("Panel")).position.y).is_equal_approx(2.0, 0.01)
	assert_float(_screen(_node("Panel")).end.y).is_equal_approx(pause.strip.screen_top() - 2.0, 0.01)

func test_moving_scrolls_to_the_highlight_and_wraps() -> void:
	_largest()
	await _open()
	_assert_scrolls()
	await _tap(KEY_DOWN)
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.SETTINGS)
	assert_int(pause.scroll_offset).is_equal(0)   # already wholly in view
	assert_bool(_shown("Settings")).is_true()
	await _tap(KEY_DOWN)
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.DEBUG)
	assert_int(pause.scroll_offset).is_equal(0)
	assert_bool(_shown("Debug")).is_true()
	await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(_max_offset())
	assert_int(_max_offset()).is_equal(23)   # 156 - 8 heading - 12 margin - 113 view
	assert_bool(_shown("QuitToTitle")).is_true()
	assert_bool(pause.shows_mark_above()).is_true()
	assert_bool(pause.shows_mark_below()).is_false()
	await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(0)
	assert_bool(_shown("Resume")).is_true()
	await _tap(KEY_UP)
	assert_int(pause.scroll_offset).is_equal(_max_offset())

func test_frame_with_a_taller_band() -> void:
	_largest()
	await _open()
	pause.scroll_offset = 0
	pause.rules.highlighted = PauseMenu.Plank.RESUME
	pause.frame(46.0, 120.0)
	assert_bool(pause.scrolls).override_failure_message("precondition: a 74-tall band scrolls the board").is_true()
	var w := pause.rest_panel.size.x
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(pause.rest_panel.position.x, 46, w, 74))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 10, w, 54))
	assert_int(pause.scroll_offset).is_equal(0)
	pause.rules.highlighted = PauseMenu.Plank.QUIT_TO_TITLE
	pause.frame(46.0, 120.0)
	# the last plank's extent runs to the content's end, so the view (54) sits flush with it
	assert_int(pause.scroll_offset).is_equal(
			int(pause.rest_panel.size.y - Pause.HEADING_TOP - Pause.BOTTOM_MARGIN - 54.0))

func test_fitting_panel_moves_inside_the_band() -> void:
	await _open()
	var y := pause.rest_panel.position.y   # the centred rest y
	var h := pause.rest_panel.size.y
	pause.frame(y + 8.0, y + h + 24.0)
	assert_bool(pause.scrolls).is_false()
	assert_float(_node("Panel").position.y).is_equal(y + 8.0)
	pause.frame(2.0, y + h + 24.0)
	assert_float(_node("Panel").position.y).is_equal(y)

func test_hovering_a_hidden_plank_scrolls_to_it() -> void:
	_largest()
	await _open()
	_assert_scrolls()
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(1, 0)
	_node("QuitToTitle").gui_input.emit(move)
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.QUIT_TO_TITLE)
	assert_int(pause.scroll_offset).is_equal(_max_offset())
	assert_bool(_shown("QuitToTitle")).is_true()

func test_reopening_starts_at_the_top() -> void:
	_largest()
	await _open()
	_assert_scrolls()
	for i in 3:
		await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(_max_offset())
	await _tap(KEY_ESCAPE)
	await _settle()
	await _tap(KEY_ESCAPE)
	await _settle()
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.RESUME)
	assert_int(pause.scroll_offset).is_equal(0)

func test_size_change_refollows() -> void:
	_largest()
	await _open()
	_assert_scrolls()
	for i in 3:
		await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(_max_offset())
	_size(-2)
	Display.prefs.step(S.TEXT_SIZE, -2)
	await _settle()
	assert_bool(pause.scrolls).is_false()
	assert_int(pause.scroll_offset).is_equal(0)
	assert_that(_node("Panel").get_rect()).is_equal(_centred(Vector2(144, 116)))
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.QUIT_TO_TITLE)
	_largest()
	await _settle()
	assert_int(pause.scroll_offset).is_equal(_max_offset())
	assert_bool(_shown("QuitToTitle")).is_true()

func test_quit_box_is_not_scrolled() -> void:
	await _open()
	assert_bool(_node("Clip").is_ancestor_of(_node("QuitBox"))).is_false()
	assert_bool(_node("Content").is_ancestor_of(_node("Heading"))).is_true()
	for unique in ["Resume", "SkipStory", "Settings", "QuitToTitle"]:
		assert_bool(_node("Content").is_ancestor_of(_node(unique))).is_true()
	assert_bool(_node("Clip").clip_contents).is_true()

func test_a_plank_scrolled_behind_the_strip_is_out_of_the_pointer_s_reach() -> void:
	_largest()
	await _open()
	_assert_scrolls()
	assert_bool(_shown("QuitToTitle")).is_false()
	var at := _screen(_node("QuitToTitle")).get_center()
	assert_bool(_screen(_node("Clip")).has_point(at)).is_false()   # behind the strip
	runner.simulate_mouse_move(_to_window(at))
	await runner.await_input_processed()
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.RESUME)

func test_a_plank_inside_the_band_still_takes_the_pointer() -> void:
	_largest()
	await _open()
	_assert_scrolls()
	assert_bool(_shown("Resume")).is_true()
	await _tap(KEY_DOWN)   # off Resume, so the pointer has something to change
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.SETTINGS)
	runner.simulate_mouse_move(_to_window(_screen(_node("Settings")).get_center()))
	await runner.await_input_processed()
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.SETTINGS)
