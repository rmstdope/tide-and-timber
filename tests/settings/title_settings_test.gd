extends GdUnitTestSuite
## The Settings board opened from the title: Settings between New Game and Quit, Back returns, Start does nothing.

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/title_none"   # never created
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title_settings"
const C := TitleMenu.Choice

var runner: GdUnitSceneRunner
var screen: TitleScreen
var board: SettingsBoard
var calls: Array[String] = []

func before_test() -> void:
	InputDevice.reset()
	_open(NO_SAVE)

func after_test() -> void:
	InputDevice.reset()
	_rm(ROOT)

func _open(dir: String) -> void:
	calls = []
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	board = screen.get_node("%SettingsBoard") as SettingsBoard
	var recorded := calls
	screen.quit_game = func() -> void: recorded.append("quit")
	screen.start_new_game = func() -> void: recorded.append("new_game")
	screen.start_continue = func() -> void: recorded.append("continue")
	board.open_controls = func() -> void: recorded.append("controls")
	screen.read_save(dir)

func _rm(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	for d in DirAccess.get_directories_at(path):
		_rm(path.path_join(d))
	DirAccess.remove_absolute(path)

func _saved() -> void:
	var d := SaveData.new()
	var slots: Array[Dictionary] = [{}, {}, {}, {}, {}, {}, {}, {}]
	d.inventory_slots = slots
	var none: Array[Vector2i] = []
	d.taken = {"driftwood": none, "shellfish": none.duplicate()}
	d.player_position = Vector2(400, 200)
	d.clock_minutes = 4680.0
	SaveStore.save_slot(d, DIR)
	_open(DIR)

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

func _left_click(control: Control) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	control.gui_input.emit(click)

func _plank(unique: String) -> Control:
	return screen.get_node("%" + unique) as Control

func _is_highlighted(plank: Control) -> bool:
	return is_same(plank.get_theme_stylebox("panel"), TitleScreen.PLANK_HIGHLIGHT_STYLE)

func _controls_highlighted() -> void:
	assert_bool(_is_highlighted(board.get_node("%Controls") as Control)) \
		.override_failure_message("Controls is not highlighted").is_true()

func _open_board() -> void:
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)

func _assert_back_on_settings() -> void:
	assert_bool(board.visible).is_false()
	assert_bool(_is_highlighted(_plank("Settings"))).override_failure_message("Settings is not highlighted").is_true()
	assert_bool(screen.strip.visible).is_true()
	await _press(KEY_DOWN)
	assert_bool(_is_highlighted(_plank("Quit"))).override_failure_message("Quit is not highlighted").is_true()

func test_no_save_order_and_words() -> void:
	assert_str((screen.get_node("Menu/Settings/Label") as Label).text).is_equal("Settings")
	var order: Array[String] = []
	for child in screen.get_node("%Menu").get_children():
		if child is PanelContainer:
			order.append(child.name)
	assert_array(order).is_equal(["Continue", "NewGame", "Settings", "Quit"])
	assert_bool(_is_highlighted(_plank("NewGame"))).is_true()
	assert_float((screen.get_node("%Menu") as Control).position.y).is_equal(97.0)

func test_down_from_new_game_is_settings() -> void:
	await _press(KEY_DOWN)
	assert_bool(_is_highlighted(_plank("Settings"))).is_true()

func test_enter_on_settings_opens_the_board_on_controls() -> void:
	await _open_board()
	assert_bool(board.visible).is_true()
	_controls_highlighted()
	assert_bool(screen.strip.visible).is_false()
	assert_array(calls).is_empty()

func test_board_ignores_the_title_behind_it() -> void:
	await _open_board()
	await _press(KEY_DOWN)
	await _press(KEY_UP)
	_controls_highlighted()
	assert_int(screen.menu.highlighted).is_equal(C.SETTINGS)
	_left_click(_plank("Quit"))
	assert_array(calls).is_empty()

func test_esc_returns_to_the_title_on_settings() -> void:
	await _open_board()
	await _press(KEY_ESCAPE)
	await _assert_back_on_settings()

func test_b_returns_too() -> void:
	await _open_board()
	await _pad(JOY_BUTTON_B)
	await _assert_back_on_settings()

func test_start_does_nothing_from_the_title() -> void:
	await _open_board()
	await _pad(JOY_BUTTON_START)
	assert_bool(board.visible).is_true()
	_controls_highlighted()
	assert_array(calls).is_empty()

func test_click_on_settings_opens_the_board() -> void:
	_left_click(_plank("Settings"))
	assert_bool(board.visible).is_true()

func test_menu_fits_with_four_planks() -> void:
	_saved()
	assert_float((screen.get_node("%Menu") as Control).position.y).is_equal(83.0)
	await await_idle_frame()
	var menu := (screen.get_node("%Menu") as Control).get_global_rect()
	assert_bool(Rect2(0, 0, 320, 180).encloses(menu)).override_failure_message("menu at %s" % menu).is_true()
	assert_bool(menu.intersects((screen.get_node("%Version") as Control).get_global_rect())).is_false()
