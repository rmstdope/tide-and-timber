extends GdUnitTestSuite
## Builder.abandon_placing: leaves placing as if it never began.

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var builder: Builder
var inventory: Inventory

func before_test() -> void:
	runner = scene_runner("res://src/beach/beach.tscn")
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	builder = beach.get_node("%Builder") as Builder
	inventory = beach.inventory

func _stand(cell: Vector2i, facing: Walk.Facing) -> void:
	player.global_position = BeachLayout.cell_centre(cell)
	player.facing = facing
	await await_millis(50)

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()
	await await_millis(50)

func test_abandon_placing_spends_nothing_and_unfreezes() -> void:
	inventory.add(Item.Kind.DRIFTWOOD, 9)
	await _stand(Vector2i(92, 11), Walk.Facing.DOWN)
	await _press(KEY_B)
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(Builder.Mode.PLACING)
	builder.abandon_placing()
	assert_int(builder.mode).is_equal(Builder.Mode.CLOSED)
	assert_bool(beach.get_node("%Ghost").visible).is_false()
	assert_bool(beach.get_node("%KeyHint").visible).is_false()
	assert_int(beach.get_node("%Interactor").process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(9)

func test_abandon_placing_does_nothing_otherwise() -> void:
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(Builder.Mode.LIST)
	builder.abandon_placing()
	assert_int(builder.mode).is_equal(Builder.Mode.LIST)
	await _press(KEY_B)
