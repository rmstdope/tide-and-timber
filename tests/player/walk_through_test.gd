extends GdUnitTestSuite
## Walk through things: with the debug switch on he passes through anything solid.

var runner: GdUnitSceneRunner
var player: Player

func before_test() -> void:
	runner = scene_runner("res://src/beach/beach.tscn")
	player = runner.scene().get_node("%Player") as Player
	player.global_position = BeachLayout.cell_centre(Vector2i(92, 9))

func after_test() -> void:
	DebugSwitches.walk_through = false

func _walk_up() -> void:
	runner.simulate_action_press("move_up")
	await await_millis(600)
	runner.simulate_action_release("move_up")

func test_walk_through_starts_off() -> void:
	assert_bool(DebugSwitches.walk_through).is_false()

func test_without_walk_through_the_jungle_stops_him() -> void:
	await _walk_up()
	assert_float(player.global_position.y).is_greater_equal(149.0)
	assert_int(player.collision_mask).is_equal(Player.SOLID_MASK)

func test_with_walk_through_he_walks_into_the_jungle() -> void:
	DebugSwitches.walk_through = true
	await _walk_up()
	assert_float(player.global_position.y).is_less(140.0)
	assert_int(player.collision_mask).is_equal(Player.WALK_THROUGH_MASK)

func test_turning_it_off_makes_things_solid_again() -> void:
	DebugSwitches.walk_through = true
	await await_millis(50)
	DebugSwitches.walk_through = false
	await await_millis(50)
	assert_int(player.collision_mask).is_equal(Player.SOLID_MASK)
	assert_int(player.collision_layer).is_equal(1)
