extends GdUnitTestSuite
## The Controls page opened from the title: Back returns to the board, Start does nothing, the page covers the title.

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/title_controls_none"   # never created

var runner: GdUnitSceneRunner
var screen: TitleScreen
var board: SettingsBoard
var page: ControlsPage

func before_test() -> void:
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	board = screen.get_node("%SettingsBoard") as SettingsBoard
	page = board.get_node("%ControlsPage") as ControlsPage
	screen.quit_game = func() -> void: pass
	screen.start_new_game = func() -> void: pass
	screen.start_continue = func() -> void: pass
	screen.read_save(NO_SAVE)

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

func test_back_returns_to_the_board_on_controls() -> void:
	await _open_page()
	assert_bool(page.visible).is_true()
	await _press(KEY_ESCAPE)
	assert_bool(page.visible).is_false()
	assert_bool(board.visible).is_true()
	assert_bool(board.get_node("%Panel").visible).is_true()
	assert_bool(is_same((board.get_node("%Controls") as Control).get_theme_stylebox("panel"),
		SettingsBoard.PLANK_HIGHLIGHT_STYLE)).is_true()

func test_start_does_nothing_from_the_title() -> void:
	await _open_page()
	InputDevice.controls.clear_slot(Controls.Action.BUILD_LIST, Controls.Device.KEYBOARD, 0)
	await _pad(JOY_BUTTON_START)
	assert_bool(page.visible).is_true()
	assert_int(page.rules.box).is_equal(ControlsMenu.Box.NONE)

func test_page_covers_the_title() -> void:
	await _open_page()
	assert_int(page.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	assert_that(page.get_global_rect()).is_equal(Rect2(0, 0, 320, 180))
