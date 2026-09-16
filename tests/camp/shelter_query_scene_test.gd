extends GdUnitTestSuite

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

func _n(unique: String) -> Node:
	return beach.get_node("%" + unique)

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

func _build_lean_to_at_spawn() -> void:
	_driftwood(9)
	await _stand(Vector2i(92, 11), F.DOWN)
	await _press(KEY_B)
	await _press(KEY_E)
	await _press(KEY_E)
	builder.tick(0.5)
	builder.tick(5.0)
	builder.tick(0.5)

## Up to the placing press of a fire in front of the lean-to at spawn.
func _place_fire(dn: DayNight, at_minutes: float) -> void:
	await _build_lean_to_at_spawn()
	_driftwood(4)
	await _press(KEY_B)
	await _press(KEY_E)
	await _stand(Vector2i(91, 14), F.RIGHT)
	if dn:
		dn.clock.total_minutes = at_minutes
	await _press(KEY_E)

func _build_fire(dn: DayNight, at_minutes: float) -> void:
	await _place_fire(dn, at_minutes)
	builder.tick(0.5)
	builder.tick(5.0)
	builder.tick(0.5)

func test_no_shelter_without_camp() -> void:
	assert_bool(builder.has_shelter()).is_false()
	assert_bool(builder.in_firelight(player.global_position)).is_false()

func test_lean_to_alone_is_no_shelter() -> void:
	await _build_lean_to_at_spawn()
	assert_bool(builder.has_shelter()).is_false()
	assert_vector(builder.lean_to.global_position).is_equal(Vector2(1480, 224))

func test_lit_fire_is_shelter_and_light() -> void:
	var dn := _clock()
	await _build_fire(dn, 900.0)
	assert_bool(builder.has_shelter()).is_true()
	assert_bool(builder.in_firelight(Vector2(1480, 232))).is_true()
	assert_bool(builder.in_firelight(Vector2(1480 + 48, 232))).is_true()
	assert_bool(builder.in_firelight(Vector2(1480 + 49, 232))).is_false()
	assert_vector(builder.fire.light_centre()).is_equal(Vector2(1480, 232))

func test_ash_is_no_shelter() -> void:
	var dn := _clock()
	await _build_fire(dn, 900.0)
	dn.clock.total_minutes = FireLife.out_at(dn.clock.total_minutes)
	builder.tick(0.0)
	assert_bool(builder.has_shelter()).is_false()
	assert_bool(builder.in_firelight(Vector2(1480, 232))).is_false()
