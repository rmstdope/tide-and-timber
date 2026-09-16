extends GdUnitTestSuite

const SCENE := "res://src/beach/beach.tscn"
const SPAWN := Vector2(1480, 184)

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var camera: LooseCamera
var inventory: Inventory
var walker: ClickWalker
var D := BeachLayout.cell_base(BeachLayout.DRIFTWOOD[2])

func before_test() -> void:
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	camera = beach.get_node("%Camera") as LooseCamera
	inventory = beach.inventory
	walker = beach.get_node("%ClickWalker") as ClickWalker

func _stand(at: Vector2) -> void:
	player.global_position = at
	camera.snap_to_target()
	await await_millis(50)

func _click(world: Vector2) -> void:
	var screen := player.get_viewport().get_final_transform() * player.get_canvas_transform() * world
	runner.simulate_mouse_move(screen)
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()

func _marks() -> Array:
	return beach.get_node("%Decor").get_children().filter(func(n: Node) -> bool:
		return n is ClickMark and not n.is_queued_for_deletion())

func _line_text() -> String:
	var line := player.get_node_or_null("RisingLine")
	if line == null:
		return ""
	var labels := line.find_children("*", "Label", true, false)
	return (labels[0] as Label).text if labels.size() > 0 else ""

func _all_empty() -> bool:
	for i in Inventory.SLOT_COUNT:
		if inventory.slot_kind(i) != Inventory.EMPTY:
			return false
	return true

func test_not_walking_at_start() -> void:
	assert_bool(walker.is_walking()).is_false()
	assert_vector(player.auto_direction).is_equal(Vector2.ZERO)

func test_click_sand_walks_there_with_mark() -> void:
	await _click(SPAWN + Vector2(40, 0))
	assert_int(_marks().size()).is_equal(1)
	assert_vector((_marks()[0] as ClickMark).position).is_equal(Vector2(1520, 184))
	assert_bool(walker.is_walking()).is_true()
	await await_millis(1500)
	assert_float(player.global_position.distance_to(Vector2(1520, 184))).is_less_equal(2.0)
	assert_bool(walker.is_walking()).is_false()
	assert_vector(player.auto_direction).is_equal(Vector2.ZERO)
	assert_array(_marks()).is_empty()
	assert_str(_line_text()).is_equal("")

func test_click_goes_round_rock() -> void:
	await _stand(Vector2(1570, 220))
	await _click(Vector2(1616, 220))
	await await_millis(2500)
	assert_float(player.global_position.distance_to(Vector2(1616, 220))).is_less_equal(2.0)
	assert_str(_line_text()).is_equal("")

func test_click_deep_water_stops_at_edge_cant_reach() -> void:
	await _stand(Vector2(1480, 244))
	await _click(Vector2(1480, 300))   # deep water, above the bar on screen
	assert_int(_marks().size()).is_equal(1)
	await assert_signal(walker).wait_until(5000).is_emitted("cant_reach")
	assert_float(player.global_position.y).is_between(276.0, 286.0)
	assert_str(_line_text()).is_equal("Can't reach that")

func test_movement_key_stops_walk() -> void:
	await _click(SPAWN + Vector2(200, 0))
	await await_millis(400)
	runner.simulate_action_press("move_up")
	await await_millis(100)
	assert_bool(walker.is_walking()).is_false()
	runner.simulate_action_release("move_up")
	await await_millis(100)
	var at := player.global_position
	await await_millis(400)
	assert_vector(player.global_position).is_equal(at)
	assert_vector(player.auto_direction).is_equal(Vector2.ZERO)
	assert_str(_line_text()).is_equal("")

func test_second_click_redirects() -> void:
	await _click(Vector2(1600, 184))
	await await_millis(400)
	await _click(Vector2(1400, 184))
	await await_millis(3500)
	assert_float(player.global_position.distance_to(Vector2(1400, 184))).is_less_equal(2.0)
	assert_int(_marks().size()).is_less_equal(1)

func test_click_on_bar_does_not_walk() -> void:
	runner.simulate_mouse_move(player.get_viewport().get_final_transform() * Vector2(100, 165))
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()
	await await_millis(300)
	assert_vector(player.global_position).is_equal(SPAWN)
	assert_bool(walker.is_walking()).is_false()
	assert_array(_marks()).is_empty()

func test_click_driftwood_walks_and_takes_it() -> void:
	await _click(Vector2(1416, 220))
	assert_array(_marks()).is_empty()
	assert_bool(walker.is_walking()).is_true()
	await assert_signal(walker).wait_until(4000).is_emitted("arrived")
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(1)
	assert_bool(walker.is_walking()).is_false()
	assert_float(player.global_position.distance_to(D)).is_less_equal(Reach.DISTANCE)
	assert_str(_line_text()).is_equal("+1 Driftwood")

func test_click_usable_beside_him_uses_it_at_once() -> void:
	await _stand(D + Vector2(-16, -2))
	await _click(Vector2(1416, 220))
	await await_millis(100)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(1)
	assert_vector(player.global_position).is_equal(D + Vector2(-16, -2))

func test_click_thing_not_usable_walks_like_sand() -> void:
	await _click(Vector2(1592, 212))
	assert_int(_marks().size()).is_equal(1)
	await await_millis(3500)
	assert_float(player.global_position.distance_to(Vector2(1592, 212))).is_less_equal(2.0)
	assert_bool(_all_empty()).is_true()
	assert_str(_line_text()).is_equal("")

func test_goal_gone_before_arrival_shows_nothing() -> void:
	await _click(Vector2(1416, 220))
	assert_bool(walker.is_walking()).is_true()
	var wood := beach.get_node("%Decor").get_children().filter(func(n: Node) -> bool:
		return n.scene_file_path.ends_with("driftwood.tscn") and (n as Node2D).position == D)[0] as Node
	wood.queue_free()
	await assert_signal(walker).wait_until(4000).is_emitted("arrived")
	await assert_signal(walker).wait_until(200).is_not_emitted("cant_reach")
	assert_str(_line_text()).is_equal("")
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(0)
