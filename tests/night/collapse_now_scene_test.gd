extends "res://tests/night/night_scene_base.gd"
## Collapse now (the Debug panel's Survival page): the normal collapse, on demand, at any hour.

func _through_black() -> void:
	night.tick(4.5)
	night.tick(0.5)
	night.tick(2.0)
	night.tick(0.5)

func _through_got_up() -> void:
	_through_black()
	night.tick(1.5)
	night.tick(1.5)
	night.tick(2.2)

func test_collapse_now_starts_the_normal_collapse() -> void:
	_at(600.0)
	night.collapse_now()
	assert_object(night.collapse).is_not_null()
	assert_bool(player.control_enabled).is_false()

func test_collapse_now_in_daylight_wakes_next_morning() -> void:
	inventory.add(Item.Kind.DRIFTWOOD, 4)
	await await_idle_frame()
	_at(600.0)
	night.collapse_now()
	_through_black()
	assert_float(dn.clock.total_minutes).is_equal(NightWatch.next_morning(600.0))
	assert_float(dn.clock.total_minutes).is_equal(1800.0)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(2)
	assert_int(saves.size()).is_equal(1)
	night.tick(1.5)
	night.tick(1.5)
	night.tick(2.2)
	assert_object(night.collapse).is_null()
	assert_bool(player.control_enabled).is_true()

func test_collapse_now_wakes_beside_a_debug_lean_to() -> void:
	player.global_position = BeachLayout.cell_centre(Vector2i(92, 11))
	player.facing = Walk.Facing.DOWN
	assert_bool(builder.place_now(BuildMenu.Thing.LEAN_TO)).is_true()
	player.global_position = BeachLayout.cell_centre(Vector2i(80, 8))
	_at(600.0)
	night.collapse_now()
	_through_black()
	assert_vector(player.global_position) \
		.is_equal(BeachLayout.cell_centre(WakeSpot.beside_lean_to(builder.lean_to.anchor(), Waking.WAKE_CELL)))

func test_collapse_now_while_collapsing_does_nothing() -> void:
	_at(600.0)
	night.collapse_now()
	var c := night.collapse
	night.tick(1.0)
	var elapsed := c.phase_elapsed
	night.collapse_now()
	assert_object(night.collapse).is_same(c)
	assert_float(c.phase_elapsed).is_equal(elapsed)
