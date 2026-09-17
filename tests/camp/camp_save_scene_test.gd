extends GdUnitTestSuite
## The camp as the beach captures it, with a clock: a fire built across dawn, and one rebuilt on ash.

const SCENE := "res://src/beach/beach.tscn"
const F := Walk.Facing

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

func _place_fire(dn: DayNight, at_minutes: float) -> void:
	await _build_lean_to_at_spawn()
	_driftwood(4)
	await _press(KEY_B)
	await _press(KEY_E)
	await _stand(Vector2i(91, 14), F.RIGHT)
	if dn:
		dn.clock.total_minutes = at_minutes
	await _press(KEY_E)

func test_fire_built_across_dawn_saves_its_real_out_at() -> void:
	var dn := _clock()
	var captures: Array[SaveData] = []
	dn.dawn.connect(func() -> void: captures.append(beach.capture()))
	await _place_fire(dn, 1440.0 + 350.0)
	builder.tick(0.5)
	builder.tick(5.0)
	builder.tick(0.5)
	assert_int(captures.size()).is_equal(1)
	assert_bool(captures[0].fire_lit).is_true()
	assert_float(captures[0].fire_out_at).is_equal(1860.0)
	assert_float(builder.fire.out_at).is_equal(captures[0].fire_out_at)
	await await_idle_frame()

func test_rebuilt_on_ash_captures_the_new_fire() -> void:
	var dn := _clock()
	await _place_fire(dn, 1300.0)
	builder.tick(0.5)
	builder.tick(5.0)
	builder.tick(0.5)
	dn.clock.total_minutes = 1860.0
	builder.tick(0.0)
	_driftwood(4)
	await _press(KEY_B)
	await _press(KEY_E)
	await _stand(Vector2i(91, 14), F.RIGHT)
	await _press(KEY_E)
	builder.tick(0.5)
	builder.tick(5.0)
	builder.tick(0.5)
	var d := beach.capture()
	assert_bool(d.fire_lit).is_true()
	assert_float(d.fire_out_at).is_equal(3300.0)
	await await_idle_frame()
