extends GdUnitTestSuite
## The Debug panel's Time page on the beach and in the shipwreck story.

var runner: GdUnitSceneRunner
var waking: Waking
var dn: DayNight
var panel: DebugPanel

func before_test() -> void:
	Pause.debug_tools = true
	InputDevice.reset()
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	dn = waking.get_node("%DayNight") as DayNight
	panel = waking.get_node("%Pause").get_node("%DebugPanel") as DebugPanel
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	Input.action_release("menu_right")
	get_tree().paused = false
	Pause.debug_tools = OS.is_debug_build()
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _tap(key: Key, r: GdUnitSceneRunner = runner) -> void:
	await r.simulate_key_pressed(key)
	await r.await_input_processed()

# gdUnit4's await_millis stops with the paused tree; this timer runs through a pause.
func _real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _open_panel() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)

func _values(rules: DebugMenu) -> Array:
	return rules.rows_of(DebugMenu.Page.TIME).map(func(r: DebugRow) -> String: return r.value_text())

func test_time_page_shows_day_time_speed() -> void:
	await _open_panel()
	assert_bool(panel.rules.is_open).is_true()
	var rows := panel.rules.rows_of(DebugMenu.Page.TIME)
	assert_array(rows.map(func(r: DebugRow) -> String: return r.label)).is_equal(["Day", "Time", "Speed"])
	assert_array(_values(panel.rules)).is_equal(["1", "13:00", "x1"])

func test_right_on_day_changes_the_clock_while_paused() -> void:
	await _open_panel()
	await _tap(KEY_RIGHT)
	assert_int(dn.clock.day()).is_equal(2)
	assert_str((dn.get_node("%DayLabel") as Label).text).is_equal("DAY 2")
	assert_bool(get_tree().paused).is_true()

func test_speed_stops_at_x32() -> void:
	await _open_panel()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	for i in 8:
		await _tap(KEY_RIGHT)
	assert_str(_values(panel.rules)[2]).is_equal("x32")
	assert_float(dn.time_scale).is_equal(32.0)
	for i in 8:
		await _tap(KEY_LEFT)
	assert_str(_values(panel.rules)[2]).is_equal("x0.25")

func _hold_right() -> void:
	Input.action_press("menu_right")
	var e := InputEventKey.new()
	e.keycode = KEY_RIGHT
	e.physical_keycode = KEY_RIGHT
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func test_holding_right_on_time_repeats() -> void:
	await _open_panel()
	await _tap(KEY_DOWN)
	await _hold_right()
	await _real_seconds(0.65)
	assert_float(dn.clock.total_minutes).is_greater_equal(780.0 + 4 * 30)
	Input.action_release("menu_right")
	var minutes := dn.clock.total_minutes
	await _real_seconds(0.3)
	assert_float(dn.clock.total_minutes).is_equal(minutes)

func test_holding_right_on_day_does_not_repeat() -> void:
	await _open_panel()
	await _hold_right()
	await _real_seconds(0.65)
	assert_int(dn.clock.day()).is_equal(2)

func test_chosen_speed_drives_the_clock_after_resume() -> void:
	await _open_panel()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_RIGHT)
	await _tap(KEY_RIGHT)
	await _tap(KEY_ESCAPE)   # the panel closes; Escape again resumes from the board
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()
	var before := dn.clock.total_minutes
	dn.tick(90.0)
	assert_float(dn.clock.total_minutes).is_equal(before + 240.0)

func test_story_time_rows_dimmed_and_inert() -> void:
	waking.free()   # one scene at a time: the beach must not take the story's keys
	var story := scene_runner("res://src/intro/intro.tscn")
	var intro := story.scene() as Intro
	intro.end_story = func() -> void: pass
	var story_panel := intro.get_node("%Pause").get_node("%DebugPanel") as DebugPanel
	await _tap(KEY_ESCAPE, story)
	for i in 3:
		await _tap(KEY_DOWN, story)
	await _tap(KEY_ENTER, story)
	assert_bool(story_panel.rules.is_open).is_true()
	assert_array(_values(story_panel.rules)).is_equal(["1", "13:00", "x1"])
	await _tap(KEY_RIGHT, story)
	assert_array(_values(story_panel.rules)).is_equal(["1", "13:00", "x1"])
	assert_bool(story_panel.rules.page_works(DebugMenu.Page.TIME)).is_false()
