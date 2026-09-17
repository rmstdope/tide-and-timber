extends "res://tests/night/night_scene_base.gd"
## The Debug panel's Survival page on the beach: placing, removing builds, and collapsing now.

const T := BuildMenu.Thing
const F := Walk.Facing

var pause: Pause
var panel: DebugPanel

func before_test() -> void:
	Pause.debug_tools = true
	InputDevice.reset()
	super.before_test()
	pause = waking.get_node("%Pause") as Pause
	panel = pause.get_node("%DebugPanel") as DebugPanel

func after_test() -> void:
	super.after_test()
	Pause.debug_tools = OS.is_debug_build()
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

func _real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _stand(cell: Vector2i, facing: F) -> void:
	player.global_position = BeachLayout.cell_centre(cell)
	player.facing = facing

func _open_survival() -> void:
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_Q)
	await _tap(KEY_Q)
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.SURVIVAL)

func _row(i: int) -> void:
	for n in i:
		await _tap(KEY_DOWN)

func _lean_to_by_hand() -> void:
	_stand(Vector2i(92, 11), F.DOWN)
	assert_bool(builder.place_now(T.LEAN_TO)).is_true()

func test_survival_page_lists_its_four_rows() -> void:
	await _open_survival()
	assert_array(panel.rules.rows_of(DebugMenu.Page.SURVIVAL).map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Place lean-to", "Place fire", "Remove builds", "Collapse now"])
	assert_int(panel.rules.highlighted).is_equal(0)

func test_place_lean_to_from_the_panel_stands_while_paused() -> void:
	_stand(Vector2i(92, 11), F.DOWN)
	await _open_survival()
	await _tap(KEY_ENTER)
	assert_object(builder.lean_to).is_not_null()
	assert_array(builder.lean_to.cells).is_equal(BuildSite.cells_for(T.LEAN_TO, Vector2i(92, 11), F.DOWN))
	assert_bool(get_tree().paused).is_true()
	assert_bool(panel.visible).is_true()
	assert_int(panel.shaking_row).is_equal(-1)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(0)

func test_place_fire_from_the_panel_lights_on_the_fire_spot() -> void:
	_lean_to_by_hand()
	_stand(Vector2i(91, 14), F.RIGHT)
	_at(600.0)
	await _open_survival()
	await _row(1)
	await _tap(KEY_ENTER)
	assert_object(builder.fire).is_not_null()
	assert_bool(builder.fire.lit).is_true()
	assert_that(builder.fire.cell).is_equal(Vector2i(92, 14))
	assert_bool(get_tree().paused).is_true()
	assert_bool(builder.in_firelight(player.global_position)).is_true()

func test_cannot_place_here_shakes_and_places_nothing() -> void:
	_stand(Waking.WAKE_CELL, F.DOWN)
	await _open_survival()
	await _tap(KEY_ENTER)
	assert_int(panel.shaking_row).is_equal(0)
	assert_object(builder.lean_to).is_null()
	await _real_seconds(0.4)
	assert_int(panel.shaking_row).is_equal(-1)
	await _row(1)
	await _tap(KEY_ENTER)
	assert_int(panel.shaking_row).is_equal(1)
	assert_object(builder.fire).is_null()

func test_remove_builds_from_the_panel() -> void:
	_lean_to_by_hand()
	_stand(Vector2i(91, 14), F.RIGHT)
	assert_bool(builder.place_now(T.FIRE)).is_true()
	await _open_survival()
	await _row(2)
	await _tap(KEY_ENTER)
	assert_object(builder.lean_to).is_null()
	assert_object(builder.fire).is_null()
	assert_bool(get_tree().paused).is_true()
	assert_bool(panel.visible).is_true()
	assert_int(panel.shaking_row).is_equal(-1)

func test_collapse_now_closes_panel_and_pause_and_he_collapses() -> void:
	_at(600.0)
	await _open_survival()
	await _row(3)
	await _tap(KEY_ENTER)
	assert_bool(get_tree().paused).is_false()
	assert_bool(panel.visible).is_false()
	assert_bool((pause.get_node("%Board") as CanvasItem).visible).is_false()
	assert_object(night.collapse).is_not_null()
	assert_bool(player.control_enabled).is_false()
	for s: float in [4.5, 0.5, 2.0, 0.5, 1.5, 1.5, 2.2]:
		night.tick(s)
	assert_object(night.collapse).is_null()
	assert_float(dn.clock.total_minutes).is_equal(1800.0)
	await _tap(KEY_ESCAPE)
	assert_bool((pause.get_node("%Board") as CanvasItem).visible).is_true()
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.RESUME)

func test_pad_a_on_place_lean_to() -> void:
	_stand(Vector2i(92, 11), F.DOWN)
	await _open_survival()
	await _pad(JOY_BUTTON_A)
	assert_object(builder.lean_to).is_not_null()

func test_debug_builds_are_what_the_dawn_save_writes() -> void:
	_stand(Vector2i(92, 11), F.DOWN)
	await _open_survival()
	await _tap(KEY_ENTER)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ESCAPE)
	_stand(Vector2i(91, 14), F.RIGHT)
	await _open_survival()
	await _row(1)
	await _tap(KEY_ENTER)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()
	var data := beach.capture()
	assert_bool(Builder.camp_fits(data)).is_true()
	assert_bool(data.has_fire).is_true()
