extends GdUnitTestSuite

const SCENE := "res://src/beach/beach.tscn"
const T := BuildMenu.Thing
const F := Walk.Facing
const M := Builder.Mode

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var builder: Builder
var inventory: Inventory

func before_test() -> void:
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset()
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	builder = beach.get_node("%Builder") as Builder
	inventory = beach.inventory

func _n(unique: String) -> Node:
	return beach.get_node("%" + unique)

func _list() -> BuildList:
	return _n("BuildList") as BuildList

func _stand(cell: Vector2i, facing: F) -> void:
	player.global_position = BeachLayout.cell_centre(cell)
	player.facing = facing
	(beach.get_node("%Camera") as LooseCamera).snap_to_target()
	await await_millis(50)

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()
	await await_millis(50)

func _clock() -> DayNight:
	var dn := load("res://src/day_night/day_night.tscn").instantiate() as DayNight
	beach.add_child(dn)
	beach.set_day_night(dn)
	dn.start()
	return dn

func _driftwood(n: int) -> void:
	inventory.add(Item.Kind.DRIFTWOOD, n)

func _left_press() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event

## Placing: the see-through outline in front of him, red where it cannot go.

func _choose_lean_to_at(cell: Vector2i, facing: F) -> void:
	_driftwood(9)
	await _stand(cell, facing)
	await _press(KEY_B)
	await _press(KEY_E)
	await await_millis(50)

func test_e_chooses_and_places_outline_in_front() -> void:
	_driftwood(9)
	await _stand(Vector2i(92, 11), F.DOWN)
	await _press(KEY_B)
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.PLACING)
	assert_bool(_list().visible).is_false()
	assert_bool(_n("BuildBlocker").visible).is_false()
	assert_str((_n("KeyHint") as KeyHint).text()).is_equal("[E] Place   [Esc] Back")
	await await_millis(50)
	var ghost := _n("Ghost") as BuildGhost
	assert_bool(ghost.visible).is_true()
	assert_bool(ghost.ok).is_true()
	assert_int(ghost.thing).is_equal(T.LEAN_TO)
	assert_vector(ghost.position).is_equal(Vector2(1480, 224))

func test_click_on_row_chooses() -> void:
	_driftwood(9)
	await _press(KEY_B)
	_list().rows[0].gui_input.emit(_left_press())
	assert_int(builder.mode).is_equal(M.PLACING)

func test_outline_follows_his_facing() -> void:
	await _choose_lean_to_at(Vector2i(92, 11), F.DOWN)
	player.facing = F.UP
	await await_millis(50)
	assert_vector(_n("Ghost").position).is_equal(BeachLayout.cell_base(Vector2i(92, 10)))

func test_world_and_clock_run_while_placing() -> void:
	var dn := _clock()
	_driftwood(9)
	await _press(KEY_B)
	await _press(KEY_E)
	assert_int(_n("World").process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_int(_n("Interactor").process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	var m := dn.clock.total_minutes
	await await_millis(300)
	assert_bool(dn.clock.total_minutes > m).is_true()

func test_red_on_rock_and_press_ignored() -> void:
	await _choose_lean_to_at(Vector2i(99, 11), F.DOWN)
	assert_bool(_n("Ghost").ok).is_false()
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.PLACING)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(9)
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()
	assert_int(builder.mode).is_equal(M.PLACING)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(9)

func test_shapes_cross_on_rock() -> void:
	Display.prefs.step(DisplayPrefs.Setting.CUES, 1)
	await _choose_lean_to_at(Vector2i(99, 11), F.DOWN)
	assert_bool((_n("Ghost") as BuildGhost).ok).is_false()
	assert_bool((_n("Ghost") as BuildGhost).shows_cross()).is_true()
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.PLACING)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(9)

func test_shapes_leaves_a_good_spot_plain() -> void:
	Display.prefs.step(DisplayPrefs.Setting.CUES, 1)
	await _choose_lean_to_at(Vector2i(92, 11), F.DOWN)
	assert_bool((_n("Ghost") as BuildGhost).ok).is_true()
	assert_bool((_n("Ghost") as BuildGhost).shows_cross()).is_false()

func test_standard_cross_on_rock() -> void:
	await _choose_lean_to_at(Vector2i(99, 11), F.DOWN)
	assert_bool((_n("Ghost") as BuildGhost).ok).is_false()
	assert_bool((_n("Ghost") as BuildGhost).shows_cross()).is_true()
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.PLACING)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(9)

func test_standard_leaves_a_good_spot_plain() -> void:
	await _choose_lean_to_at(Vector2i(92, 11), F.DOWN)
	assert_bool((_n("Ghost") as BuildGhost).ok).is_true()
	assert_bool((_n("Ghost") as BuildGhost).shows_cross()).is_false()

func test_red_over_driftwood() -> void:
	await _choose_lean_to_at(Vector2i(88, 11), F.DOWN)
	assert_bool(_n("Ghost").ok).is_false()

func test_red_over_the_spring_base() -> void:
	await _choose_lean_to_at(Vector2i(96, 10), F.RIGHT)
	assert_bool(_n("Ghost").ok).is_false()

func test_red_over_a_boulder() -> void:
	await _choose_lean_to_at(Vector2i(62, 12), F.UP)
	assert_bool(_n("Ghost").ok).is_false()

func test_red_in_the_water() -> void:
	await _choose_lean_to_at(Vector2i(92, 14), F.DOWN)
	assert_bool(_n("Ghost").ok).is_false()

func test_esc_goes_back_to_list_spending_nothing() -> void:
	_driftwood(9)
	await _press(KEY_B)
	await _press(KEY_E)
	await _press(KEY_ESCAPE)
	assert_int(builder.mode).is_equal(M.LIST)
	assert_bool(_n("Ghost").visible).is_false()
	assert_int(builder.menu.highlighted).is_equal(0)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(9)
	await _press(KEY_E)
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(M.LIST)

func test_e_while_placing_does_not_take_things() -> void:
	_driftwood(9)
	player.global_position = BeachLayout.cell_base(BeachLayout.DRIFTWOOD[2]) + Vector2(-16, -2)
	player.facing = F.LEFT    # cell (87,13): the driftwood is still his E target (in reach), the outline on open sand
	await await_millis(50)
	assert_bool(_n("Prompt").visible).is_true()
	await _press(KEY_B)
	await _press(KEY_E)
	await await_millis(50)
	assert_bool(_n("Ghost").ok).is_true()
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.BUILDING)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(1)
	var wood := _n("Decor").get_children().filter(func(n: Node) -> bool:
		return n.scene_file_path.ends_with("driftwood.tscn"))
	assert_int(wood.size()).is_equal(BeachLayout.DRIFTWOOD.size())

func after_test() -> void:
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.use_controls(Controls.new())

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

func test_the_players_use_key_places() -> void:
	InputDevice.controls.set_slot(Controls.Action.USE, Controls.Device.KEYBOARD, 0, _key(KEY_F))
	_driftwood(9)
	await _stand(Vector2i(92, 11), F.DOWN)
	await _press(KEY_B)
	await _press(KEY_F)
	assert_int(builder.mode).is_equal(M.PLACING)
	await await_millis(50)
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.PLACING)
	await _press(KEY_F)
	assert_int(builder.mode).is_not_equal(M.PLACING)
