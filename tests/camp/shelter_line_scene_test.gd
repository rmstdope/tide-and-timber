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

func _line() -> Control:
	return _n("ShelterLine") as Control

func test_line_text_on_the_band() -> void:
	assert_str((_line().get_node("Text") as Label).text).is_equal("That should see me through the night.")
	assert_bool(_line().visible).is_false()
	# 296 wide, centred, its bottom 14 above the picture's
	assert_vector(_line().position).is_equal(Vector2((Screen.WIDTH - 296) / 2, Screen.HEIGHT - 30))

func test_line_shows_when_fire_lit_then_fades() -> void:
	var dn := _clock()
	await _build_fire(dn, 900.0)
	assert_int(builder.mode).is_equal(M.CLOSED)
	assert_bool(_line().visible).is_true()
	assert_bool(builder.shelter_line.is_showing()).is_true()
	builder.tick(0.25)
	assert_float(_line().modulate.a).is_equal_approx(0.5, 0.05)
	builder.tick(4.75)
	assert_bool(_line().visible).is_false()

func test_line_not_shown_for_lean_to() -> void:
	await _build_lean_to_at_spawn()
	assert_bool(_line().visible).is_false()

func test_line_not_shown_while_black() -> void:
	var dn := _clock()
	await _place_fire(dn, 900.0)
	builder.tick(0.5)
	builder.tick(5.0)
	assert_bool(_line().visible).is_false()

func test_line_waits_for_sunset_line() -> void:
	var dn := _clock()
	await _build_fire(dn, 1090.0)
	assert_bool(dn.sunset.is_showing()).is_true()
	assert_bool(_line().visible).is_false()
	dn.tick(5.0)
	builder.tick(0.0)
	assert_bool(dn.sunset.is_showing()).is_false()
	assert_bool(_line().visible).is_true()

func test_line_steps_aside_for_sunset_line_starting_over_it() -> void:
	var dn := _clock()
	await _build_fire(dn, 1075.0)
	assert_bool(_line().visible).is_true()
	dn.sunset.start()
	builder.tick(0.0)
	assert_bool(_line().visible).is_false()
	dn.tick(5.0)
	builder.tick(0.0)
	assert_bool(dn.sunset.is_showing()).is_false()
	assert_bool(_line().visible).is_true()
	assert_float(_line().modulate.a).is_less(0.2)

func test_line_said_again_on_relight() -> void:
	var dn := _clock()
	await _build_fire(dn, 900.0)
	builder.tick(5.0)
	assert_bool(_line().visible).is_false()
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
	assert_bool(_line().visible).is_true()

func test_line_holds_while_list_open() -> void:
	await _build_fire(null, 0.0)
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(M.LIST)
	builder.tick(10.0)
	assert_bool(builder.shelter_line.is_showing()).is_true()
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(M.CLOSED)

func test_line_without_clock() -> void:
	await _build_fire(null, 0.0)
	assert_bool(_line().visible).is_true()
