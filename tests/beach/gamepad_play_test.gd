extends GdUnitTestSuite
## On the beach a pad walks him with the left stick, runs with LB, uses with A; a lost pad stops him.

const SCENE := "res://src/beach/beach.tscn"
const K := Item.Kind
const START := Vector2(1480, 184)
const EPS := Vector2(0.5, 0.5)

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var camera: LooseCamera
var inventory: Inventory
var D := BeachLayout.cell_base(BeachLayout.driftwood()[2])

func before_test() -> void:
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	camera = beach.get_node("%Camera") as LooseCamera
	inventory = beach.inventory

func after_test() -> void:
	InputDevice.reset()
	for b: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_DPAD_RIGHT]:
		_send_pad(b, false)
	_send_stick(JOY_AXIS_LEFT_X, 0.0)

func _send_pad(button: JoyButton, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = button
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _send_stick(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _pad(button: JoyButton, pressed: bool) -> void:
	_send_pad(button, pressed)
	await runner.await_input_processed()

func _stick(axis: JoyAxis, value: float) -> void:
	_send_stick(axis, value)
	await runner.await_input_processed()

func _stand(at: Vector2, facing: Walk.Facing) -> void:
	player.global_position = at
	player.facing = facing
	camera.snap_to_target()
	await await_millis(50)

func test_stick_walks_at_one_speed_whatever_the_tilt() -> void:
	await _stick(JOY_AXIS_LEFT_X, 0.5)
	await await_millis(300)
	assert_vector(player.velocity).is_equal_approx(Vector2(48, 0), EPS)
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	await await_millis(100)
	assert_vector(player.velocity).is_equal_approx(Vector2(48, 0), EPS)
	await _stick(JOY_AXIS_LEFT_X, 0.0)

func test_stick_inside_dead_zone_stands_still() -> void:
	await _stick(JOY_AXIS_LEFT_X, 0.1)
	await await_millis(300)
	assert_vector(player.global_position).is_equal(START)
	await _stick(JOY_AXIS_LEFT_X, 0.0)

func test_lb_runs_and_alone_does_nothing() -> void:
	await _pad(JOY_BUTTON_LEFT_SHOULDER, true)
	await await_millis(300)
	assert_vector(player.global_position).is_equal(START)
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	await await_millis(100)
	assert_vector(player.velocity).is_equal_approx(Vector2(96, 0), EPS)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
	await _pad(JOY_BUTTON_LEFT_SHOULDER, false)

func test_d_pad_does_not_walk() -> void:
	await _pad(JOY_BUTTON_DPAD_RIGHT, true)
	await await_millis(300)
	assert_vector(player.global_position).is_equal(START)
	await _pad(JOY_BUTTON_DPAD_RIGHT, false)

func test_a_takes_driftwood_he_faces() -> void:
	await _stand(D + Vector2(-16, -2), Walk.Facing.RIGHT)
	await _pad(JOY_BUTTON_A, true)
	await _pad(JOY_BUTTON_A, false)
	await await_millis(50)
	assert_int(inventory.count(K.DRIFTWOOD)).is_equal(1)

func test_pad_and_keyboard_together() -> void:
	await _pad(JOY_BUTTON_LEFT_SHOULDER, true)
	runner.simulate_key_press(KEY_D)
	await runner.await_input_processed()
	await await_millis(300)
	assert_vector(player.velocity).is_equal_approx(Vector2(96, 0), EPS)
	runner.simulate_key_release(KEY_D)
	await runner.await_input_processed()
	await _pad(JOY_BUTTON_LEFT_SHOULDER, false)

func test_pad_disconnect_stops_him() -> void:
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	await await_millis(200)
	Input.joy_connection_changed.emit(0, false)
	await runner.await_input_processed()
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()
	await await_millis(50)
	var x := player.global_position.x
	await await_millis(200)
	assert_float(player.global_position.x).is_equal(x)
	await _stick(JOY_AXIS_LEFT_X, 0.0)

func test_pad_connect_changes_nothing() -> void:
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	await await_millis(200)
	Input.joy_connection_changed.emit(1, true)
	await runner.await_input_processed()
	await await_millis(100)
	assert_vector(player.velocity).is_equal_approx(Vector2(48, 0), EPS)
	await _stick(JOY_AXIS_LEFT_X, 0.0)
