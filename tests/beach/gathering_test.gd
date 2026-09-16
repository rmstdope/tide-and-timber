extends GdUnitTestSuite

const SCENE := "res://src/beach/beach.tscn"
const K := Item.Kind

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var camera: LooseCamera
var inventory: Inventory
var D := BeachLayout.cell_base(BeachLayout.DRIFTWOOD[2])
var S := BeachLayout.cell_base(BeachLayout.SHELLFISH[3])

func before_test() -> void:
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	camera = beach.get_node("%Camera") as LooseCamera
	inventory = beach.inventory

func _stand(at: Vector2, facing: Walk.Facing) -> void:
	player.global_position = at
	player.facing = facing
	camera.snap_to_target()
	await await_millis(50)

func _press_e() -> void:
	runner.simulate_key_pressed(KEY_E)
	await runner.await_input_processed()
	await await_millis(50)

func _count(suffix: String) -> int:
	return beach.get_node("%Decor").get_children().filter(func(n: Node) -> bool:
		return n.scene_file_path.ends_with(suffix) and not n.is_queued_for_deletion()).size()

func _all_empty() -> bool:
	for i in Inventory.SLOT_COUNT:
		if inventory.slot_kind(i) != Inventory.EMPTY:
			return false
	return true

func _second_driftwood(at: Vector2) -> void:
	var extra := Beach.DRIFTWOOD.instantiate() as Node2D
	extra.position = at
	beach.get_node("%Decor").add_child(extra)

func test_new_game_has_full_beach_and_empty_inventory() -> void:
	assert_int(_count("driftwood.tscn")).is_equal(BeachLayout.DRIFTWOOD.size())
	assert_int(_count("shellfish.tscn")).is_equal(BeachLayout.SHELLFISH.size())
	assert_bool(_all_empty()).is_true()
	await await_millis(50)
	assert_bool(beach.get_node("%Prompt").visible).is_false()

func test_e_takes_driftwood_he_faces() -> void:
	await _stand(D + Vector2(-16, -2), Walk.Facing.RIGHT)
	await _press_e()
	assert_int(inventory.count(K.DRIFTWOOD)).is_equal(1)
	assert_int(inventory.slot_kind(0)).is_equal(K.DRIFTWOOD)
	assert_int(_count("driftwood.tscn")).is_equal(BeachLayout.DRIFTWOOD.size() - 1)
	assert_bool(beach.get_node("%Decor").get_children().any(func(n: Node) -> bool:
		return n.scene_file_path.ends_with("driftwood.tscn") and (n as Node2D).position == D)).is_false()

func test_e_takes_shellfish() -> void:
	await _stand(S + Vector2(-16, -2), Walk.Facing.RIGHT)
	await _press_e()
	assert_int(inventory.count(K.SHELLFISH)).is_equal(1)
	assert_int(_count("shellfish.tscn")).is_equal(BeachLayout.SHELLFISH.size() - 1)

func test_e_far_from_anything_does_nothing() -> void:
	await _press_e()
	assert_bool(_all_empty()).is_true()
	assert_int(_count("driftwood.tscn")).is_equal(BeachLayout.DRIFTWOOD.size())
	assert_int(_count("shellfish.tscn")).is_equal(BeachLayout.SHELLFISH.size())

func test_holding_e_takes_one() -> void:
	_second_driftwood(D + Vector2(-8, 0))
	await _stand(D + Vector2(-16, -2), Walk.Facing.RIGHT)
	runner.simulate_key_press(KEY_E)
	await await_millis(600)
	runner.simulate_key_release(KEY_E)
	await runner.await_input_processed()
	assert_int(inventory.count(K.DRIFTWOOD)).is_equal(1)
