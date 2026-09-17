extends GdUnitTestSuite
## Changing a slot on the Controls page opened from the title: Start goes in, and the hold ring runs unpaused.

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/title_change_slot_none"   # never created

var runner: GdUnitSceneRunner
var screen: TitleScreen
var page: ControlsPage

func before_test() -> void:
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	page = (screen.get_node("%SettingsBoard") as SettingsBoard).get_node("%ControlsPage") as ControlsPage
	screen.quit_game = func() -> void: pass
	screen.start_new_game = func() -> void: pass
	screen.start_continue = func() -> void: pass
	screen.read_save(NO_SAVE)
	page.pad_connected = func() -> bool: return true

func after_test() -> void:
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
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

func _open_page() -> void:
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)
	await _press(KEY_ENTER)
	assert_bool(page.visible).is_true()

func test_start_goes_into_the_slot_from_the_title() -> void:
	await _open_page()
	await _press(KEY_E)
	await _press(KEY_ENTER)
	await _pad(JOY_BUTTON_START)
	var b := InputDevice.controls.slot(Controls.Action.WALK_UP, Controls.Device.CONTROLLER, 0) as InputEventJoypadButton
	assert_object(b).is_not_null()
	assert_int(b.button_index).is_equal(JOY_BUTTON_START)
	assert_bool(page.visible).is_true()

func test_esc_held_cancels_from_the_title() -> void:
	await _open_page()
	await _press(KEY_ENTER)
	var box := page.get_node("%WaitingBox") as WaitingBox
	assert_bool(box.visible).is_true()
	runner.simulate_key_press(KEY_ESCAPE)
	await runner.await_input_processed()
	await get_tree().create_timer(0.5, true).timeout
	assert_bool(box.ring.visible).is_true()
	await get_tree().create_timer(0.8, true).timeout
	assert_bool(box.visible).is_false()
	assert_int((InputDevice.controls.slot(Controls.Action.WALK_UP, Controls.Device.KEYBOARD, 0) as InputEventKey).physical_keycode).is_equal(KEY_W)
	runner.simulate_key_release(KEY_ESCAPE)
	await runner.await_input_processed()
	assert_bool(page.visible).is_true()
