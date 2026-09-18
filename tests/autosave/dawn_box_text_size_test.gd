extends GdUnitTestSuite
## At larger Text size the dawn-save box's words grow; the box widens, then wraps, and its grown buttons stack.
## At 640x360 Text size alone never stacks the buttons (UI Normal leaves room), so the stacking test
## steps UI size to Large first and then Text size: it stacks at UI Large + Text Largest.

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
	get_tree().root.size = Vector2i(1280, 720)
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

func _n(unique: String) -> Control:
	return autosave.get_node("%" + unique)

func _rect(unique: String) -> Rect2:
	return Rect2(_n(unique).position, _n(unique).size)

## The rest layout, before framing: the box now scrolls whenever it stacks.
func _panel_rect() -> Rect2:
	return autosave._box.panel

func _fail_dawn(more: Array = []) -> void:
	results.append(ERR_FILE_CANT_WRITE)
	results.append_array(more)
	autosave.on_dawn()

func _key(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _text_up(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	await await_idle_frame()
	await await_idle_frame()

func test_largest_text_widens_the_box_and_keeps_the_journal_inset() -> void:
	_fail_dawn()
	await _text_up(2)
	# as wide as the picture allows at this UI size
	assert_float(_panel_rect().size.x).is_equal(BoxLayout.widest(UiScale.current(Display.prefs, get_tree().root)))
	assert_float(_n("FirstLine").position.x).is_equal(Autosave.FIRST_LINE_X)
	assert_that(_n("FirstLine").scale).is_equal(Vector2(2, 2))

func test_grown_buttons_stack_and_up_down_choose() -> void:
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	_fail_dawn()
	var steps := 0
	while not autosave._box.stacked and steps < 2:
		await _text_up(1)
		steps += 1
	assert_bool(autosave._box.stacked).is_true()
	# stacked, each button is centred on its own width (BoxLayout's pinned rule), so their centres line up
	var a := _rect("TryAgain").get_center().x
	var b := _rect("KeepPlaying").get_center().x
	assert_float(absf(a - b)).is_less_equal(0.5)
	assert_float(_rect("TryAgain").end.y).is_less(_rect("KeepPlaying").position.y)
	var before := autosave.rules.selected
	await _key(KEY_DOWN)
	await _key(KEY_UP)
	await _key(KEY_DOWN)
	assert_int(autosave.rules.selected).is_not_equal(B.TRY_AGAIN)
	await _key(KEY_UP)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)
	assert_int(before).is_equal(B.TRY_AGAIN)
