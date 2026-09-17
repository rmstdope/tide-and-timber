extends GdUnitTestSuite
## The title screen's Select strip: bottom-left, clear of the version, following the device used last.

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/title_none"   # never created

var runner: GdUnitSceneRunner
var screen: TitleScreen
var calls: Array[String] = []

func before_test() -> void:
	InputDevice.reset()
	calls = []
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	var recorded := calls
	screen.quit_game = func() -> void: recorded.append("quit")
	screen.start_new_game = func() -> void: recorded.append("new_game")
	screen.start_continue = func() -> void: recorded.append("continue")
	screen.read_save(NO_SAVE)

func after_test() -> void:
	InputDevice.reset()

func _plank(unique: String) -> PanelContainer:
	return screen.get_node("%" + unique) as PanelContainer

func assert_highlighted(unique: String) -> void:
	for plank: String in ["Continue", "NewGame", "Settings", "Quit"]:
		var want := TitleScreen.PLANK_HIGHLIGHT_STYLE if plank == unique else TitleScreen.PLANK_STYLE
		assert_object(_plank(plank).get_theme_stylebox("panel")) \
			.override_failure_message("%s should%s be highlighted" % [plank, "" if plank == unique else " not"]) \
			.is_same(want)

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

func _mouse_moved() -> void:
	var move := InputEventMouseMotion.new()
	move.position = Vector2(300, 20)
	move.relative = Vector2(2, 0)
	Input.parse_input_event(move)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func _mouse_clicked() -> void:
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = Vector2(300, 20)
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		Input.parse_input_event(click)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func test_opens_with_enter_select_only() -> void:
	assert_str(screen.strip.text()).is_equal("[Enter] Select")
	assert_bool(screen.strip.is_visible_in_tree()).is_true()
	assert_vector(screen.strip.position).is_equal(Vector2(4, 164))

func test_opens_with_the_pads_select_when_a_pad_is_connected() -> void:
	InputDevice.reset(PackedStringArray(["Xbox Series Controller"]))
	assert_str(screen.strip.text()).is_equal("(A) Select")

func test_pad_press_switches_it() -> void:
	await _pad(JOY_BUTTON_DPAD_DOWN)
	assert_str(screen.strip.text()).is_equal("(A) Select")

func test_mouse_moved_after_the_pad_keeps_the_pad() -> void:
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _mouse_moved()
	assert_str(screen.strip.text()).is_equal("(A) Select")

func test_mouse_clicked_after_the_pad_shows_keys() -> void:
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _mouse_clicked()
	assert_str(screen.strip.text()).is_equal("[Enter] Select")

func test_back_changes_nothing() -> void:
	await _press(KEY_ESCAPE)
	assert_str(screen.strip.text()).is_equal("[Enter] Select")
	await _pad(JOY_BUTTON_B)
	assert_str(screen.strip.text()).is_equal("(A) Select")
	assert_highlighted("NewGame")

func test_unplugging_the_last_pad_shows_keys_and_leaves_the_menu() -> void:
	await _pad(JOY_BUTTON_DPAD_DOWN)
	assert_highlighted("Settings")
	InputDevice.tracker.pad_disconnected(0, PackedStringArray())
	assert_str(screen.strip.text()).is_equal("[Enter] Select")
	assert_highlighted("Settings")

func test_sits_above_the_boxes_and_under_the_fade() -> void:
	assert_int(screen.strip.get_index()).is_greater(screen.get_node("%ReplaceBox").get_index())
	assert_int(screen.strip.get_index()).is_greater(screen.get_node("%StartOverBox").get_index())
	assert_int(screen.strip.get_index()).is_less(screen.get_node("%Fade").get_index())

func test_widest_strip_clears_the_version() -> void:
	screen.strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	assert_float(screen.strip.position.x + screen.strip.size.x) \
		.is_less((screen.get_node("%Version") as Control).position.x)
