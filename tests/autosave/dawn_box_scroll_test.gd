extends GdUnitTestSuite
## The dawn-save box, too tall for the room above the Select / Back strip, scrolls its words and
## buttons a line per push, with ▲ / ▼.

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

func _panel() -> Control:
	return autosave.get_node("BoxLayer/Box/Panel")

func _clip() -> Control:
	return autosave.get_node("BoxLayer/Box/Panel/Clip")

func _content() -> Control:
	return autosave.get_node("BoxLayer/Box/Panel/Clip/Content")

func _frame() -> BoxLayout:
	return autosave._box_frame

func _rect(node: Control) -> Rect2:
	return Rect2(node.position, node.size)

func _fail_dawn(more: Array = []) -> void:
	results.append(ERR_FILE_CANT_WRITE)
	results.append_array(more)
	autosave.on_dawn()
	await get_tree().process_frame

func _key(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _highlighted(unique: String) -> void:
	assert_bool(is_same(_n(unique).get_theme_stylebox("panel"), Autosave.PLANK_HIGHLIGHT_STYLE)) \
		.override_failure_message(unique + " is not highlighted").is_true()

func test_largest_opens_framed_at_the_top() -> void:
	_size_up(2)
	await _fail_dawn()
	assert_float(autosave.strip.screen_top()).is_equal(152.0)
	assert_that(_rect(_panel())).is_equal(Rect2(84, 46, 152, 74))
	assert_that(_rect(_clip())).is_equal(Rect2(0, 10, 152, 54))
	assert_that(_rect(_content())).is_equal(Rect2(0, -8, 152, 155))
	_highlighted("TryAgain")
	assert_bool(_frame().shows_mark_below()).is_true()
	assert_bool(_frame().shows_mark_above()).is_false()

func test_reads_down_then_moves_to_keep_playing() -> void:
	_size_up(2)
	await _fail_dawn()
	for i in 5:
		await _key(KEY_DOWN)
	assert_float(_content().position.y).is_equal(-63.0)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)
	await _key(KEY_DOWN)
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	assert_float(_content().position.y).is_equal(-91.0)
	assert_bool(_frame().shows_mark_above()).is_true()
	assert_bool(_frame().shows_mark_below()).is_false()

func test_up_back_through_the_words() -> void:
	_size_up(2)
	await _fail_dawn()
	await _key(KEY_RIGHT)
	assert_int(autosave._box_offset).is_equal(83)
	await _key(KEY_UP)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)
	assert_int(autosave._box_offset).is_equal(83)
	for i in 8:
		await _key(KEY_UP)
	assert_int(autosave._box_offset).is_equal(0)

func test_select_on_hidden_try_again_retries() -> void:
	_size_up(2)
	await _fail_dawn([OK])
	assert_int(autosave._box_offset).is_equal(0)
	await _key(KEY_ENTER)
	assert_bool(autosave.rules.box_open).is_false()

func test_normal_fits_unchanged() -> void:
	await _fail_dawn()
	assert_that(_rect(_panel())).is_equal(Rect2(12, 42, 296, 96))
	assert_bool(_frame().shows_mark_above()).is_false()
	assert_bool(_frame().shows_mark_below()).is_false()

func test_journal_scrolls_with_the_words() -> void:
	_size_up(2)
	await _fail_dawn()
	for i in 3:
		await _key(KEY_DOWN)
	var journal: Control = autosave.get_node("BoxLayer/Box/Panel/Clip/Content/CrossedJournal")
	assert_that(journal.position).is_equal(Vector2(8, 8))
	assert_bool(is_same(journal.get_parent(), _content())).is_true()
