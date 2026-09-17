extends GdUnitTestSuite
## The Paused board when it no longer fits above its lifted Select / Back strip: the panel is framed to
## the band, the planks scroll to the highlight, and ▲ / ▼ show where planks are hidden.

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
	get_tree().root.size = Vector2i(640, 360)
	Pause.debug_tools = false
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

func _shown(unique: String) -> bool:
	return _screen(_node("Clip")).encloses(_screen(_node(unique)))

func test_normal_board_does_not_scroll() -> void:
	await _open()
	assert_bool(pause.scrolls).is_false()
	assert_int(pause.scroll_offset).is_equal(0)
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(88, 42, 144, 96))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 0, 144, 96))
	assert_that(_node("Content").position).is_equal(Vector2.ZERO)
	assert_bool(pause.shows_mark_above()).is_false()
	assert_bool(pause.shows_mark_below()).is_false()

func test_largest_board_is_framed_above_the_lifted_strip() -> void:
	_size(2)
	await _open()
	assert_that(pause.rest_panel).is_equal(Rect2(88, 42, 144, 96))
	assert_bool(pause.scrolls).is_true()
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(88, 46, 144, 52))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 10, 144, 32))
	assert_int(pause.scroll_offset).is_equal(4)
	assert_that(_node("Content").position).is_equal(Vector2(0, -12))
	assert_bool(pause.shows_mark_above()).is_true()
	assert_bool(pause.shows_mark_below()).is_true()
	assert_bool(_shown("Resume")).is_true()
	assert_float(_screen(_node("Panel")).position.y).is_equal_approx(2.0, 0.01)
	assert_float(_screen(_node("Panel")).end.y).is_equal_approx(pause.strip.screen_top() - 2.0, 0.01)

func test_moving_scrolls_to_the_highlight_and_wraps() -> void:
	_size(2)
	await _open()
	await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(24)
	assert_bool(_shown("Settings")).is_true()
	assert_bool(pause.shows_mark_above()).is_true()
	assert_bool(pause.shows_mark_below()).is_true()
	await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(44)
	assert_bool(_shown("QuitToTitle")).is_true()
	assert_bool(pause.shows_mark_above()).is_true()
	assert_bool(pause.shows_mark_below()).is_false()
	await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(4)
	assert_bool(_shown("Resume")).is_true()
	await _tap(KEY_UP)
	assert_int(pause.scroll_offset).is_equal(44)

func test_large_board_scrolls_above_the_lifted_strip() -> void:
	_size(1)
	await _open()
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(88, 32, 144, 80))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 10, 144, 60))
	assert_int(pause.scroll_offset).is_equal(0)
	assert_bool(pause.shows_mark_above()).is_false()
	assert_bool(pause.shows_mark_below()).is_true()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(16)
	assert_bool(pause.shows_mark_below()).is_false()

func test_frame_with_a_taller_band() -> void:
	_size(2)
	await _open()
	pause.scroll_offset = 0
	pause.rules.highlighted = PauseMenu.Plank.RESUME
	pause.frame(46.0, 120.0)
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(88, 46, 144, 74))
	assert_that(_node("Clip").get_rect()).is_equal(Rect2(0, 10, 144, 54))
	assert_int(pause.scroll_offset).is_equal(0)
	pause.rules.highlighted = PauseMenu.Plank.QUIT_TO_TITLE
	pause.frame(46.0, 120.0)
	assert_int(pause.scroll_offset).is_equal(22)

func test_fitting_panel_moves_inside_the_band() -> void:
	await _open()
	pause.frame(50.0, 162.0)
	assert_bool(pause.scrolls).is_false()
	assert_float(_node("Panel").position.y).is_equal(50.0)
	pause.frame(2.0, 162.0)
	assert_float(_node("Panel").position.y).is_equal(42.0)

func test_hovering_a_hidden_plank_scrolls_to_it() -> void:
	_size(2)
	await _open()
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(1, 0)
	_node("QuitToTitle").gui_input.emit(move)
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.QUIT_TO_TITLE)
	assert_int(pause.scroll_offset).is_equal(44)
	assert_bool(_shown("QuitToTitle")).is_true()

func test_reopening_starts_at_the_top() -> void:
	_size(2)
	await _open()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(44)
	await _tap(KEY_ESCAPE)
	await _settle()
	await _tap(KEY_ESCAPE)
	await _settle()
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.RESUME)
	assert_int(pause.scroll_offset).is_equal(4)

func test_size_change_refollows() -> void:
	_size(2)
	await _open()
	await _tap(KEY_DOWN)
	assert_int(pause.scroll_offset).is_equal(24)
	_size(-1)
	_size(-1)
	await _settle()
	assert_bool(pause.scrolls).is_false()
	assert_that(_node("Panel").get_rect()).is_equal(Rect2(88, 42, 144, 96))
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.SETTINGS)
	_size(2)
	await _settle()
	assert_int(pause.scroll_offset).is_equal(24)
	assert_bool(_shown("Settings")).is_true()

func test_quit_box_is_not_scrolled() -> void:
	await _open()
	assert_bool(_node("Clip").is_ancestor_of(_node("QuitBox"))).is_false()
	assert_bool(_node("Content").is_ancestor_of(_node("Heading"))).is_true()
	for unique in ["Resume", "SkipStory", "Settings", "QuitToTitle"]:
		assert_bool(_node("Content").is_ancestor_of(_node(unique))).is_true()
	assert_bool(_node("Clip").clip_contents).is_true()
