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

## Building: driftwood spent, black with knocks, the thing stands, 30 minutes on.

func _to_building(dn: DayNight = null, minutes := -1.0) -> void:
	_driftwood(9)
	await _stand(Vector2i(92, 11), F.DOWN)
	await _press(KEY_B)
	await _press(KEY_E)
	if dn and minutes >= 0.0:
		dn.clock.total_minutes = minutes
	await _press(KEY_E)

func _build_lean_to_at_spawn() -> void:
	await _to_building()
	builder.tick(0.5)
	builder.tick(5.0)
	builder.tick(0.5)

func test_placing_spends_and_goes_black_then_stands() -> void:
	var dn := _clock()
	await _to_building()
	assert_int(builder.mode).is_equal(M.BUILDING)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(1)
	assert_object(builder.lean_to).is_null()
	assert_bool(_n("Ghost").visible).is_false()
	assert_bool(_n("KeyHint").visible).is_false()
	assert_int(_n("World").process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	var m := dn.clock.total_minutes
	builder.tick(0.5)
	assert_int(builder.fade.phase).is_equal(BuildFade.Phase.BLACK)
	assert_float(_n("BuildCover").modulate.a).is_equal(1.0)
	assert_object(builder.lean_to).is_not_null()
	assert_object(builder.lean_to.get_parent()).is_same(_n("World"))
	assert_vector(builder.lean_to.position).is_equal(Vector2(1480, 224))
	assert_bool(_n("BuildSound").audible).is_true()
	assert_float(dn.clock.total_minutes).is_equal(m)
	builder.tick(5.0)
	assert_float(dn.clock.total_minutes).is_equal(m + 30.0)
	assert_bool(_n("BuildSound").audible).is_false()
	builder.tick(0.5)
	assert_int(builder.mode).is_equal(M.CLOSED)
	assert_bool(_n("BuildCover").visible).is_false()
	assert_int(_n("World").process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_vector(player.global_position).is_equal(BeachLayout.cell_centre(Vector2i(92, 11)))

func test_input_ignored_while_black() -> void:
	await _to_building()
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(M.BUILDING)
	assert_bool(_list().visible).is_false()
	await _press(KEY_ESCAPE)
	assert_int(builder.mode).is_equal(M.BUILDING)
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()
	assert_int(builder.mode).is_equal(M.BUILDING)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(1)

func test_sunset_line_after_picture_returns() -> void:
	var dn := _clock()
	await _to_building(dn, 1100.0)
	builder.tick(0.5)
	builder.tick(5.0)
	assert_bool(dn.sunset.is_showing()).is_false()
	builder.tick(0.5)
	assert_bool(dn.sunset.is_showing()).is_true()

func test_no_sunset_line_when_not_crossed() -> void:
	var dn := _clock()
	await _to_building(dn, 1000.0)
	builder.tick(0.5)
	builder.tick(5.0)
	builder.tick(0.5)
	assert_bool(dn.sunset.is_showing()).is_false()

func test_beach_alone_builds_without_clock() -> void:
	await _build_lean_to_at_spawn()
	assert_int(builder.mode).is_equal(M.CLOSED)
	assert_object(builder.lean_to).is_not_null()

func test_lean_to_is_solid() -> void:
	await _build_lean_to_at_spawn()
	await _stand(Vector2i(92, 11), F.DOWN)
	runner.simulate_action_press("move_down")
	await await_millis(500)
	runner.simulate_action_release("move_down")
	assert_float(player.global_position.y).is_less_equal(192.0)

func test_only_one_lean_to() -> void:
	await _build_lean_to_at_spawn()
	_driftwood(8)
	await _press(KEY_B)
	assert_str(_list().cost_labels[0].text).is_equal("Already built")
	assert_int(builder.menu.highlighted).is_equal(1)
	assert_str(_list().cost_labels[1].text).is_equal("9/4 driftwood")

func test_outline_red_over_lean_to() -> void:
	await _build_lean_to_at_spawn()
	_driftwood(8)
	await _press(KEY_B)
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.PLACING)
	assert_int(builder.placing).is_equal(T.FIRE)
	await _stand(Vector2i(92, 11), F.DOWN)
	await await_millis(50)
	assert_bool(_n("Ghost").ok).is_false()

func test_fire_only_on_spot_in_front_then_lit() -> void:
	await _build_lean_to_at_spawn()
	_driftwood(4)
	await _press(KEY_B)
	assert_int(builder.menu.highlighted).is_equal(1)
	await _press(KEY_E)
	await _stand(Vector2i(89, 14), F.RIGHT)
	await await_millis(50)
	assert_bool(_n("Ghost").ok).is_false()
	await _stand(Vector2i(91, 14), F.RIGHT)
	await await_millis(50)
	assert_bool(_n("Ghost").ok).is_true()
	assert_vector(_n("Ghost").position).is_equal(Vector2(1480, 240))
	await _press(KEY_E)
	builder.tick(0.5)
	assert_object(builder.fire).is_not_null()
	assert_bool(builder.fire.lit).is_true()
	assert_vector(builder.fire.position).is_equal(Vector2(1480, 240))
	builder.tick(5.0)
	builder.tick(0.5)
	assert_int(builder.mode).is_equal(M.CLOSED)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(1)
	await _press(KEY_B)
	assert_str(_list().cost_labels[1].text).is_equal("Already lit")
	assert_int(builder.menu.highlighted).is_equal(-1)
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.LIST)
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(M.CLOSED)
