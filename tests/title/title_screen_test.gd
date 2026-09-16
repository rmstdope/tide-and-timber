extends GdUnitTestSuite

const SCENE := "res://src/title/title_screen.tscn"

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

func _plank(unique: String) -> PanelContainer:
	return screen.get_node("%" + unique) as PanelContainer

func assert_highlighted(unique: String) -> void:
	var other := "Quit" if unique == "NewGame" else "NewGame"
	assert_object(_plank(unique).get_theme_stylebox("panel")) \
		.override_failure_message("%s should be highlighted" % unique) \
		.is_same(TitleScreen.PLANK_HIGHLIGHT_STYLE)
	assert_object(_plank(other).get_theme_stylebox("panel")) \
		.override_failure_message("%s should not be highlighted" % other) \
		.is_same(TitleScreen.PLANK_STYLE)

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
	assert_str((screen.get_node("Menu/NewGame/Label") as Label).text).is_equal("New Game")
	assert_str((screen.get_node("Menu/Quit/Label") as Label).text).is_equal("Quit")
	assert_str((screen.get_node("%Version") as Label).text).is_equal("v0.1")

func test_down_and_s_move_and_wrap() -> void:
	await _press(KEY_DOWN)
	assert_highlighted("Quit")
	await _press(KEY_S)
	assert_highlighted("NewGame")

func test_up_and_w_move_and_wrap() -> void:
	await _press(KEY_UP)
	assert_highlighted("Quit")
	await _press(KEY_W)
	assert_highlighted("NewGame")

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
	_plank("Quit").mouse_entered.emit()
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
	_plank("Quit").mouse_entered.emit()
	_click("Quit", MOUSE_BUTTON_LEFT)
	assert_highlighted("NewGame")
	await await_millis(1300)
	assert_array(calls).is_equal(["new_game"])
