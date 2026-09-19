extends GdUnitTestSuite
## The Paused board at a larger Text size: the heading and the plank words grow, the planks widen and
## grow taller to fit them, and the board follows. A plank's words wrap only when they cannot fit the screen.

const S := DisplayPrefs.Setting

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Pause.debug_tools = false
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause") as Pause
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode

func _tap(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()

func _open() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _settle()

func _node(unique: String) -> Control:
	return pause.get_node("%" + unique) as Control

func _screen(n: Control) -> Rect2:
	return n.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, n.size)

## A board of that size centred on the picture, as lay_out() rests it.
func _centred(size: Vector2) -> Rect2:
	return Rect2(((Screen.SIZE - size) / 2.0).floor(), size)

func _words(unique: String) -> GrownWords:
	return _node(unique).get_node("Label") as GrownWords

func test_normal_text_lays_out_as_before() -> void:
	await _open()
	assert_that(pause.rest_panel).is_equal(_centred(Vector2(144, 96)))
	assert_that(_node("Resume").get_rect()).is_equal(Rect2(12, 28, 120, 16))
	assert_that(_node("QuitToTitle").get_rect()).is_equal(Rect2(12, 68, 120, 16))
	assert_vector(_node("Heading").scale).is_equal(Vector2.ONE)

func test_large_text_widens_the_planks_and_the_board() -> void:
	Display.prefs.step(S.TEXT_SIZE, 1)
	await _open()
	assert_that(pause.rest_panel).is_equal(_centred(Vector2(184, 112)))
	assert_that(_node("Resume").get_rect()).is_equal(Rect2(12, 32, 160, 20))
	assert_that(_node("Settings").get_rect()).is_equal(Rect2(12, 56, 160, 20))
	assert_that(_node("QuitToTitle").get_rect()).is_equal(Rect2(12, 80, 160, 20))
	assert_vector(_node("Heading").scale).is_equal(Vector2(1.5, 1.5))
	assert_float(_node("Heading").size.x).is_equal_approx(184.0 / 1.5, 0.01)
	assert_bool(_words("QuitToTitle").wrapped).is_false()
	assert_bool(pause.scrolls).is_false()

## The band above the strip the board is framed to, in board units.
func _band() -> Vector2:
	return ScrollWindow.band((_node("Board")).get_global_transform_with_canvas(), pause.strip.screen_top())

# Retired in tr-1o0.1: the quit box stacking and scrolling; it fits at every size and window. Since tr-1ci.1
# the item bar is 12 taller, so the strip lifts 24 higher at Largest and the three-plank Paused board, 128
# tall, scrolls again in the 121-tall band (accepted by the navigator). This is what fails if a later change
# grows the quit box past the room above the strip, or makes the board fit again unnoticed.
func test_at_the_largest_sizes_the_board_scrolls_and_the_quit_box_fits_above_the_strip(
		window: Vector2i, test_parameters := [[Vector2i(1280, 720)], [Vector2i(640, 360)]]) -> void:
	get_tree().root.size = window
	Display.prefs.step(S.UI_SIZE, 2)
	Display.prefs.step(S.TEXT_SIZE, 2)
	await _open()
	var b := _band()
	assert_float(b.y - b.x).is_equal(121.0)
	assert_float(pause.rest_panel.size.y).is_equal(128.0)
	assert_bool(pause.scrolls).is_true()
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)
	await _settle()
	assert_bool(pause._quit_box.stacked).override_failure_message("the quit box stacks").is_false()
	assert_bool(pause._quit_frame.scrolls).override_failure_message("the quit box scrolls").is_false()

func test_text_size_change_keeps_the_highlight() -> void:
	await _open()
	await _tap(KEY_DOWN)
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.SETTINGS)
	Display.prefs.step(S.TEXT_SIZE, 1)
	await _settle()
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.SETTINGS)
	assert_float(pause.rest_panel.size.x).is_equal(184.0)
	Display.use_prefs(DisplayPrefs.new())
	await _settle()
	assert_that(pause.rest_panel).is_equal(_centred(Vector2(144, 96)))
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.SETTINGS)
