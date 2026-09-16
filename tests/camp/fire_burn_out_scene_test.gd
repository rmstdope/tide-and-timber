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

func test_fire_out_at_first_0700_after_lit() -> void:
	var dn := _clock()
	await _build_fire(dn, 1300.0)
	var fire := builder.fire
	assert_bool(fire.lit).is_true()
	assert_float(fire.out_at).is_equal(1860.0)
	dn.clock.total_minutes = 1859.0
	builder.tick(0.0)
	assert_bool(fire.lit).is_true()
	dn.clock.total_minutes = 1860.0
	builder.tick(0.0)
	assert_bool(fire.lit).is_false()
	assert_bool(fire.glow.visible).is_false()
	assert_object(fire.get_parent()).is_same(_n("World"))

func test_fire_built_over_0700_burns_until_next() -> void:
	var dn := _clock()
	await _build_fire(dn, 1440.0 + 400.0)
	assert_bool(builder.fire.lit).is_true()
	assert_float(builder.fire.out_at).is_equal(3300.0)

func test_fire_out_when_picture_returns_if_0700_in_jump() -> void:
	var dn := _clock()
	var f := CampFire.new()
	f.cell = Vector2i(92, 14)
	f.position = Vector2(1480, 240)
	f.out_at = 1860.0
	_n("World").add_child(f)
	builder.fire = f
	_driftwood(9)
	await _stand(Vector2i(92, 11), F.DOWN)
	await _press(KEY_B)
	await _press(KEY_E)
	dn.clock.total_minutes = 1845.0
	await _press(KEY_E)
	builder.tick(0.5)
	builder.tick(5.0)
	# Still building and still covered; real time during the press's await may have begun the fade in.
	assert_bool(f.lit).is_false()
	assert_int(builder.mode).is_equal(M.BUILDING)
	assert_float(_n("BuildCover").modulate.a).is_greater(0.5)
	builder.tick(0.5)
	assert_int(builder.mode).is_equal(M.CLOSED)
	assert_bool(f.lit).is_false()

func test_already_lit_only_while_burning() -> void:
	var dn := _clock()
	await _build_fire(dn, 1300.0)
	await _press(KEY_B)
	var list := _n("BuildList") as BuildList
	assert_str(list.cost_labels[1].text).is_equal("Already lit")
	await _press(KEY_B)
	dn.clock.total_minutes = 1860.0
	builder.tick(0.0)
	await _press(KEY_B)
	assert_str(list.cost_labels[1].text).is_equal("1/4 driftwood")
	assert_bool(builder.menu.can_build(BuildMenu.Thing.FIRE)).is_false()
	await _press(KEY_B)

func test_rebuild_on_ash_replaces_it() -> void:
	var dn := _clock()
	await _build_fire(dn, 1300.0)
	var old := builder.fire
	dn.clock.total_minutes = 1860.0
	builder.tick(0.0)
	_driftwood(4)
	await _press(KEY_B)
	var list := _n("BuildList") as BuildList
	assert_int(builder.menu.highlighted).is_equal(1)
	assert_str(list.cost_labels[1].text).is_equal("5/4 driftwood")
	await _press(KEY_E)
	await _stand(Vector2i(91, 14), F.RIGHT)
	await _press(KEY_E)
	builder.tick(0.5)
	assert_object(builder.fire).is_not_same(old)
	assert_bool(builder.fire.lit).is_true()
	assert_bool(old.is_queued_for_deletion()).is_true()
	builder.tick(5.0)
	builder.tick(0.5)
	assert_float(builder.fire.out_at).is_equal(3300.0)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(1)

func test_fire_never_out_without_clock() -> void:
	await _build_fire(null, 0.0)
	assert_bool(builder.fire.lit).is_true()
	assert_float(builder.fire.out_at).is_equal(INF)
	builder.tick(1.0)
	assert_bool(builder.fire.lit).is_true()
