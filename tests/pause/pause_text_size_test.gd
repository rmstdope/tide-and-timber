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

func test_largest_ui_and_text_wrap_only_the_long_plank() -> void:
	Display.prefs.step(S.UI_SIZE, 2)
	Display.prefs.step(S.TEXT_SIZE, 2)
	await _open()
	# Precondition: the layout under test. At 640x360 no UI/Text combination reaches it (tr-1o0.1:
	# UI Largest + Text Largest rests a 236x128 board that neither wraps nor scrolls); navigator decision.
	assert_bool(_words("QuitToTitle").wrapped).override_failure_message("the long plank does not wrap").is_true()
	assert_bool(pause.scrolls).override_failure_message("the board does not scroll").is_true()
	assert_that(pause.rest_panel).is_equal(Rect2(82, -7, 156, 194))
	assert_bool(_words("QuitToTitle").wrapped).is_true()
	assert_bool(_words("Settings").wrapped).is_false()
	assert_vector(_node("Resume").size).is_equal(Vector2(132, 46))
	assert_vector(_node("Settings").size).is_equal(Vector2(132, 46))
	assert_vector(_node("QuitToTitle").size).is_equal(Vector2(132, 46))
	assert_bool(pause.scrolls).is_true()
	for name: String in ["Resume", "Settings", "QuitToTitle"]:
		var r := _screen(_node(name))
		assert_float(r.position.x).is_greater_equal(0.0)
		assert_float(r.end.x).is_less_equal(Screen.WIDTH)
	# The highlighted plank is now taller than the band above the strip, so the scroll brings its top
	# to the view's top and nothing of it is hidden above.
	assert_float(_screen(_node("Resume")).position.y).is_equal(_screen(_node("Clip")).position.y)
	assert_int(pause.scroll_offset).is_equal(28)

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
