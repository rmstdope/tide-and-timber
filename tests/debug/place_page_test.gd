extends GdUnitTestSuite
## The Debug panel's Place page on the beach: Walk through things, and putting him on a named place.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var panel: DebugPanel
var player: Player
var beach: Beach

func before_test() -> void:
	Pause.debug_tools = true
	InputDevice.reset()
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	panel = pause.get_node("%DebugPanel") as DebugPanel
	player = waking.player
	beach = waking.get_node("%Beach") as Beach
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	get_tree().paused = false
	Pause.debug_tools = OS.is_debug_build()
	DebugSwitches.walk_through = false
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _taps(key: Key, times: int) -> void:
	for i in times:
		await _tap(key)

func _pad(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = button
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func _open_place() -> void:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _taps(KEY_DOWN, 2)
	await _tap(KEY_ENTER)
	await _taps(KEY_E, 2)

func _rows() -> Array[DebugRow]:
	return panel.rules.rows_of(DebugMenu.Page.PLACE)

func test_place_page_lists_walk_through_then_places() -> void:
	await _open_place()
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.PLACE)
	assert_array(_rows().map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Walk through things", "Where he woke", "Wreck", "Beach", "Spring", "Camp"])
	assert_str(_rows()[0].value_text()).is_equal("Off")
	assert_int(panel.rules.highlighted).is_equal(0)

func test_right_turns_walk_through_on_and_left_off() -> void:
	await _open_place()
	await _tap(KEY_RIGHT)
	assert_bool(DebugSwitches.walk_through).is_true()
	assert_str(_rows()[0].value_text()).is_equal("On")
	await _tap(KEY_LEFT)
	assert_bool(DebugSwitches.walk_through).is_false()

func test_enter_on_walk_through_flips_it() -> void:
	await _open_place()
	await _tap(KEY_ENTER)
	assert_bool(DebugSwitches.walk_through).is_true()
	assert_bool(panel.visible).is_true()
	assert_bool(get_tree().paused).is_true()

func test_select_a_place_moves_him_and_the_view_while_paused() -> void:
	await _open_place()
	await _taps(KEY_DOWN, 4)
	await _tap(KEY_ENTER)
	assert_vector(player.global_position).is_equal(BeachLayout.cell_centre(DebugPlaces.SPRING_CELL))
	assert_int(player.facing).is_equal(Walk.Facing.UP)
	var camera := beach.get_node("%Camera") as LooseCamera
	# the spring sits near the treeline, so the view snaps to him but stops at the island's top edge
	assert_vector(camera.centre).is_equal(LooseFollow.clamp_centre(player.global_position, camera.bounds))
	assert_float(camera.centre.y).is_equal(Screen.CENTRE.y)
	assert_bool(get_tree().paused).is_true()
	assert_bool(panel.visible).is_true()
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.PLACE)
	assert_int(panel.shaking_row).is_equal(-1)

func test_wreck_puts_him_in_the_shallows() -> void:
	await _open_place()
	await _taps(KEY_DOWN, 2)
	await _tap(KEY_ENTER)
	assert_vector(player.global_position).is_equal(BeachLayout.cell_centre(DebugPlaces.WRECK_CELL))

func test_camp_without_a_camp_goes_to_the_camp_spot() -> void:
	await _open_place()
	await _taps(KEY_DOWN, 5)
	await _tap(KEY_ENTER)
	assert_vector(player.global_position).is_equal(BeachLayout.cell_centre(DebugPlaces.CAMP_CELL))
	assert_int(player.facing).is_equal(Walk.Facing.DOWN)

func test_camp_with_a_lean_to_goes_beside_it() -> void:
	var data := SaveData.new()
	data.lean_to_cells = [Vector2i(39, 11), Vector2i(40, 11), Vector2i(41, 11),
			Vector2i(39, 12), Vector2i(40, 12), Vector2i(41, 12)] as Array[Vector2i]
	(beach.get_node("%Builder") as Builder).restore_camp(data)
	await _open_place()
	await _taps(KEY_DOWN, 5)
	await _tap(KEY_ENTER)
	assert_vector(player.global_position) \
		.is_equal(BeachLayout.cell_centre(WakeSpot.beside_lean_to(Vector2i(40, 12), Waking.WAKE_CELL)))

func test_same_place_twice_still_moves_him() -> void:
	await _open_place()
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	player.global_position += Vector2(3, 0)
	await _tap(KEY_ENTER)
	assert_vector(player.global_position).is_equal(BeachLayout.cell_centre(Waking.WAKE_CELL))

func test_pad_a_on_beach_moves_him() -> void:
	await _open_place()
	for i in 3:
		await _pad(JOY_BUTTON_DPAD_DOWN)
	await _pad(JOY_BUTTON_A)
	assert_vector(player.global_position).is_equal(BeachLayout.cell_centre(BeachLayout.SPAWN_CELL))

func test_after_resume_he_walks_from_the_new_place() -> void:
	await _open_place()
	await _taps(KEY_DOWN, 3)
	await _tap(KEY_ENTER)
	await _taps(KEY_ESCAPE, 2)
	assert_bool(get_tree().paused).is_false()
	assert_vector(beach.capture().player_position).is_equal(BeachLayout.cell_centre(BeachLayout.SPAWN_CELL))

func test_walk_through_stays_on_after_resume() -> void:
	await _open_place()
	await _tap(KEY_RIGHT)
	await _taps(KEY_ESCAPE, 2)
	assert_bool(get_tree().paused).is_false()
	await await_millis(50)
	assert_int(player.collision_mask).is_equal(Player.WALK_THROUGH_MASK)
