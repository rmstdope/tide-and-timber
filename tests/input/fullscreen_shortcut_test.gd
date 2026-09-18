extends GdUnitTestSuite
## The fixed fullscreen shortcut through the real window: it flips the remembered setting on every screen
## and is never also taken as Select or any game key.

var runner: GdUnitSceneRunner
var calls: Array[String] = []

func before_test() -> void:
	Pause.debug_tools = false
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset(PackedStringArray(), false)
	calls = []

func after_test() -> void:
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.use_controls(Controls.new())
	InputDevice.reset()

func _send(physical: Key, pressed: bool, alt := false, meta := false) -> void:
	var k := InputEventKey.new()
	k.physical_keycode = physical
	k.keycode = physical
	k.key_label = physical
	k.pressed = pressed
	k.alt_pressed = alt
	k.meta_pressed = meta
	Input.parse_input_event(k)
	Input.flush_buffered_events()
	await runner.await_input_processed()

## The whole Windows shortcut as the OS sends it: Alt down, Enter down, Enter up, Alt up.
func _alt_enter() -> void:
	await _send(KEY_ALT, true, true)
	await _send(KEY_ENTER, true, true)
	await _send(KEY_ENTER, false, true)
	await _send(KEY_ALT, false)

func _cmd_enter() -> void:
	await _send(KEY_META, true, false, true)
	await _send(KEY_ENTER, true, false, true)
	await _send(KEY_ENTER, false, false, true)
	await _send(KEY_META, false)

func _title() -> TitleScreen:
	runner = scene_runner("res://src/title/title_screen.tscn")
	var screen := runner.scene() as TitleScreen
	var recorded := calls
	screen.quit_game = func() -> void: recorded.append("quit")
	screen.start_new_game = func() -> void: recorded.append("new_game")
	screen.start_continue = func() -> void: recorded.append("continue")
	screen.read_save("user://test_saves/fullscreen_none")
	return screen

# A pick on the title locks the menu at once, then fades before it calls out.
func test_alt_enter_through_the_window_toggles_and_is_not_select() -> void:
	var screen := _title()
	await _alt_enter()
	assert_bool(Display.prefs.fullscreen).is_true()
	assert_bool(screen.menu.locked).is_false()
	await _alt_enter()
	assert_bool(Display.prefs.fullscreen).is_false()
	assert_bool(screen.menu.locked).is_false()
	assert_array(calls).is_empty()

func test_cmd_enter_on_mac() -> void:
	InputDevice.reset(PackedStringArray(), true)
	var screen := _title()
	await _cmd_enter()
	assert_bool(Display.prefs.fullscreen).is_true()
	assert_bool(screen.menu.locked).is_false()
	await _alt_enter()   # not this platform's shortcut: plain Select
	assert_bool(Display.prefs.fullscreen).is_true()
	assert_bool(screen.menu.locked).is_true()

func test_plain_enter_still_selects() -> void:
	var screen := _title()
	await _send(KEY_ENTER, true)
	await _send(KEY_ENTER, false)
	assert_bool(Display.prefs.fullscreen).is_false()
	assert_bool(screen.menu.locked).is_true()

func test_on_the_pause_board_nothing_resumes() -> void:
	runner = scene_runner("res://src/waking/waking.tscn")
	var waking := runner.scene() as Waking
	waking.set_process(false)
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK
	var pause := waking.get_node("%Pause") as Pause
	waking.tick(5.0)
	await _send(KEY_ESCAPE, true)
	await _send(KEY_ESCAPE, false)
	assert_bool(get_tree().paused).is_true()
	var highlighted := pause.rules.highlighted
	await _alt_enter()
	assert_bool(Display.prefs.fullscreen).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_bool(pause.rules.is_open).is_true()
	assert_int(pause.rules.highlighted).is_equal(highlighted)

func test_during_the_intro_nothing_advances() -> void:
	runner = scene_runner("res://src/intro/intro.tscn")
	var intro := runner.scene() as Intro
	intro.end_story = func() -> void: pass
	var story := intro.story
	var panel := story.panel
	await _alt_enter()
	assert_bool(Display.prefs.fullscreen).is_true()
	assert_int(story.panel).is_equal(panel)
	assert_int(story.held_count).is_equal(0)
	assert_bool(story.skip_hint_shown).is_false()
