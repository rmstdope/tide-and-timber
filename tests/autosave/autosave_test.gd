extends GdUnitTestSuite
## The dawn line and the save-failed box, with the save replaced.

const B := DawnSave.Choice
const PLANK := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT := preload("res://src/title/plank_highlight.tres")

var runner: GdUnitSceneRunner
var autosave: Autosave
var results: Array = []
var calls: Array = []

func before_test() -> void:
	results = []
	calls = []
	runner = scene_runner("res://src/autosave/autosave.tscn")
	autosave = runner.scene() as Autosave
	autosave.set_process(false)
	autosave.save_game = func() -> Error:
		calls.append(1)
		return results.pop_front()

func after_test() -> void:
	autosave.get_tree().paused = false
	InputDevice.reset()
	_send_stick(JOY_AXIS_LEFT_X, 0.0)
	_send_stick(JOY_AXIS_LEFT_Y, 0.0)
	InputDevice.reset()

func _n(unique: String) -> Node:
	return autosave.get_node("%" + unique)

func _paused() -> bool:
	return autosave.get_tree().paused

func _style(button: String) -> StyleBox:
	return (_n(button) as Control).get_theme_stylebox("panel")

func _fail_dawn(more: Array = []) -> void:
	results.append(ERR_FILE_CANT_WRITE)
	results.append_array(more)
	autosave.on_dawn()

func _key(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_process_mode_is_always() -> void:
	assert_int(autosave.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

func test_nothing_shown_before_dawn() -> void:
	assert_bool(_n("Dawn").visible).is_false()
	assert_bool(_n("Box").visible).is_false()
	assert_bool(_paused()).is_false()

func test_dawn_saved_shows_the_line() -> void:
	results.append(OK)
	autosave.on_dawn()
	autosave.tick(0.5)
	assert_bool(_n("Dawn").visible).is_true()
	assert_float(_n("Dawn").modulate.a).is_equal(1.0)
	assert_str((_n("Text") as Label).text).is_equal("Another morning. Still here.")
	assert_bool(_n("Box").visible).is_false()
	assert_bool(_paused()).is_false()
	autosave.tick(3.6)
	assert_bool(_n("Dawn").visible).is_false()

func test_line_holds_while_paused() -> void:
	results.append(OK)
	autosave.on_dawn()
	autosave.tick(1.0)
	autosave.get_tree().paused = true
	autosave.tick(10.0)
	assert_bool(_n("Dawn").visible).is_true()
	assert_float(_n("Dawn").modulate.a).is_equal(1.0)
	autosave.get_tree().paused = false
	autosave.tick(3.1)
	assert_bool(_n("Dawn").visible).is_false()

func test_dawn_failed_opens_the_box_and_pauses() -> void:
	_fail_dawn()
	assert_bool(_n("Box").visible).is_true()
	assert_bool(_n("Dawn").visible).is_false()
	assert_bool(_paused()).is_true()
	assert_str((_n("FirstLine") as Label).text).is_equal("The day couldn't be saved.")
	assert_str((_n("SecondLine") as Label).text).is_equal("Your progress since yesterday may be lost if you quit.")
	assert_str((_n("TryAgain").get_node("Label") as Label).text).is_equal("Try again")
	assert_str((_n("KeepPlaying").get_node("Label") as Label).text).is_equal("Keep playing")
	assert_object(_style("TryAgain")).is_same(PLANK_HIGHLIGHT)
	assert_object(_style("KeepPlaying")).is_same(PLANK)

func test_arrows_move_the_highlight() -> void:
	_fail_dawn()
	await _key(KEY_RIGHT)
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	assert_object(_style("TryAgain")).is_same(PLANK)
	assert_object(_style("KeepPlaying")).is_same(PLANK_HIGHLIGHT)
	await _key(KEY_LEFT)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)
	assert_object(_style("TryAgain")).is_same(PLANK_HIGHLIGHT)

func test_enter_try_again_works() -> void:
	_fail_dawn([OK])
	await _key(KEY_ENTER)
	assert_bool(_n("Box").visible).is_false()
	assert_bool(_paused()).is_false()
	assert_bool(_n("Dawn").visible).is_true()

func test_enter_try_again_fails_and_shakes() -> void:
	_fail_dawn([ERR_FILE_CANT_WRITE])
	await _key(KEY_ENTER)
	assert_bool(_n("Box").visible).is_true()
	assert_bool(_paused()).is_true()
	assert_int(autosave.rules.failed_retries).is_equal(1)
	assert_bool(autosave._shake.is_running()).is_true()
	await autosave.get_tree().create_timer(0.4, true).timeout   # await_millis stops while the tree is paused
	assert_float((_n("FirstLine") as Control).position.x).is_equal(24.0)

func test_escape_keeps_playing() -> void:
	_fail_dawn()
	await _key(KEY_ESCAPE)
	assert_bool(_n("Box").visible).is_false()
	assert_bool(_paused()).is_false()
	assert_bool(_n("Dawn").visible).is_false()
	assert_int(calls.size()).is_equal(1)

func test_click_keep_playing() -> void:
	_fail_dawn()
	var button := _n("KeepPlaying") as Control
	button.mouse_entered.emit()
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	runner.simulate_mouse_move(button.get_global_rect().get_center())
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()
	assert_bool(_n("Box").visible).is_false()
	assert_bool(_paused()).is_false()

func test_keys_ignored_while_box_closed() -> void:
	results.append(OK)
	autosave.on_dawn()
	await _key(KEY_ESCAPE)
	assert_bool(autosave.rules.box_open).is_false()
	assert_bool(_paused()).is_false()

func test_box_never_unpauses_someone_elses_pause() -> void:
	autosave.get_tree().paused = true
	_fail_dawn()
	assert_bool(_n("Box").visible).is_true()
	await _key(KEY_ESCAPE)
	assert_bool(_n("Box").visible).is_false()
	assert_bool(_paused()).is_true()

func test_words_fit() -> void:
	for label: Label in [_n("Text"), _n("FirstLine"), _n("TryAgain").get_node("Label"), _n("KeepPlaying").get_node("Label")]:
		assert_bool(label.get_minimum_size().x <= label.size.x) \
			.override_failure_message("%s does not fit" % label.text).is_true()
	assert_int((_n("SecondLine") as Label).get_line_count()).is_less_equal(2)
	var screen := Rect2(0, 0, 320, 180)
	assert_bool(screen.encloses((_n("Dawn") as Control).get_global_rect())).is_true()
	assert_bool(screen.encloses((autosave.get_node("BoxLayer/Box/Panel") as Control).get_global_rect())).is_true()

func test_hud_ignores_the_mouse_except_buttons() -> void:
	var buttons := [_n("TryAgain"), _n("KeepPlaying")]
	var all: Array[Node] = [_n("Dawn"), _n("Box")]
	all.append_array(_n("Dawn").find_children("*", "Control", true, false))
	all.append_array(_n("Box").find_children("*", "Control", true, false))
	for c: Control in all:
		var want := Control.MOUSE_FILTER_STOP if c in buttons else Control.MOUSE_FILTER_IGNORE
		assert_int(c.mouse_filter).override_failure_message("%s mouse_filter" % c.name).is_equal(want)

func _joy(button: JoyButton) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = true
	Input.parse_input_event(e)
	await runner.await_input_processed()

func _send_stick(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _stick(axis: JoyAxis, value: float) -> void:
	_send_stick(axis, value)
	await runner.await_input_processed()

func test_stick_moves_between_the_buttons_and_stops_at_the_ends() -> void:
	_fail_dawn()
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	await _stick(JOY_AXIS_LEFT_X, -1.0)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	await _stick(JOY_AXIS_LEFT_X, -1.0)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)

func test_stick_inside_dead_zone_moves_nothing() -> void:
	_fail_dawn()
	await _stick(JOY_AXIS_LEFT_X, 0.2)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)

func test_controller_moves_and_presses() -> void:
	_fail_dawn([OK])
	await _joy(JOY_BUTTON_DPAD_RIGHT)
	assert_int(autosave.rules.selected).is_equal(B.KEEP_PLAYING)
	await _joy(JOY_BUTTON_DPAD_LEFT)
	assert_int(autosave.rules.selected).is_equal(B.TRY_AGAIN)
	await _joy(JOY_BUTTON_A)
	assert_bool(_n("Box").visible).is_false()
	assert_bool(_n("Dawn").visible).is_true()

func test_controller_b_keeps_playing() -> void:
	_fail_dawn()
	await _joy(JOY_BUTTON_B)
	assert_bool(_n("Box").visible).is_false()
	assert_bool(_paused()).is_false()
