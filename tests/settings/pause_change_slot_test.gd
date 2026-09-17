extends GdUnitTestSuite
## Changing a slot on the Controls page opened from the Paused board: the waiting box, Esc / B tap and
## hold, wrong device, sticks, no controller, a pad unplugging, and a changed Pause button.

const A := Controls.Action
const D := Controls.Device

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var board: SettingsBoard
var page: ControlsPage

func before_test() -> void:
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	board = pause.get_node("%SettingsBoard")
	page = board.get_node("%ControlsPage")
	pause.quit_to_title = func() -> void: pass
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK
	page.pad_connected = func() -> bool: return true

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

func _axis(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func _click(at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	page.gui_input.emit(click)
	await runner.await_input_processed()

func _real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _open_page() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_ENTER)
	assert_bool(page.visible).is_true()

func _down(times: int) -> void:
	for i in times:
		await _tap(KEY_DOWN)

func _box() -> WaitingBox:
	return page.get_node("%WaitingBox") as WaitingBox

func _ks() -> Controls:
	return InputDevice.controls

func _wait_on_use() -> void:
	await _open_page()
	await _down(5)
	await _tap(KEY_ENTER)
	assert_bool(_box().visible).is_true()

func _controller_tab_on(p_row: int) -> void:
	await _open_page()
	await _tap(KEY_E)
	await _down(p_row)
	await _tap(KEY_ENTER)

func test_enter_opens_the_waiting_box() -> void:
	await _wait_on_use()
	assert_bool((page.get_node("%Box") as Control).visible).is_false()
	assert_bool(page.strip.visible).is_false()
	assert_array(Array(_box().lines)).is_equal(["Use / take", "Press a new key"])
	assert_bool(get_tree().paused).is_true()

func test_a_key_goes_in_and_saves_to_the_model() -> void:
	await _wait_on_use()
	await _tap(KEY_F)
	assert_bool(_box().visible).is_false()
	assert_int((_ks().slot(A.USE, D.KEYBOARD, 0) as InputEventKey).physical_keycode).is_equal(KEY_F)
	assert_int(page.rules.row).is_equal(5)
	assert_int(page.rules.slot).is_equal(0)
	assert_bool(page.strip.visible).is_true()

func test_esc_tap_goes_in_not_back() -> void:
	await _wait_on_use()
	await _tap(KEY_ESCAPE)
	assert_bool(page.visible).is_true()
	assert_bool(_box().visible).is_false()
	assert_int((_ks().slot(A.USE, D.KEYBOARD, 0) as InputEventKey).physical_keycode).is_equal(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_true()
	assert_object(_ks().slot(A.PAUSE, D.KEYBOARD, 0)).is_null()
	assert_bool(page.rules.is_orange(7)).is_true()
	assert_str(page.rules.no_key_line).is_equal("Pause has no key")

func test_esc_held_cancels() -> void:
	await _wait_on_use()
	runner.simulate_key_press(KEY_ESCAPE)
	await runner.await_input_processed()
	await _real_seconds(0.5)
	assert_bool(_box().ring.visible).is_true()
	await _real_seconds(0.8)
	assert_bool(_box().visible).is_false()
	assert_int((_ks().slot(A.USE, D.KEYBOARD, 0) as InputEventKey).physical_keycode).is_equal(KEY_E)
	assert_bool(page.visible).is_true()
	runner.simulate_key_release(KEY_ESCAPE)
	await runner.await_input_processed()
	assert_bool(page.visible).is_true()

func test_click_and_pad_are_ignored_on_keyboard() -> void:
	await _wait_on_use()
	await _pad(JOY_BUTTON_A)
	await _click(ControlsPage.slot_rect(0, 0).get_center())
	assert_bool(_box().visible).is_true()
	assert_int(page.rules.row).is_equal(5)

func test_click_on_a_slot_opens_the_box() -> void:
	await _open_page()
	await _click(ControlsPage.slot_rect(4, 1).get_center())
	assert_bool(_box().visible).is_true()
	assert_str(_box().lines[0]).is_equal("Run (hold)")

func test_start_goes_into_the_slot() -> void:
	await _controller_tab_on(6)
	assert_array(Array(_box().lines)).is_equal(["Build list", "Press a new button"])
	await _pad(JOY_BUTTON_START)
	assert_bool(get_tree().paused).is_true()
	assert_bool(page.visible).is_true()
	assert_int((_ks().slot(A.BUILD_LIST, D.CONTROLLER, 0) as InputEventJoypadButton).button_index).is_equal(JOY_BUTTON_START)
	assert_object(_ks().slot(A.PAUSE, D.CONTROLLER, 0)).is_null()
	assert_str(page.rules.no_key_line).is_equal("Pause has no key")

func test_b_tap_goes_in() -> void:
	await _controller_tab_on(0)
	await _pad(JOY_BUTTON_B)
	assert_int((_ks().slot(A.WALK_UP, D.CONTROLLER, 0) as InputEventJoypadButton).button_index).is_equal(JOY_BUTTON_B)
	assert_bool(page.visible).is_true()

func test_stick_goes_in_and_does_not_move_the_page() -> void:
	await _controller_tab_on(4)
	await _axis(JOY_AXIS_LEFT_Y, 0.3)
	await _axis(JOY_AXIS_LEFT_Y, 0.9)
	await _axis(JOY_AXIS_LEFT_Y, 0.0)
	var m := _ks().slot(A.RUN, D.CONTROLLER, 0) as InputEventJoypadMotion
	assert_object(m).is_not_null()
	assert_int(m.axis).is_equal(JOY_AXIS_LEFT_Y)
	assert_float(signf(m.axis_value)).is_equal(1.0)
	assert_int(page.rules.row).is_equal(4)
	assert_bool(_ks().has_no_key(A.WALK_DOWN, D.CONTROLLER)).is_true()
	assert_str(page.rules.no_key_line).is_equal("Walk down has no key")

func test_keyboard_is_ignored_on_controller() -> void:
	await _controller_tab_on(0)
	await _tap(KEY_Q)
	assert_bool(_box().visible).is_true()

func test_no_controller_box() -> void:
	page.pad_connected = func() -> bool: return false
	await _controller_tab_on(0)
	assert_bool((page.get_node("%Box") as Control).visible).is_true()
	assert_bool(_box().visible).is_false()
	assert_str((page.get_node("%Lines") as Label).text).is_equal("Connect a controller to change its buttons.")
	assert_str((page.get_node("%Safe").get_node("Label") as Label).text).is_equal("OK")
	assert_bool((page.get_node("%Other") as Control).visible).is_false()
	await _pad(JOY_BUTTON_START)
	assert_bool((page.get_node("%Box") as Control).visible).is_true()
	assert_bool(get_tree().paused).is_true()
	await _tap(KEY_ENTER)
	assert_bool((page.get_node("%Box") as Control).visible).is_false()
	await _tap(KEY_ENTER)
	assert_bool((page.get_node("%Box") as Control).visible).is_true()
	await _tap(KEY_ESCAPE)
	assert_bool((page.get_node("%Box") as Control).visible).is_false()
	assert_bool(page.visible).is_true()

func test_pad_connecting_leaves_the_no_controller_box() -> void:
	page.pad_connected = func() -> bool: return false
	await _controller_tab_on(0)
	page._on_joy_connection_changed(0, true)
	assert_bool((page.get_node("%Box") as Control).visible).is_true()

func test_pad_disconnect_closes_the_waiting_box() -> void:
	await _controller_tab_on(0)
	page._on_joy_connection_changed(0, false)
	assert_bool(_box().visible).is_false()
	assert_int((_ks().slot(A.WALK_UP, D.CONTROLLER, 0) as InputEventJoypadMotion).axis).is_equal(JOY_AXIS_LEFT_Y)
	assert_bool(get_tree().paused).is_true()

func test_changed_pause_button_resumes() -> void:
	await _controller_tab_on(7)
	await _pad(JOY_BUTTON_Y)
	assert_bool(_ks().has_no_key(A.BUILD_LIST, D.CONTROLLER)).is_true()
	await _tap(KEY_ESCAPE)
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.LEAVING)
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_bool(page.visible).is_false()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()
	_control()
	await _pad(JOY_BUTTON_Y)
	assert_bool(get_tree().paused).is_true()
	await _pad(JOY_BUTTON_Y)
	assert_bool(get_tree().paused).is_false()
	_control()
	await _pad(JOY_BUTTON_START)
	assert_bool(get_tree().paused).is_false()
