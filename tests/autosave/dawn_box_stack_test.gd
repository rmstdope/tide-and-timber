extends GdUnitTestSuite
## The dawn-save box stacks its buttons, left on top, when side by side is wider than the screen.

const B := DawnSave.Choice

var runner: GdUnitSceneRunner
var autosave: Autosave
var results: Array = []
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(640, 360)
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset()
	results = []
	runner = scene_runner("res://src/autosave/autosave.tscn")
	autosave = runner.scene() as Autosave
	autosave.set_process(false)
	autosave.save_game = func() -> Error: return results.pop_front()

func after_test() -> void:
	autosave.get_tree().paused = false
	InputDevice.reset()
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _size_up(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)

func _n(unique: String) -> Control:
	return autosave.get_node("%" + unique)

func _rect(unique: String) -> Rect2:
	return Rect2(_n(unique).position, _n(unique).size)

func _panel_rect() -> Rect2:
	var p: Control = autosave.get_node("BoxLayer/Box/Panel")
	return Rect2(p.position, p.size)

func _fail_dawn(more: Array = []) -> void:
	results.append(ERR_FILE_CANT_WRITE)
	results.append_array(more)
	autosave.on_dawn()

func _key(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _highlighted(unique: String) -> void:
	assert_bool(is_same(_n(unique).get_theme_stylebox("panel"), Autosave.PLANK_HIGHLIGHT_STYLE)) \
		.override_failure_message(unique + " is not highlighted").is_true()

func _assert_normal() -> void:
	assert_that(_panel_rect()).is_equal(Rect2(12, 42, 296, 96))
	assert_that(_rect("FirstLine")).is_equal(Rect2(24, 8, 264, 12))
	assert_that(_rect("SecondLine")).is_equal(Rect2(8, 28, 280, 28))
	assert_that(_rect("TryAgain")).is_equal(Rect2(40, 66, 104, 20))
	assert_that(_rect("KeepPlaying")).is_equal(Rect2(152, 66, 104, 20))

func test_normal_is_todays_layout() -> void:
	_fail_dawn()
	_assert_normal()

func test_stacks_at_largest() -> void:
	_size_up(2)
	_fail_dawn()
	assert_that(_panel_rect()).is_equal(Rect2(84, 13, 152, 155))
	assert_that(_rect("FirstLine")).is_equal(Rect2(24, 8, 120, 30))
	assert_that(_rect("SecondLine")).is_equal(Rect2(8, 46, 136, 41))
	assert_that(_rect("TryAgain")).is_equal(Rect2(24, 97, 104, 20))
	assert_that(_rect("KeepPlaying")).is_equal(Rect2(24, 125, 104, 20))

func test_stacks_at_large() -> void:
	_size_up(1)
	_fail_dawn()
	assert_that(_panel_rect()).is_equal(Rect2(58, 24, 204, 133))
	assert_that(_rect("FirstLine")).is_equal(Rect2(24, 8, 172, 19))
	assert_that(_rect("SecondLine")).is_equal(Rect2(8, 35, 188, 30))
	assert_that(_rect("TryAgain")).is_equal(Rect2(50, 75, 104, 20))
	assert_that(_rect("KeepPlaying")).is_equal(Rect2(50, 103, 104, 20))

func test_unstacks_keeping_the_highlight() -> void:
	_size_up(2)
	_fail_dawn()
	await _key(KEY_DOWN)
	Display.use_prefs(DisplayPrefs.new())
	_assert_normal()
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	_highlighted("KeepPlaying")

func test_up_down_move_between_stacked_buttons() -> void:
	_size_up(2)
	_fail_dawn()
	await _key(KEY_DOWN)
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	await _key(KEY_UP)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)
	await _key(KEY_RIGHT)
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	await _key(KEY_LEFT)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)
	assert_bool(autosave.rules.box_open).is_true()

func test_up_down_do_nothing_side_by_side() -> void:
	_fail_dawn()
	await _key(KEY_DOWN)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)

func test_failed_retry_still_shakes_when_stacked() -> void:
	_size_up(2)
	_fail_dawn([ERR_FILE_CANT_WRITE])
	await _key(KEY_ENTER)
	assert_int(autosave.rules.failed_retries).is_equal(1)
	await get_tree().create_timer(0.3, true).timeout
	assert_float(_n("FirstLine").position.x).is_equal(24.0)
