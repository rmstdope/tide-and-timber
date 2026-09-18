extends GdUnitTestSuite
## The dawn-save box stacks its buttons, left on top, when side by side is wider than the screen.
## At 640x360 UI size alone never stacks it, so the stacked layouts are reached as a player would, in the
## default 1280x720 window: UI Largest + Text Large (the smallest combination at UI Largest), and
## UI Large + Text Largest (the only one at UI Large). Every test about a stacked box asserts stacked first.

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

func _size_up(steps: int, text_steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	for i in text_steps:
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)

## UI Largest + Text Large, or UI Large + Text Largest: the two stacked layouts.
func _stack_largest() -> void:
	_size_up(2, 1)

func _stack_large() -> void:
	_size_up(1, 2)

func _assert_stacked() -> void:
	assert_bool(autosave._box.stacked).override_failure_message("the box did not stack").is_true()

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

func _highlighted(unique: String) -> void:
	assert_bool(is_same(_n(unique).get_theme_stylebox("panel"), Autosave.PLANK_HIGHLIGHT_STYLE)) \
		.override_failure_message(unique + " is not highlighted").is_true()

func _assert_normal() -> void:
	assert_bool(autosave._box.stacked).is_false()
	# the scene's 296x96 box, centred on the picture
	assert_that(_panel_rect()).is_equal(Rect2(Screen.CENTRE - Vector2(148, 48), Vector2(296, 96)))
	assert_that(_rect("FirstLine")).is_equal(Rect2(24, 8, 264, 12))
	assert_that(_rect("SecondLine")).is_equal(Rect2(8, 28, 280, 28))
	assert_that(_rect("TryAgain")).is_equal(Rect2(40, 66, 104, 20))
	assert_that(_rect("KeepPlaying")).is_equal(Rect2(152, 66, 104, 20))

## A stacked box: centred on the picture, its lines keep their insets, its buttons are centred on
## the box's width, the left one on top, one above the other.
func _assert_stacked_layout(width: float) -> void:
	var box: BoxLayout = autosave._box
	var p := _panel_rect()
	assert_float(p.size.x).is_equal(width)
	assert_that(p.position).is_equal((Screen.CENTRE - p.size / 2.0).round())
	assert_float(box.lines[0].position.x).is_equal(24.0)
	assert_float(box.lines[0].end.x).is_equal(width - 8.0)
	assert_float(box.lines[1].position.x).is_equal(8.0)
	assert_float(box.lines[1].end.x).is_equal(width - 8.0)
	assert_float(box.left.position.x).is_equal(roundf((width - box.left.size.x) / 2.0))
	assert_float(box.right.position.x).is_equal(roundf((width - box.right.size.x) / 2.0))
	assert_float(box.left.end.y).is_less(box.right.position.y)
	assert_that(_rect("TryAgain")).is_equal(box.left)
	assert_that(_rect("KeepPlaying")).is_equal(box.right)

func test_normal_is_todays_layout() -> void:
	_fail_dawn()
	_assert_normal()

func test_stacks_at_largest() -> void:
	_stack_largest()
	_fail_dawn()
	_assert_stacked()
	# as wide as the picture allows at UI Largest: BoxLayout.widest(2) = 312
	_assert_stacked_layout(BoxLayout.widest(UiScale.current(Display.prefs, get_tree().root)))
	# 158 tall: the grown lines wrap to 19 + 30 and the buttons stack (observed at this setting)
	assert_float(_panel_rect().size.y).is_equal(158.0)

func test_stacks_at_large() -> void:
	_stack_large()
	_fail_dawn()
	_assert_stacked()
	# as wide as the picture allows at UI Large: BoxLayout.widest(1.5) = 418
	_assert_stacked_layout(BoxLayout.widest(UiScale.current(Display.prefs, get_tree().root)))
	# 182 tall: the grown lines wrap to 19 + 30 and the buttons stack (observed at this setting)
	assert_float(_panel_rect().size.y).is_equal(182.0)

func test_unstacks_keeping_the_highlight() -> void:
	_stack_largest()
	_fail_dawn()
	_assert_stacked()
	await _key(KEY_RIGHT)
	Display.use_prefs(DisplayPrefs.new())
	_assert_normal()
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	_highlighted("KeepPlaying")

func test_left_right_move_between_stacked_buttons() -> void:
	_stack_largest()
	_fail_dawn()
	_assert_stacked()
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
	_stack_largest()
	_fail_dawn([ERR_FILE_CANT_WRITE])
	_assert_stacked()
	await _key(KEY_ENTER)
	assert_int(autosave.rules.failed_retries).is_equal(1)
	await get_tree().create_timer(0.3, true).timeout
	assert_float(_n("FirstLine").position.x).is_equal(24.0)

