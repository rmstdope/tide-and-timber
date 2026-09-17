extends GdUnitTestSuite
## The title menu and its boxes on a pad: d-pad and stick move one step per push, A picks, B goes back.

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/title_none"   # never created
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title_pad"
const C := TitleMenu.Choice

var runner: GdUnitSceneRunner
var screen: TitleScreen
var calls: Array[String] = []

func before_test() -> void:
	InputDevice.reset()
	_open(NO_SAVE)

func after_test() -> void:
	InputDevice.reset()
	_send_stick(JOY_AXIS_LEFT_X, 0.0)
	_send_stick(JOY_AXIS_LEFT_Y, 0.0)
	InputDevice.reset()
	_rm(ROOT)

func _open(dir: String) -> void:
	calls = []
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	var recorded := calls
	screen.quit_game = func() -> void: recorded.append("quit")
	screen.start_new_game = func() -> void: recorded.append("new_game")
	screen.start_continue = func() -> void: recorded.append("continue")
	screen.read_save(dir)

func _rm(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	for d in DirAccess.get_directories_at(path):
		_rm(path.path_join(d))
	DirAccess.remove_absolute(path)

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

func _tap(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = button
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func _fade_alpha() -> float:
	return (screen.get_node("%Fade") as CanvasItem).modulate.a

func test_d_pad_moves_and_wraps() -> void:
	await _tap(JOY_BUTTON_DPAD_DOWN)
	assert_int(screen.menu.highlighted).is_equal(C.SETTINGS)
	await _tap(JOY_BUTTON_DPAD_DOWN)
	assert_int(screen.menu.highlighted).is_equal(C.QUIT)
	await _tap(JOY_BUTTON_DPAD_UP)
	assert_int(screen.menu.highlighted).is_equal(C.SETTINGS)

func test_held_stick_moves_one_step() -> void:
	for v: float in [0.3, 0.6, 0.9, 1.0]:
		await _stick(JOY_AXIS_LEFT_Y, v)
	assert_int(screen.menu.highlighted).is_equal(C.SETTINGS)

func test_stick_pushes_again_after_centre() -> void:
	for v: float in [1.0, 0.0, 1.0]:
		await _stick(JOY_AXIS_LEFT_Y, v)
	assert_int(screen.menu.highlighted).is_equal(C.QUIT)

func test_a_picks_quit() -> void:
	await _tap(JOY_BUTTON_DPAD_DOWN)
	await _tap(JOY_BUTTON_DPAD_DOWN)
	await _tap(JOY_BUTTON_A)
	assert_array(calls).is_equal(["quit"])

func test_b_on_the_menu_does_nothing() -> void:
	await _tap(JOY_BUTTON_B)
	assert_int(screen.menu.highlighted).is_equal(C.NEW_GAME)
	assert_array(calls).is_empty()
	assert_float(_fade_alpha()).is_equal(0.0)

func test_stick_in_a_box_stops_at_the_ends() -> void:
	var d := SaveData.new()
	var slots: Array[Dictionary] = [{}, {}, {}, {}, {}, {}, {}, {}]
	d.inventory_slots = slots
	var none: Array[Vector2i] = []
	d.taken = {"driftwood": none, "shellfish": none.duplicate()}
	d.player_position = Vector2(400, 200)
	d.clock_minutes = 4680.0
	SaveStore.save_slot(d, DIR)
	_open(DIR)
	await _tap(JOY_BUTTON_DPAD_DOWN)
	await _tap(JOY_BUTTON_A)
	assert_int(screen.menu.box).is_equal(TitleMenu.Box.START_OVER)
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.START_OVER)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.START_OVER)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	await _stick(JOY_AXIS_LEFT_X, -1.0)
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.KEEP_MY_ISLAND)
	await _tap(JOY_BUTTON_B)
	assert_int(screen.menu.box).is_equal(TitleMenu.Box.NONE)

func test_pad_ignored_during_the_fade() -> void:
	await _tap(JOY_BUTTON_A)
	assert_bool(screen.menu.locked).is_true()
	await _tap(JOY_BUTTON_DPAD_DOWN)
	assert_int(screen.menu.highlighted).is_equal(C.NEW_GAME)
	assert_array(calls).is_empty()
