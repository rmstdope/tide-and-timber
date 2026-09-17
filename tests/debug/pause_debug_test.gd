extends GdUnitTestSuite
## The Debug plank, the DEV tag and the Debug panel on the beach's pause board, in a debug build.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var panel: DebugPanel
var resumed := 0

func before_test() -> void:
	Pause.debug_tools = true
	InputDevice.reset()
	resumed = 0
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
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

func _press(at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	panel.gui_input.emit(click)

# gdUnit4's await_millis stops with the paused tree; this timer runs through a pause.
func _real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _highlighted(unique: String) -> void:
	assert_bool(is_same((_node(unique) as Control).get_theme_stylebox("panel"), Pause.PLANK_HIGHLIGHT_STYLE)) \
		.override_failure_message(unique + " is not highlighted").is_true()

func _open_panel() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)

func test_debug_plank_sits_above_quit_to_title() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	var planks: Array = ["Resume", "Settings", "Debug", "QuitToTitle"].map(func(n: String) -> Control: return _node(n))
	for i in planks.size() - 1:
		assert_float(planks[i].position.y).is_less(planks[i + 1].position.y)
	assert_str((_node("Debug").get_node("Label") as Label).text).is_equal("Debug")
	var board := _node("Panel") as Control
	assert_float(board.size.y).is_equal(Pause.BOARD_H_THREE + Pause.PLANK_STEP)
	assert_float(board.position.y + board.size.y).is_less_equal(180.0)
	var quit := _node("QuitToTitle") as Control
	assert_float(quit.position.y + quit.size.y).is_less_equal(board.size.y)

func test_dev_tag_shows_on_the_board() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	var tag := _node("DevTag") as Control
	assert_bool(tag.is_visible_in_tree()).is_true()
	assert_str(DevTag.WORD).is_equal("DEV")
	assert_bool((_node("Panel") as Control).get_global_rect().encloses(tag.get_global_rect())).is_true()

func test_enter_on_debug_opens_the_panel_on_time() -> void:
	await _open_panel()
	assert_bool(panel.visible).is_true()
	assert_bool((_node("Board") as Control).visible).is_false()
	assert_bool(get_tree().paused).is_true()
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.TIME)
	assert_int(panel.rules.highlighted).is_equal(0)

func test_q_and_e_flip_pages() -> void:
	await _open_panel()
	await _tap(KEY_E)
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.ITEMS)
	await _tap(KEY_Q)
	await _tap(KEY_Q)
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.SHOW)

func test_pad_shoulders_flip_pages_and_b_goes_back() -> void:
	await _open_panel()
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.ITEMS)
	await _pad(JOY_BUTTON_B)
	assert_bool(panel.visible).is_false()
	assert_bool((_node("Board") as Control).visible).is_true()
	_highlighted("Debug")

func test_esc_goes_one_step_back_then_resumes() -> void:
	await _open_panel()
	await _tap(KEY_ESCAPE)
	assert_bool(panel.visible).is_false()
	assert_bool((_node("Board") as Control).visible).is_true()
	_highlighted("Debug")
	assert_bool(get_tree().paused).is_true()
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()

func test_start_resumes_at_once() -> void:
	await _open_panel()
	await _pad(JOY_BUTTON_START)
	assert_bool(get_tree().paused).is_false()
	assert_bool(panel.visible).is_false()
	assert_bool((_node("Board") as Control).visible).is_false()
	assert_int(resumed).is_equal(1)

func test_each_opening_starts_on_time() -> void:
	await _open_panel()
	await _tap(KEY_E)
	await _tap(KEY_E)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ENTER)
	assert_bool(panel.visible).is_true()
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.TIME)

func test_rows_added_through_the_seam_draw_and_act() -> void:
	var got: Array[int] = []
	pause.debug_menu().add_row(DebugMenu.Page.ITEMS,
			DebugRow.new("Test", func() -> String: return "1", func(d: int) -> void: got.append(d)))
	await _open_panel()
	await _tap(KEY_E)   # Items: the Time page has its own rows
	await _tap(KEY_RIGHT)
	assert_array(got).is_equal([1])
	await _tap(KEY_DOWN)
	assert_int(panel.rules.highlighted).is_equal(0)
	assert_bool(panel.visible).is_true()

func test_list_scrolls() -> void:
	for i in 12:
		pause.debug_menu().add_row(DebugMenu.Page.TIME, DebugRow.new("Row"))
	await _open_panel()
	for i in 9:
		await _tap(KEY_DOWN)
	assert_int(panel.rules.scroll).is_equal(1)

func test_refused_row_shakes() -> void:
	pause.debug_menu().add_row(DebugMenu.Page.ITEMS,
			DebugRow.new("No", Callable(), Callable(), func() -> DebugRow.Result: return DebugRow.Result.REFUSED))
	await _open_panel()
	await _tap(KEY_E)   # Items: the Time page has its own rows
	await _tap(KEY_ENTER)
	assert_int(panel.shaking_row).is_equal(0)
	await _real_seconds(0.4)
	assert_int(panel.shaking_row).is_equal(-1)
	assert_float(panel.shake_x).is_equal(0.0)

func test_resume_row_closes_panel_and_pause() -> void:
	pause.debug_menu().add_row(DebugMenu.Page.ITEMS,
			DebugRow.new("Go", Callable(), Callable(), func() -> DebugRow.Result: return DebugRow.Result.RESUME))
	await _open_panel()
	await _tap(KEY_E)   # Items: the Time page has its own rows
	await _tap(KEY_ENTER)
	assert_bool(get_tree().paused).is_false()
	assert_bool(panel.visible).is_false()
	await _tap(KEY_ESCAPE)
	assert_bool((_node("Board") as Control).visible).is_true()
	_highlighted("Resume")

func test_hint_strip_reads_page_change_back() -> void:
	await _open_panel()
	assert_str(panel.strip.text()).is_equal("[Q][E] Page   [←][→] Change   [Esc] Back")

func test_mouse_clicks_a_tab_and_a_row() -> void:
	var picked: Array[String] = []
	pause.debug_menu().add_row(DebugMenu.Page.STORY,
			DebugRow.new("Pick", Callable(), Callable(), func() -> DebugRow.Result: picked.append("x"); return DebugRow.Result.DONE))
	await _open_panel()
	_press(DebugPanel.tab_rect(3).get_center())
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.STORY)
	_press(DebugPanel.row_rect(0).get_center())
	assert_array(picked).is_equal(["x"])

func test_a_second_refusal_restarts_the_shake() -> void:
	pause.debug_menu().add_row(DebugMenu.Page.ITEMS,
			DebugRow.new("No", Callable(), Callable(), func() -> DebugRow.Result: return DebugRow.Result.REFUSED))
	await _open_panel()
	await _tap(KEY_E)   # Items: the Time page has its own rows
	await _tap(KEY_ENTER)
	await _real_seconds(0.15)
	await _tap(KEY_ENTER)
	await _real_seconds(0.15)
	assert_int(panel.shaking_row).is_equal(0)
	await _real_seconds(0.3)
	assert_int(panel.shaking_row).is_equal(-1)
