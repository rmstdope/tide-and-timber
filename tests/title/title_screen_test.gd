extends GdUnitTestSuite

const SCENE := "res://src/title/title_screen.tscn"
const NO_SAVE := "user://test_saves/title_none"   # never created

var runner: GdUnitSceneRunner
var screen: TitleScreen
var calls: Array[String] = []

func before_test() -> void:
	calls = []
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	var recorded := calls
	screen.quit_game = func() -> void: recorded.append("quit")
	screen.start_new_game = func() -> void: recorded.append("new_game")
	screen.start_continue = func() -> void: recorded.append("continue")
	screen.read_save(NO_SAVE)

func _plank(unique: String) -> PanelContainer:
	return screen.get_node("%" + unique) as PanelContainer

func assert_highlighted(unique: String) -> void:
	for plank: String in ["Continue", "NewGame", "Settings", "Quit"]:
		var want := TitleScreen.PLANK_HIGHLIGHT_STYLE if plank == unique else TitleScreen.PLANK_STYLE
		assert_object(_plank(plank).get_theme_stylebox("panel")) \
			.override_failure_message("%s should%s be highlighted" % [plank, "" if plank == unique else " not"]) \
			.is_same(want)

func _fade_alpha() -> float:
	return (screen.get_node("%Fade") as CanvasItem).modulate.a

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_opens_with_new_game_highlighted() -> void:
	assert_highlighted("NewGame")
	assert_float(_fade_alpha()).is_equal(0.0)

func test_shows_the_agreed_words() -> void:
	assert_str((screen.get_node("Title") as Label).text).is_equal("TIDE & TIMBER")
	assert_str((screen.get_node("Tagline") as Label).text).is_equal("a story of an island")
	assert_str((screen.get_node("MenuClip/Menu/NewGame/Label/Words") as Label).text).is_equal("New Game")
	assert_str((screen.get_node("MenuClip/Menu/Quit/Label/Words") as Label).text).is_equal("Quit")
	assert_str((screen.get_node("%Version") as Label).text).is_equal("v0.1")

func test_whole_screen_fits_the_base_viewport() -> void:
	var view := screen.get_viewport_rect()
	assert_vector(screen.size).is_equal(view.size)
	var version := (screen.get_node("%Version") as Control).get_global_rect()
	assert_bool(view.encloses(version)) \
		.override_failure_message("version at %s is outside %s" % [version, view]).is_true()

func test_down_and_s_move_and_wrap() -> void:
	await _press(KEY_DOWN)
	assert_highlighted("Settings")
	await _press(KEY_S)
	assert_highlighted("Quit")

func test_up_and_w_move_and_wrap() -> void:
	await _press(KEY_UP)
	assert_highlighted("Quit")
	await _press(KEY_W)
	assert_highlighted("Settings")

func test_escape_does_nothing() -> void:
	await _press(KEY_ESCAPE)
	assert_highlighted("NewGame")
	assert_array(calls).is_empty()
	assert_float(_fade_alpha()).is_equal(0.0)

func _click(unique: String, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	_plank(unique).gui_input.emit(event)

func test_hover_moves_the_highlight_and_keys_carry_on() -> void:
	_move_over(_plank("Quit"))
	assert_highlighted("Quit")
	await _press(KEY_DOWN)
	assert_highlighted("NewGame")

func test_left_click_on_quit_quits() -> void:
	_click("Quit", MOUSE_BUTTON_LEFT)
	assert_array(calls).is_equal(["quit"])

func test_right_click_on_a_plank_does_nothing() -> void:
	_click("Quit", MOUSE_BUTTON_RIGHT)
	_click("NewGame", MOUSE_BUTTON_RIGHT)
	assert_array(calls).is_empty()

func test_click_off_the_menu_does_nothing() -> void:
	runner.simulate_mouse_move(Vector2(10, 10))
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()
	assert_array(calls).is_empty()
	assert_highlighted("NewGame")

func test_enter_on_quit_quits_at_once() -> void:
	await _press(KEY_DOWN)
	await _press(KEY_DOWN)
	runner.simulate_key_press(KEY_ENTER)
	assert_array(calls).is_equal(["quit"])
	runner.simulate_key_release(KEY_ENTER)

func test_space_on_new_game_fades_then_starts() -> void:
	await _press(KEY_SPACE)
	assert_array(calls).is_empty()
	assert_bool(screen.menu.locked).is_true()
	await await_millis(1300)
	assert_array(calls).is_equal(["new_game"])
	assert_float(_fade_alpha()).is_equal(1.0)

func test_input_during_fade_is_ignored() -> void:
	await _press(KEY_ENTER)
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)
	await _press(KEY_SPACE)
	_move_over(_plank("Quit"))
	_click("Quit", MOUSE_BUTTON_LEFT)
	assert_highlighted("NewGame")
	await await_millis(1300)
	assert_array(calls).is_equal(["new_game"])

func test_waves_move() -> void:
	var waves := screen.get_node("%Waves").get_children()
	var recorded: Array[float] = [20.0, 100.0, 190.0, 330.0, 470.0]   # home x in title_screen.tscn
	await runner.simulate_frames(1, 25)
	var first: Array[float] = []
	for wave: Control in waves:
		first.append(wave.position.x)
	await runner.simulate_frames(30, 25)
	var any_moved := false
	for i in waves.size():
		var drift: float = (waves[i] as Control).position.x - recorded[i]
		any_moved = any_moved or (waves[i] as Control).position.x != first[i]
		assert_float(absf(drift)).is_less_equal(TitleScreen.WAVE_AMPLITUDE_PX)
	assert_bool(any_moved).is_true()

func test_no_save_shows_three_planks() -> void:
	assert_bool(_plank("Continue").visible).is_false()
	assert_float((screen.get_node("%Menu") as Control).position.y).is_equal(TitleScreen.MENU_TOP)

# A mouse movement straight to a control, as Godot delivers one over it.
func _move_over(control: Control, relative := Vector2(1, 0)) -> void:
	var move := InputEventMouseMotion.new()
	move.relative = relative
	control.gui_input.emit(move)
