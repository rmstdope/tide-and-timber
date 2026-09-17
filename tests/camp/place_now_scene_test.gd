extends GdUnitTestSuite
## Debug placing: a lean-to or fire in front of him at once, by the rules of play, and removing builds.

const SCENE := "res://src/beach/beach.tscn"
const T := BuildMenu.Thing
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

func _n(unique: String) -> Node:
	return beach.get_node("%" + unique)

func _stand(cell: Vector2i, facing: F) -> void:
	player.global_position = BeachLayout.cell_centre(cell)
	player.facing = facing
	(beach.get_node("%Camera") as LooseCamera).snap_to_target()
	await await_millis(50)

func _clock() -> DayNight:
	var dn := load("res://src/day_night/day_night.tscn").instantiate() as DayNight
	beach.add_child(dn)
	beach.set_day_night(dn)
	dn.start()
	dn.set_process(false)   # the clock stands still while he is moved about
	return dn

func _camp() -> void:
	await _stand(Vector2i(92, 11), F.DOWN)
	assert_bool(builder.place_now(T.LEAN_TO)).is_true()
	await _stand(Vector2i(91, 14), F.RIGHT)
	assert_bool(builder.place_now(T.FIRE)).is_true()

func test_place_now_lean_to_stands_in_front_spending_nothing() -> void:
	await _stand(Vector2i(92, 11), F.DOWN)
	assert_bool(builder.place_now(T.LEAN_TO)).is_true()
	assert_object(builder.lean_to).is_not_null()
	assert_array(builder.lean_to.cells).is_equal(BuildSite.cells_for(T.LEAN_TO, Vector2i(92, 11), F.DOWN))
	assert_object(builder.lean_to.get_parent()).is_same(_n("World"))
	assert_int(builder.mode).is_equal(Builder.Mode.CLOSED)
	assert_bool((_n("BuildCover") as CanvasItem).visible).is_false()
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(0)

func test_place_now_fire_on_the_fire_spot_is_lit() -> void:
	var dn := _clock()
	dn.clock.total_minutes = 600.0
	await _camp()
	assert_that(builder.fire.cell).is_equal(Vector2i(92, 14))
	assert_bool(builder.fire.lit).is_true()
	assert_float(builder.fire.out_at).is_equal(FireLife.out_at(600.0))
	assert_float(dn.clock.total_minutes).is_equal(600.0)
	assert_bool(builder.has_shelter()).is_true()
	assert_bool(builder.shelter_line.is_showing()).is_false()

func test_place_now_fire_without_a_clock_never_goes_out() -> void:
	await _camp()
	assert_float(builder.fire.out_at).is_equal(INF)

func test_place_now_fire_replaces_ash() -> void:
	await _camp()
	builder.fire.put_out()
	var old := builder.fire
	assert_bool(builder.place_now(T.FIRE)).is_true()
	assert_bool(builder.fire != old).is_true()
	assert_bool(builder.fire.lit).is_true()
	await await_idle_frame()
	assert_bool(is_instance_valid(old)).is_false()

func test_place_now_fire_refused_off_the_fire_spot_or_without_lean_to() -> void:
	await _stand(Vector2i(91, 14), F.RIGHT)
	assert_bool(builder.place_now(T.FIRE)).is_false()
	assert_object(builder.fire).is_null()
	await _stand(Vector2i(92, 11), F.DOWN)
	builder.place_now(T.LEAN_TO)
	await _stand(Vector2i(95, 14), F.RIGHT)
	assert_bool(builder.place_now(T.FIRE)).is_false()
	assert_object(builder.fire).is_null()

func test_place_now_lean_to_refused_on_water() -> void:
	await _stand(Waking.WAKE_CELL, F.DOWN)
	assert_bool(builder.cells_in_front(T.LEAN_TO).any(func(c: Vector2i) -> bool: return not BuildSite.is_ground_ok(c))) \
		.is_true()
	assert_bool(builder.place_now(T.LEAN_TO)).is_false()
	assert_object(builder.lean_to).is_null()

func test_place_now_lean_to_refused_while_one_stands() -> void:
	await _stand(Vector2i(92, 11), F.DOWN)
	builder.place_now(T.LEAN_TO)
	var cells := builder.lean_to.cells.duplicate()
	await _stand(Vector2i(86, 11), F.DOWN)
	assert_bool(builder.can_place(T.LEAN_TO)).is_true()
	assert_bool(builder.place_now(T.LEAN_TO)).is_false()
	assert_array(builder.lean_to.cells).is_equal(cells)

func test_place_now_refused_unless_closed() -> void:
	inventory.add(Item.Kind.DRIFTWOOD, 9)
	await _stand(Vector2i(92, 11), F.DOWN)
	builder.open_list()
	assert_bool(builder.place_now(T.LEAN_TO)).is_false()
	assert_object(builder.lean_to).is_null()
	builder.close_list()

func test_remove_builds_clears_lean_to_and_fire() -> void:
	await _camp()
	var l := builder.lean_to
	var f := builder.fire
	builder.remove_builds()
	assert_object(builder.lean_to).is_null()
	assert_object(builder.fire).is_null()
	await await_idle_frame()
	assert_bool(is_instance_valid(l)).is_false()
	assert_bool(is_instance_valid(f)).is_false()
	builder.remove_builds()
	await _stand(Vector2i(92, 11), F.DOWN)
	assert_bool(builder.place_now(T.LEAN_TO)).is_true()

func test_debug_camp_is_what_the_save_writes_and_fits() -> void:
	await _camp()
	var data := beach.capture()
	assert_bool(Builder.camp_fits(data)).is_true()
	assert_array(data.lean_to_cells).is_equal(builder.lean_to.cells)
	assert_bool(data.has_fire).is_true()
	assert_that(data.fire_cell).is_equal(Vector2i(92, 14))
