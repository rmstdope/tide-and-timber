extends GdUnitTestSuite
## Pausing on the beach: Esc, Start, a lost window or pad opens the board; Settings and Quit to title.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var builder: Builder
var calls: Array[String] = []

func before_test() -> void:
	Pause.debug_tools = false   # the release board; tests/debug covers the debug one
	InputDevice.reset()
	calls = []
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	builder = waking.get_node("%Beach").get_node("%Builder")
	var recorded := calls
	pause.quit_to_title = func() -> void: recorded.append("title")
	pause.open_settings = func() -> void: recorded.append("settings")
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
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

func _click(control: Control) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	control.gui_input.emit(click)

# gdUnit4's await_millis stops with the paused tree; this timer runs through a pause.
func _real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _highlighted(unique: String) -> void:
	assert_bool(is_same((_node(unique) as Control).get_theme_stylebox("panel"), Pause.PLANK_HIGHLIGHT_STYLE)) \
		.override_failure_message(unique + " is not highlighted").is_true()

func _plank_text(unique: String) -> String:
	return (_node(unique).get_node("Label/Words") as Label).text

# The quit box's button words sit in a GrownWords holder.
func _button_text(unique: String) -> String:
	return (_node(unique).get_node("Label") as GrownWords).text

func _open_box() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)

func test_esc_pauses_on_resume_with_the_agreed_words() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_true()
	assert_bool(_node("Board").visible).is_true()
	assert_bool(_node("QuitBox").visible).is_false()
	assert_str((_node("Heading") as Label).text).is_equal("Paused")
	assert_str(_plank_text("Resume")).is_equal("Resume")
	assert_str(_plank_text("Settings")).is_equal("Settings")
	assert_str(_plank_text("QuitToTitle")).is_equal("Quit to title")
	assert_bool(_node("SkipStory").visible).is_false()
	_highlighted("Resume")

func test_the_clock_stands_still_while_paused() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	var clock: GameClock = waking.get_node("%DayNight").clock
	var minutes := clock.total_minutes
	await _real_seconds(0.3)
	assert_float(clock.total_minutes).is_equal(minutes)

func test_board_is_centred_and_fits() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	var panel := _node("Panel") as Control
	assert_that(panel.get_rect()).is_equal(Rect2(((Screen.SIZE - Vector2(144, 96)) / 2.0).floor(), Vector2(144, 96)))
	for unique: String in ["Resume", "Settings", "QuitToTitle"]:
		var plank := _node(unique) as Control
		var needs := plank.get_combined_minimum_size()
		assert_bool(needs.x <= Pause.PLANK_SIZE.x and needs.y <= Pause.PLANK_SIZE.y) \
			.override_failure_message(unique + " needs " + str(needs)).is_true()
		assert_bool(panel.get_global_rect().encloses(plank.get_global_rect())).is_true()

func _assert_closed() -> void:
	assert_bool(get_tree().paused).is_false()
	assert_bool(_node("Board").visible).is_false()

func test_esc_start_b_and_resume_each_resume() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ESCAPE)
	_assert_closed()
	await _pad(JOY_BUTTON_START)
	assert_bool(get_tree().paused).is_true()
	await _pad(JOY_BUTTON_START)
	_assert_closed()
	await _tap(KEY_ESCAPE)
	await _pad(JOY_BUTTON_B)
	_assert_closed()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ENTER)
	_assert_closed()

func test_up_down_wrap() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	_highlighted("Settings")
	await _tap(KEY_DOWN)
	_highlighted("QuitToTitle")
	await _tap(KEY_DOWN)
	_highlighted("Resume")
	await _tap(KEY_UP)
	_highlighted("QuitToTitle")

func test_reopens_on_resume() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ESCAPE)
	_highlighted("Resume")

func test_no_pause_before_he_has_control() -> void:
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()
	assert_bool(pause.try_open()).is_false()

func test_esc_with_the_build_list_open_closes_the_list_only() -> void:
	_control()
	builder.open_list()
	await _tap(KEY_ESCAPE)
	assert_int(builder.mode).is_equal(Builder.Mode.CLOSED)
	assert_bool(get_tree().paused).is_false()

func test_start_with_the_build_list_open_does_nothing() -> void:
	_control()
	builder.open_list()
	await _pad(JOY_BUTTON_START)
	assert_int(builder.mode).is_equal(Builder.Mode.LIST)
	assert_bool(get_tree().paused).is_false()

func test_no_pause_while_placing_building_or_collapsing() -> void:
	_control()
	for mode: Builder.Mode in [Builder.Mode.PLACING, Builder.Mode.BUILDING]:
		builder.mode = mode
		assert_bool(pause.try_open()).is_false()
		builder.mode = Builder.Mode.CLOSED
	var night := waking.get_node("%Night") as Night
	night.collapse = Collapse.new()
	assert_bool(pause.try_open()).is_false()
	night.collapse = null

func test_no_pause_while_the_tree_is_already_paused() -> void:
	_control()
	get_tree().paused = true
	assert_bool(pause.try_open()).is_false()
	assert_bool(_node("Board").visible).is_false()

func test_losing_focus_pauses_and_coming_back_keeps_the_board() -> void:
	_control()
	pause.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_bool(get_tree().paused).is_true()
	assert_bool(_node("Board").visible).is_true()
	_highlighted("Resume")
	pause.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_bool(get_tree().paused).is_true()
	assert_bool(_node("Board").visible).is_true()

func test_window_focus_out_also_pauses() -> void:
	_control()
	pause.notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert_bool(get_tree().paused).is_true()
	assert_bool(_node("Board").visible).is_true()

func test_losing_focus_while_paused_changes_nothing() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	pause.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_highlighted("Settings")

func test_losing_focus_with_the_list_open_changes_nothing() -> void:
	_control()
	builder.open_list()
	pause.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_bool(get_tree().paused).is_false()
	assert_int(builder.mode).is_equal(Builder.Mode.LIST)

func test_pad_lost_pauses_and_pad_found_does_not() -> void:
	_control()
	Input.joy_connection_changed.emit(1, true)
	assert_bool(get_tree().paused).is_false()
	Input.joy_connection_changed.emit(0, false)
	assert_bool(get_tree().paused).is_true()
	assert_bool(_node("Board").visible).is_true()

func test_settings_asks_for_the_settings_screen_and_stays_paused() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	assert_array(calls).is_equal(["settings"])
	assert_bool(get_tree().paused).is_true()
	assert_bool(_node("Board").visible).is_false()
	assert_bool(pause.rules.settings_open).is_true()

func test_quit_to_title_asks_on_stay_before_any_save() -> void:
	await _open_box()
	assert_bool(_node("QuitBox").visible).is_true()
	assert_str((_node("FirstLine") as Label).text).is_equal("Quit to title?")
	assert_str((_node("SecondLine") as Label).text).is_equal("Nothing has been saved yet.")
	assert_str(_button_text("Stay")).is_equal("Stay")
	assert_str(_button_text("Quit")).is_equal("Quit")
	_highlighted("Stay")
	assert_array(calls).is_empty()

func test_quit_box_after_a_dawn_warns_about_this_morning() -> void:
	_control()
	var clock: GameClock = waking.get_node("%DayNight").clock
	clock.total_minutes = GameClock.MINUTES_PER_DAY + GameClock.DAY_START_MINUTE
	await _tap(KEY_ESCAPE)
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)
	assert_str((_node("SecondLine") as Label).text).is_equal("Anything since this morning will be lost.")

func test_quit_box_fits() -> void:
	_control()
	var clock: GameClock = waking.get_node("%DayNight").clock
	clock.total_minutes = GameClock.MINUTES_PER_DAY + GameClock.DAY_START_MINUTE
	await _tap(KEY_ESCAPE)
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)
	var line := _node("SecondLine") as Label
	assert_int(line.get_line_count()).is_less_equal(2)
	var box_panel := line.get_parent() as Control
	assert_bool(box_panel.get_global_rect().encloses(line.get_global_rect())).is_true()

func test_left_right_select_and_stop_at_the_ends() -> void:
	await _open_box()
	await _tap(KEY_RIGHT)
	await _tap(KEY_RIGHT)
	_highlighted("Quit")
	await _tap(KEY_LEFT)
	await _tap(KEY_LEFT)
	_highlighted("Stay")

func _assert_back_on_the_board() -> void:
	assert_bool(_node("QuitBox").visible).is_false()
	assert_bool(_node("Board").visible).is_true()
	assert_bool(get_tree().paused).is_true()
	_highlighted("QuitToTitle")

func test_stay_esc_and_b_go_back_to_quit_to_title() -> void:
	await _open_box()
	await _tap(KEY_ENTER)
	_assert_back_on_the_board()
	await _tap(KEY_ENTER)
	await _tap(KEY_ESCAPE)
	_assert_back_on_the_board()
	await _tap(KEY_ENTER)
	await _pad(JOY_BUTTON_B)
	_assert_back_on_the_board()

func test_start_does_nothing_in_the_box() -> void:
	await _open_box()
	await _pad(JOY_BUTTON_START)
	assert_bool(_node("QuitBox").visible).is_true()
	_highlighted("Stay")

func test_quit_fades_then_opens_the_title() -> void:
	await _open_box()
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_bool(_node("Fade").visible).is_true()
	assert_array(calls).is_empty()
	await _tap(KEY_ESCAPE)
	assert_bool(_node("QuitBox").visible).is_true()
	await _real_seconds(1.2)
	assert_array(calls).is_equal(["title"])
	assert_float(_node("Fade").modulate.a).is_equal_approx(1.0, 0.01)

func test_mouse_hovers_and_clicks() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	_move_over(_node("Settings"))
	_highlighted("Settings")
	_click(_node("QuitToTitle"))
	assert_bool(_node("QuitBox").visible).is_true()
	_move_over(_node("Quit"))
	_highlighted("Quit")
	_click(_node("Stay"))
	assert_bool(_node("QuitBox").visible).is_false()
	_highlighted("QuitToTitle")
	_click(_node("Resume"))
	assert_bool(get_tree().paused).is_false()

# A mouse movement straight to a control, as Godot delivers one over it.
func _move_over(control: Control, relative := Vector2(1, 0)) -> void:
	var move := InputEventMouseMotion.new()
	move.relative = relative
	control.gui_input.emit(move)

# A mouse movement through the window, so InputDevice sees it.
func _mouse_moved() -> void:
	var move := InputEventMouseMotion.new()
	move.position = Vector2(4, 4)
	move.relative = Vector2(2, 0)
	Input.parse_input_event(move)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func test_esc_hides_the_pointer_and_resuming_shows_it() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	assert_bool(InputDevice.pointer.hidden).is_true()
	await _tap(KEY_ESCAPE)
	assert_bool(InputDevice.pointer.hidden).is_false()

func test_pause_after_a_mouse_move_shows_the_pointer() -> void:
	_control()
	await _mouse_moved()
	pause.try_open()
	assert_bool(InputDevice.pointer.hidden).is_false()
	await _tap(KEY_DOWN)
	assert_bool(InputDevice.pointer.hidden).is_true()
	await _mouse_moved()
	assert_bool(InputDevice.pointer.hidden).is_false()

func test_resting_pointer_does_not_pull_the_highlight() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	(_node("Settings") as Control).mouse_entered.emit()
	_highlighted("Resume")
	_move_over(_node("Settings"), Vector2.ZERO)
	_highlighted("Resume")

func test_quit_box_hover_needs_motion() -> void:
	await _open_box()
	(_node("Quit") as Control).mouse_entered.emit()
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.STAY)
	_move_over(_node("Quit"))
	assert_int(pause.rules.box_selected).is_equal(PauseMenu.Choice.QUIT)

func test_the_players_pause_key_pauses() -> void:
	var p := InputEventKey.new()
	p.physical_keycode = KEY_P
	InputDevice.controls.set_slot(Controls.Action.PAUSE, Controls.Device.KEYBOARD, 0, p)
	_control()
	await _tap(KEY_ESCAPE)
	assert_bool(_node("Board").visible).is_false()
	await _tap(KEY_P)
	assert_bool(_node("Board").visible).is_true()

func test_no_strip_in_play() -> void:
	_control()
	assert_bool(pause.strip.is_visible_in_tree()).is_false()

func test_board_shows_select_and_back() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	assert_bool(pause.strip.is_visible_in_tree()).is_true()
	assert_str(pause.strip.text()).is_equal("[Enter] Select   [Esc] Back")

func test_start_shows_the_pads_buttons() -> void:
	_control()
	await _pad(JOY_BUTTON_START)
	assert_bool(pause.strip.is_visible_in_tree()).is_true()
	assert_str(pause.strip.text()).is_equal("(A) Select   (B) Back")

func test_quit_box_keeps_the_strip_on_top() -> void:
	await _open_box()
	assert_bool(pause.strip.is_visible_in_tree()).is_true()
	assert_int(pause.strip.get_index()).is_greater(_node("QuitBox").get_index())
	assert_str(pause.strip.text()).is_equal("[Enter] Select   [Esc] Back")
