extends GdUnitTestSuite
## The Debug panel's Story page on the beach: the five points, the star, and a jump that fades out while paused.

const P := StoryPoints.Point

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var panel: DebugPanel
var resumed := 0
var jumps: Array = []

func before_test() -> void:
	Pause.debug_tools = true
	InputDevice.reset()
	resumed = 0
	jumps = []
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	waking.enter_story = func(p: StoryPoints.Point) -> void: jumps.append(p)
	pause = waking.get_node("%Pause")
	panel = pause.get_node("%DebugPanel") as DebugPanel
	pause.resumed.connect(func() -> void: resumed += 1)
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	get_tree().paused = false
	Pause.debug_tools = OS.is_debug_build()
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _node(unique: String) -> Node:
	return pause.get_node("%" + unique)

func _control() -> void:
	waking.tick(5.0)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
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

# gdUnit4's await_millis stops with the paused tree; this timer runs through a pause.
func _real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _set_clock(minutes: float) -> void:
	(waking.get_node("%DayNight") as DayNight).clock.total_minutes = minutes

func _open_story() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	for i in 3:
		await _tap(KEY_E)
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.STORY)

func _values() -> Array:
	return panel.rules.rows_of(DebugMenu.Page.STORY).map(func(r: DebugRow) -> String: return r.value_text())

func test_story_page_lists_points_with_star_on_first_day() -> void:
	_set_clock(960.0)
	await _open_story()
	assert_array(panel.rules.rows_of(DebugMenu.Page.STORY).map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Shipwreck story", "Waking on the beach", "First day", "First night", "Morning after"])
	assert_array(_values()).is_equal(["", "", "★", "", ""])

func test_star_on_waking_at_the_start() -> void:
	await _open_story()
	assert_array(_values()).is_equal(["", "★", "", "", ""])

func test_select_closes_panel_and_board_and_fades_while_paused() -> void:
	await _open_story()
	for i in 3:
		await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	assert_bool(panel.visible).is_false()
	assert_bool((_node("Board") as CanvasItem).visible).is_false()
	assert_bool(get_tree().paused).is_true()
	assert_bool((_node("Fade") as CanvasItem).visible).is_true()
	assert_array(jumps).is_empty()
	await _real_seconds(0.5)
	assert_array(jumps).is_empty()
	assert_float((_node("Fade") as CanvasItem).modulate.a).is_between(0.2, 0.8)
	await _real_seconds(0.7)
	assert_array(jumps).is_equal([P.FIRST_NIGHT])
	assert_int(resumed).is_equal(0)

func test_input_during_the_fade_does_nothing() -> void:
	await _open_story()
	await _tap(KEY_ENTER)
	await _tap(KEY_ESCAPE)
	await _pad(JOY_BUTTON_START)
	await _tap(KEY_ENTER)
	assert_bool((_node("Board") as CanvasItem).visible).is_false()
	assert_bool(panel.visible).is_false()
	assert_bool(pause.rules.is_open).is_false()
	assert_bool(get_tree().paused).is_true()
	await _real_seconds(1.2)
	assert_int(jumps.size()).is_equal(1)

func test_current_point_still_jumps() -> void:
	_set_clock(960.0)
	await _open_story()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _real_seconds(1.2)
	assert_array(jumps).is_equal([P.FIRST_DAY])

func test_pad_a_jumps() -> void:
	await _open_story()
	await _pad(JOY_BUTTON_A)
	await _real_seconds(1.2)
	assert_array(jumps).is_equal([P.SHIPWRECK])

func test_enter_story_default_is_the_real_jump() -> void:
	var game := auto_free(load("res://src/waking/waking.tscn").instantiate()) as Waking
	assert_bool(game.enter_story == Callable(game, "_enter_story")).is_true()
