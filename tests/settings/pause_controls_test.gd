extends GdUnitTestSuite
## The Controls page opened from the Paused board: tabs, slots, Clear, Reset, leaving, and Start resuming play.

const A := Controls.Action
const D := Controls.Device

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var board: SettingsBoard
var page: ControlsPage
var changes: Array[String] = []
var resumed := 0

func before_test() -> void:
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())
	changes = []
	resumed = 0
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	board = pause.get_node("%SettingsBoard")
	page = board.get_node("%ControlsPage")
	pause.quit_to_title = func() -> void: pass
	pause.resumed.connect(func() -> void: resumed += 1)
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	get_tree().paused = false
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _control() -> void:
	waking.tick(5.0)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _pad(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = button
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func _left_click(control: Control, at: Vector2 = Vector2.ZERO) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	control.gui_input.emit(click)

func _motion(control: Control, at: Vector2 = Vector2.ZERO) -> void:
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(1, 0)
	move.position = at
	control.gui_input.emit(move)

func _record_changes() -> void:
	var recorded := changes
	page.change_slot = func() -> void: recorded.append("change")

func _open_settings() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)

func _open_page() -> void:
	await _open_settings()
	await _tap(KEY_ENTER)

func _down(times: int) -> void:
	for i in times:
		await _tap(KEY_DOWN)

func _is_highlighted(control: Control) -> bool:
	return is_same(control.get_theme_stylebox("panel"), ControlsPage.PLANK_HIGHLIGHT_STYLE)

func _box_node(unique: String) -> Control:
	return page.get_node("%" + unique) as Control

func _box_label(unique: String) -> String:
	return (_box_node(unique).get_node("Label") as Label).text

func _assert_board_on_controls() -> void:
	assert_bool(page.visible).is_false()
	assert_bool(board.visible).is_true()
	assert_bool(board.get_node("%Panel").visible).is_true()
	assert_bool(_is_highlighted(board.get_node("%Controls"))).override_failure_message("Controls is not highlighted").is_true()
	assert_bool(get_tree().paused).is_true()

func test_controls_opens_the_page_on_the_keyboard_tab() -> void:
	await _open_page()
	assert_bool(page.visible).is_true()
	assert_bool(board.get_node("%Panel").visible).is_false()
	assert_bool(get_tree().paused).is_true()
	assert_int(page.rules.device).is_equal(D.KEYBOARD)
	assert_int(page.rules.row).is_equal(0)
	assert_int(page.rules.slot).is_equal(0)
	assert_str(page.strip.text()).is_equal("[Q][E] Tab   [Enter] Change   [Del] Clear   [Esc] Back")

func test_opens_on_controller_after_a_pad_press() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _pad(JOY_BUTTON_A)
	await _pad(JOY_BUTTON_A)
	assert_bool(page.visible).is_true()
	assert_int(page.rules.device).is_equal(D.CONTROLLER)

func test_enter_that_opens_the_page_changes_nothing_on_it() -> void:
	await _open_settings()
	_record_changes()
	await _tap(KEY_ENTER)
	assert_bool(page.visible).is_true()
	assert_array(changes).is_empty()
	await _tap(KEY_ENTER)
	assert_array(changes).is_equal(["change"])

func test_q_and_lb_switch_tabs() -> void:
	await _open_page()
	await _down(2)
	await _tap(KEY_Q)
	assert_int(page.rules.device).is_equal(D.CONTROLLER)
	assert_int(page.rules.row).is_equal(2)
	assert_str(page.strip.text()).starts_with("[Q]")
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	assert_int(page.rules.device).is_equal(D.KEYBOARD)
	assert_int(page.rules.row).is_equal(2)
	assert_str(page.strip.text()).starts_with("(LB)")
	await _tap(KEY_E)
	assert_int(page.rules.device).is_equal(D.CONTROLLER)
	assert_str(page.strip.text()).starts_with("[Q]")

func test_a_and_d_move_between_slots() -> void:
	await _open_page()
	await _tap(KEY_D)
	assert_int(page.rules.slot).is_equal(1)
	await _tap(KEY_D)
	assert_int(page.rules.slot).is_equal(1)
	await _tap(KEY_A)
	assert_int(page.rules.slot).is_equal(0)

func test_delete_clears_and_saves_to_the_model() -> void:
	await _open_page()
	await _down(6)
	await _tap(KEY_DELETE)
	assert_object(InputDevice.controls.slot(A.BUILD_LIST, D.KEYBOARD, 0)).is_null()
	assert_bool(InputMap.event_is_action(_key(KEY_B), &"build")).is_false()
	assert_str(page.rules.no_key_line).is_equal("Build list has no key")
	await _tap(KEY_DOWN)
	assert_str(page.rules.no_key_line).is_equal("")
	for i in 7:
		await _tap(KEY_UP)
	assert_int(page.rules.row).is_equal(0)
	await _tap(KEY_BACKSPACE)
	assert_object(InputDevice.controls.slot(A.WALK_UP, D.KEYBOARD, 0)).is_null()

func _key(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.pressed = true
	return e

func test_pad_x_clears() -> void:
	await _open_page()
	await _tap(KEY_E)
	await _down(5)
	await _pad(JOY_BUTTON_X)
	assert_object(InputDevice.controls.slot(A.USE, D.CONTROLLER, 0)).is_null()
	assert_str(page.rules.no_key_line).is_equal("Use / take has no key")

func test_reset_box_and_reset() -> void:
	await _open_page()
	await _down(6)
	await _tap(KEY_DELETE)
	await _down(2)
	await _tap(KEY_ENTER)
	assert_bool(_box_node("Box").visible).is_true()
	assert_str((_box_node("Lines") as Label).text).is_equal("Put every keyboard key back as it was?")
	assert_str(_box_label("Safe")).is_equal("Keep mine")
	assert_str(_box_label("Other")).is_equal("Reset")
	assert_bool(_is_highlighted(_box_node("Safe"))).is_true()
	assert_bool(_is_highlighted(_box_node("Other"))).is_false()
	assert_str(page.strip.text()).is_equal("[Enter] Select   [Esc] Back")
	await _tap(KEY_RIGHT)
	assert_bool(_is_highlighted(_box_node("Other"))).is_true()
	await _tap(KEY_ENTER)
	assert_bool(_box_node("Box").visible).is_false()
	assert_bool(Controls.same_input(InputDevice.controls.slot(A.BUILD_LIST, D.KEYBOARD, 0), _key(KEY_B))).is_true()
	assert_int(page.rules.row).is_equal(ControlsMenu.RESET_ROW)
	assert_bool(get_tree().paused).is_true()

func test_reset_box_back_keeps_mine() -> void:
	await _open_page()
	await _down(6)
	await _tap(KEY_DELETE)
	await _down(2)
	await _tap(KEY_ENTER)
	await _tap(KEY_ESCAPE)
	assert_bool(_box_node("Box").visible).is_false()
	assert_bool(page.visible).is_true()
	assert_object(InputDevice.controls.slot(A.BUILD_LIST, D.KEYBOARD, 0)).is_null()

func test_back_returns_to_the_settings_board_on_controls() -> void:
	await _open_page()
	await _tap(KEY_ESCAPE)
	_assert_board_on_controls()
	await _tap(KEY_ESCAPE)
	assert_bool(board.visible).is_false()
	assert_bool(pause.get_node("%Board").visible).is_true()
	assert_bool(_is_highlighted(pause.get_node("%Settings"))).is_true()
	assert_bool(get_tree().paused).is_true()

func test_back_with_an_empty_action_warns() -> void:
	await _open_page()
	await _down(6)
	await _tap(KEY_DELETE)
	await _tap(KEY_ESCAPE)
	assert_bool(_box_node("Box").visible).is_true()
	assert_str((_box_node("Lines") as Label).text).is_equal("Build list has no key.\nLeave anyway?")
	assert_str(_box_label("Safe")).is_equal("Set a key")
	assert_str(_box_label("Other")).is_equal("Leave")
	assert_bool(_is_highlighted(_box_node("Safe"))).is_true()
	await _tap(KEY_ESCAPE)
	assert_bool(_box_node("Box").visible).is_false()
	assert_bool(page.visible).is_true()
	assert_int(page.rules.row).is_equal(A.BUILD_LIST)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	_assert_board_on_controls()
	assert_object(InputDevice.controls.slot(A.BUILD_LIST, D.KEYBOARD, 0)).is_null()

func test_start_resumes_play_at_once() -> void:
	await _open_page()
	await _pad(JOY_BUTTON_START)
	assert_bool(get_tree().paused).is_false()
	assert_bool(page.visible).is_false()
	assert_bool(board.visible).is_false()
	assert_bool(pause.get_node("%Board").visible).is_false()
	assert_int(resumed).is_equal(1)

func test_esc_is_back_not_resume() -> void:
	await _open_page()
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_true()
	assert_int(resumed).is_equal(0)

func test_start_with_an_empty_action_warns_then_leave_resumes() -> void:
	await _open_page()
	await _down(6)
	await _tap(KEY_DELETE)
	await _pad(JOY_BUTTON_START)
	assert_bool(_box_node("Box").visible).is_true()
	assert_bool(get_tree().paused).is_true()
	await _pad(JOY_BUTTON_START)
	assert_bool(_box_node("Box").visible).is_true()
	assert_bool(get_tree().paused).is_true()
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_bool(get_tree().paused).is_false()
	assert_int(resumed).is_equal(1)

func test_start_warning_set_a_key_stays() -> void:
	await _open_page()
	await _down(6)
	await _tap(KEY_DELETE)
	await _pad(JOY_BUTTON_START)
	await _tap(KEY_ENTER)
	assert_bool(page.visible).is_true()
	assert_bool(_box_node("Box").visible).is_false()
	assert_bool(get_tree().paused).is_true()

func test_mouse_hovers_clicks_slots_and_tabs() -> void:
	await _open_page()
	_motion(page, ControlsPage.slot_rect(4, 1).get_center())
	assert_int(page.rules.row).is_equal(4)
	assert_int(page.rules.slot).is_equal(1)
	_left_click(page, ControlsPage.TAB_RECTS[1].get_center())
	assert_int(page.rules.device).is_equal(D.CONTROLLER)
	_left_click(page, ControlsPage.row_rect(8).get_center())
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.RESET)
	InputDevice.controls.clear_slot(A.USE, D.CONTROLLER, 0)
	_motion(_box_node("Other"))
	assert_bool(_is_highlighted(_box_node("Other"))).is_true()
	_left_click(_box_node("Other"))
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.NONE)
	assert_object(InputDevice.controls.slot(A.USE, D.CONTROLLER, 0)).is_not_null()

func test_click_on_a_slot_calls_the_seam() -> void:
	await _open_page()
	_record_changes()
	_left_click(page, ControlsPage.slot_rect(2, 1).get_center())
	assert_array(changes).is_equal(["change"])
	assert_int(page.rules.row).is_equal(2)
	assert_int(page.rules.slot).is_equal(1)
	_left_click(page, Vector2(ControlsPage.NAME_X + 4, ControlsPage.row_rect(3).get_center().y))
	assert_array(changes).is_equal(["change"])

func test_losing_focus_changes_nothing() -> void:
	await _open_page()
	pause._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_bool(page.visible).is_true()
	assert_bool(get_tree().paused).is_true()

func test_changed_pause_key_resumes() -> void:
	var back := InputEventJoypadButton.new()
	back.button_index = JOY_BUTTON_BACK
	InputDevice.controls.set_slot(A.PAUSE, D.CONTROLLER, 0, back)
	await _open_page()
	await _pad(JOY_BUTTON_BACK)
	assert_bool(get_tree().paused).is_false()
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_ENTER)
	assert_bool(page.visible).is_true()
	await _pad(JOY_BUTTON_START)
	assert_bool(get_tree().paused).is_true()
	assert_bool(page.visible).is_true()
