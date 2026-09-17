extends GdUnitTestSuite
## The Debug panel's Show page on the beach: the readout and the red and blue outlines.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var panel: DebugPanel
var readout: DebugReadout
var outlines: DebugOutlines

func before_test() -> void:
	Pause.debug_tools = true
	InputDevice.reset()
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	panel = pause.get_node("%DebugPanel") as DebugPanel
	readout = waking.get_node("DebugReadoutLayer/Readout") as DebugReadout
	outlines = waking.get_node("DebugOutlineLayer/Outlines") as DebugOutlines
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	get_tree().paused = false
	Pause.debug_tools = OS.is_debug_build()
	DebugSwitches.readout = false
	DebugSwitches.collision_areas = false
	DebugSwitches.use_areas = false
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

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

func _open_show() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_Q)

func _rows() -> Array[DebugRow]:
	return panel.rules.rows_of(DebugMenu.Page.SHOW)

func test_show_page_lists_three_switches_off() -> void:
	await _open_show()
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.SHOW)
	assert_array(_rows().map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Readout", "Collision areas", "Use areas"])
	assert_array(_rows().map(func(r: DebugRow) -> String: return r.value_text())) \
		.is_equal(["Off", "Off", "Off"])
	await runner.simulate_frames(2)
	assert_bool(readout.visible).is_false()
	assert_bool(outlines.visible).is_false()

func test_readout_on_shows_at_once_while_paused() -> void:
	await _open_show()
	await _tap(KEY_RIGHT)
	assert_bool(DebugSwitches.readout).is_true()
	await runner.simulate_frames(2)
	assert_bool(readout.visible).is_true()
	assert_bool(get_tree().paused).is_true()
	var clock := (waking.get_node("%DayNight") as DayNight).clock
	var ls := readout.lines()
	assert_int(ls.size()).is_equal(4)
	assert_str(ls[0]).is_equal(clock.day_text() + " " + clock.time_text())
	assert_str(ls[1]).is_equal("SPEED x1")
	assert_str(ls[2]).starts_with("FPS ")
	assert_str(ls[3]).is_equal("X %d Y %d" % [roundi(waking.player.global_position.x), roundi(waking.player.global_position.y)])

func test_readout_box_is_top_right_and_fits() -> void:
	assert_object(DebugReadout.box_rect(4)).is_equal(Rect2(236, 4, 80, 34))
	assert_int(Glyphs.width("X 9999 Y 999")).is_less_equal(80 - 8)

func test_collision_areas_outline_his_feet_and_the_shapes() -> void:
	await _open_show()
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	assert_bool(DebugSwitches.collision_areas).is_true()
	await runner.simulate_frames(2)
	assert_bool(outlines.visible).is_true()
	var rects := DebugShow.solid_rects(waking.get_node("%Beach").get_node("%World"))
	assert_array(rects).contains([Rect2(waking.player.global_position + Vector2(-5, -6), Vector2(10, 6))])

func test_use_areas_circle_every_usable() -> void:
	await _open_show()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	assert_bool(DebugSwitches.use_areas).is_true()
	await runner.simulate_frames(2)
	assert_bool(outlines.visible).is_true()
	var n := DebugShow.use_spots(get_tree()).size()
	assert_int(n).is_equal(get_tree().get_nodes_in_group(Usable.GROUP).size())
	assert_int(n).is_greater(0)

func test_switches_stay_on_after_resume() -> void:
	await _open_show()
	await _tap(KEY_RIGHT)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()
	await runner.simulate_frames(2)
	assert_bool(readout.visible).is_true()

func test_pad_turns_use_areas_on() -> void:
	await _open_show()
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _pad(JOY_BUTTON_A)
	assert_bool(DebugSwitches.use_areas).is_true()

func test_readout_sits_under_the_pause_layer() -> void:
	assert_int((waking.get_node("DebugReadoutLayer") as CanvasLayer).layer).is_less((pause as CanvasLayer).layer)
	var outline_layer := waking.get_node("DebugOutlineLayer") as CanvasLayer
	assert_int(outline_layer.layer).is_less(10)
	assert_bool(outline_layer.follow_viewport_enabled).is_true()
