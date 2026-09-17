extends GdUnitTestSuite
## Building on a pad: Y opens and toggles the list, A chooses and places, B goes back.

const SCENE := "res://src/beach/beach.tscn"
const F := Walk.Facing
const M := Builder.Mode

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var builder: Builder
var inventory: Inventory

func before_test() -> void:
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	builder = beach.get_node("%Builder") as Builder
	inventory = beach.inventory

func after_test() -> void:
	InputDevice.reset()
	_send_stick(JOY_AXIS_RIGHT_Y, 0.0)
	_send_stick(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	InputDevice.use_controls(Controls.new())
	_send_stick(JOY_AXIS_LEFT_X, 0.0)
	_send_stick(JOY_AXIS_LEFT_Y, 0.0)
	InputDevice.reset()

func _n(unique: String) -> Node:
	return beach.get_node("%" + unique)

func _stand(cell: Vector2i, facing: F) -> void:
	player.global_position = BeachLayout.cell_centre(cell)
	player.facing = facing
	(beach.get_node("%Camera") as LooseCamera).snap_to_target()
	await await_millis(50)

func _driftwood(n: int) -> void:
	inventory.add(Item.Kind.DRIFTWOOD, n)

func _send_stick(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _pad(button: JoyButton, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = button
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func _stick(axis: JoyAxis, value: float) -> void:
	_send_stick(axis, value)
	await runner.await_input_processed()

func _tap(button: JoyButton) -> void:
	await _pad(button, true)
	await _pad(button, false)
	await await_millis(50)

func _to_placing() -> void:
	_driftwood(9)
	await _stand(Vector2i(92, 11), F.DOWN)
	await _tap(JOY_BUTTON_Y)
	await _tap(JOY_BUTTON_A)

func test_y_opens_the_list() -> void:
	_driftwood(9)
	await _tap(JOY_BUTTON_Y)
	assert_int(builder.mode).is_equal(M.LIST)

func test_b_closes_and_y_toggles_closed() -> void:
	_driftwood(9)
	await _tap(JOY_BUTTON_Y)
	await _tap(JOY_BUTTON_B)
	assert_int(builder.mode).is_equal(M.CLOSED)
	await _tap(JOY_BUTTON_Y)
	assert_int(builder.mode).is_equal(M.LIST)
	await _tap(JOY_BUTTON_Y)
	assert_int(builder.mode).is_equal(M.CLOSED)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(9)

func test_a_chooses_then_places() -> void:
	await _to_placing()
	assert_int(builder.mode).is_equal(M.PLACING)
	await _tap(JOY_BUTTON_A)
	assert_int(builder.mode).is_equal(M.BUILDING)

func test_b_and_y_go_back_from_placing() -> void:
	await _to_placing()
	assert_int(builder.mode).is_equal(M.PLACING)
	await _tap(JOY_BUTTON_B)
	assert_int(builder.mode).is_equal(M.LIST)
	await _tap(JOY_BUTTON_A)
	assert_int(builder.mode).is_equal(M.PLACING)
	await _tap(JOY_BUTTON_Y)
	assert_int(builder.mode).is_equal(M.LIST)

func test_stick_moves_the_outline_while_placing() -> void:
	await _to_placing()
	assert_int(builder.mode).is_equal(M.PLACING)
	var x := (_n("Ghost") as Node2D).position.x
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	await await_millis(600)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	await await_millis(50)
	assert_float((_n("Ghost") as Node2D).position.x).is_greater(x)

func test_start_does_not_close_the_list() -> void:
	_driftwood(9)
	await _tap(JOY_BUTTON_Y)
	await _tap(JOY_BUTTON_START)
	assert_int(builder.mode).is_equal(M.LIST)

func test_y_during_the_build_fade_does_nothing() -> void:
	await _to_placing()
	await _tap(JOY_BUTTON_A)
	assert_int(builder.mode).is_equal(M.BUILDING)
	await _tap(JOY_BUTTON_Y)
	assert_int(builder.mode).is_equal(M.BUILDING)
	assert_bool((_n("BuildList") as Control).visible).is_false()

func test_disconnect_with_list_open_changes_nothing() -> void:
	_driftwood(9)
	await _tap(JOY_BUTTON_Y)
	Input.joy_connection_changed.emit(0, false)
	await runner.await_input_processed()
	assert_int(builder.mode).is_equal(M.LIST)
	assert_bool((_n("BuildList") as Control).visible).is_true()

func test_disconnect_while_placing_stops_the_outline() -> void:
	await _to_placing()
	assert_int(builder.mode).is_equal(M.PLACING)
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	await await_millis(100)
	Input.joy_connection_changed.emit(0, false)
	await runner.await_input_processed()
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()
	await await_millis(50)
	var at := player.global_position
	var ghost_x := (_n("Ghost") as Node2D).position.x
	await await_millis(600)
	assert_vector(player.global_position).is_equal(at)
	assert_float((_n("Ghost") as Node2D).position.x).is_equal(ghost_x)
	assert_int(builder.mode).is_equal(M.PLACING)
	await _stick(JOY_AXIS_LEFT_X, 0.0)

func _list_after_one_down() -> int:
	var want := BuildMenu.new()
	want.set_state(9, false, false)
	want.open()
	want.move(1)
	return want.highlighted

func test_d_pad_moves_the_list_highlight() -> void:
	_driftwood(9)
	await _tap(JOY_BUTTON_Y)
	await _tap(JOY_BUTTON_DPAD_DOWN)
	assert_int(builder.menu.highlighted).is_equal(_list_after_one_down())

func test_held_stick_moves_the_list_one_line() -> void:
	_driftwood(9)
	await _tap(JOY_BUTTON_Y)
	for v: float in [0.6, 0.7, 0.9, 1.0]:   # an even count: on two lines, four steps would land back where it started
		await _stick(JOY_AXIS_LEFT_Y, v)
	assert_int(builder.menu.highlighted).is_equal(_list_after_one_down())
	await _stick(JOY_AXIS_LEFT_Y, 0.0)

func test_stick_in_the_list_does_not_walk() -> void:
	_driftwood(9)
	await _tap(JOY_BUTTON_Y)
	var at := player.global_position
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	await await_millis(200)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	assert_vector(player.global_position).is_equal(at)

func test_build_list_on_a_stick_opens_once() -> void:
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_RIGHT_Y
	m.axis_value = -1.0
	InputDevice.controls.set_slot(Controls.Action.BUILD_LIST, Controls.Device.CONTROLLER, 0, m)
	_driftwood(9)
	await _stick(JOY_AXIS_RIGHT_Y, -0.6)
	assert_int(builder.mode).is_equal(M.LIST)
	await _stick(JOY_AXIS_RIGHT_Y, -1.0)
	assert_int(builder.mode).is_equal(M.LIST)
	await _stick(JOY_AXIS_RIGHT_Y, 0.0)
	await _stick(JOY_AXIS_RIGHT_Y, 0.9)
	assert_int(builder.mode).is_equal(M.LIST)
	await _stick(JOY_AXIS_RIGHT_Y, 0.0)
	await _stick(JOY_AXIS_RIGHT_Y, -0.9)
	assert_int(builder.mode).is_equal(M.CLOSED)

func test_use_on_a_trigger_places_once() -> void:
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_TRIGGER_RIGHT
	m.axis_value = 1.0
	InputDevice.controls.set_slot(Controls.Action.USE, Controls.Device.CONTROLLER, 0, m)
	await _to_placing()
	var before := inventory.count(Item.Kind.DRIFTWOOD)
	await _stick(JOY_AXIS_TRIGGER_RIGHT, 0.9)
	assert_int(builder.mode).is_equal(M.BUILDING)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(before - BuildMenu.COSTS[builder.placing])
