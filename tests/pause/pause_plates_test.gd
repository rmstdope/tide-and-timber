extends GdUnitTestSuite
## The Paused board's rows and its quit box's buttons are plain plates: the chosen one has ink words,
## the rest cream.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause

func before_test() -> void:
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

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _words(unique: String) -> Color:
	return (pause.get_node("%" + unique).get_node("Label/Words") as Label).get_theme_color("font_color")

func _open() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)

func _row_words(item: PauseMenu.Plank) -> Color:
	return (pause._plank(item).get_node("Label/Words") as Label).get_theme_color("font_color")

func test_the_highlighted_row_has_ink_words_and_the_rest_cream() -> void:
	await _open()
	var items := pause.rules.items
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.RESUME)
	assert_that(_row_words(items[0])).is_equal(HudColours.INK)
	for item: PauseMenu.Plank in items.slice(1):
		assert_that(_row_words(item)).is_equal(HudColours.CREAM)
	await _tap(KEY_DOWN)
	assert_that(_row_words(items[1])).is_equal(HudColours.INK)
	assert_that(_row_words(items[0])).is_equal(HudColours.CREAM)

func test_the_quit_box_buttons_follow_the_selection() -> void:
	await _open()
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)
	assert_bool(pause.rules.box_open).is_true()
	var chosen := "Stay" if pause.rules.box_selected == PauseMenu.Choice.STAY else "Quit"
	var other := "Quit" if chosen == "Stay" else "Stay"
	assert_that(_words(chosen)).is_equal(HudColours.INK)
	assert_that(_words(other)).is_equal(HudColours.CREAM)
