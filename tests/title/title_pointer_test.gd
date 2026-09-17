extends GdUnitTestSuite
## The title screen hides the pointer on a key or pad press and follows it only when it moves.

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

# A mouse movement straight to a control, as Godot delivers one over it.
func _move_over(control: Control, relative := Vector2(1, 0)) -> void:
	var move := InputEventMouseMotion.new()
	move.relative = relative
	control.gui_input.emit(move)

# A mouse movement through the window, so InputDevice sees it.
func _mouse_moved() -> void:
	var move := InputEventMouseMotion.new()
	move.position = Vector2(4, 4)
	move.relative = Vector2(2, 0)
	Input.parse_input_event(move)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func test_opens_with_the_pointer_shown() -> void:
	assert_bool(InputDevice.pointer.hidden).is_false()

func test_a_key_hides_the_pointer() -> void:
	await _press(KEY_DOWN)
	assert_bool(InputDevice.pointer.hidden).is_true()

func test_a_pad_press_hides_the_pointer() -> void:
	await _pad(JOY_BUTTON_DPAD_DOWN)
	assert_bool(InputDevice.pointer.hidden).is_true()

func test_moving_the_mouse_shows_it_again() -> void:
	await _press(KEY_DOWN)
	await _mouse_moved()
	assert_bool(InputDevice.pointer.hidden).is_false()

func test_resting_pointer_does_not_pull_the_highlight() -> void:
	await _press(KEY_DOWN)
	assert_highlighted("Settings")
	_plank("NewGame").mouse_entered.emit()
	assert_highlighted("Settings")
	_move_over(_plank("NewGame"), Vector2.ZERO)
	assert_highlighted("Settings")

func test_moving_over_a_plank_highlights_it() -> void:
	await _press(KEY_DOWN)
	_move_over(_plank("NewGame"))
	assert_highlighted("NewGame")

func test_leaving_the_title_shows_the_pointer() -> void:
	await _press(KEY_DOWN)
	assert_bool(InputDevice.pointer.hidden).is_true()
	var parent := screen.get_parent()
	parent.remove_child(screen)
	assert_bool(InputDevice.pointer.hidden).is_false()
	parent.add_child(screen)
