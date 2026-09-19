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
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_E
	echo.pressed = true
	echo.echo = true
	Input.parse_input_event(echo)
	await await_millis(100)
	runner.simulate_key_release(KEY_E)
	await runner.await_input_processed()
	assert_int(inventory.count(K.DRIFTWOOD)).is_equal(1)

func test_prompt_over_usable_until_away_or_taken() -> void:
	var prompt := beach.get_node("%Prompt") as UsePrompt
	await _stand(D + Vector2(-16, -2), Walk.Facing.RIGHT)
	assert_bool(prompt.visible).is_true()
	assert_vector(prompt.global_position).is_equal(D + Vector2(0, -10))
	assert_str(prompt.verb_label.text).is_equal("Take")
	await _stand(BeachLayout.cell_centre(BeachLayout.SPAWN_CELL), Walk.Facing.DOWN)
	assert_bool(prompt.visible).is_false()
	await _stand(D + Vector2(-16, -2), Walk.Facing.RIGHT)
	assert_bool(prompt.visible).is_true()
	await _press_e()
	assert_bool(prompt.visible).is_false()

func test_prompt_over_faced_else_closest() -> void:
	var prompt := beach.get_node("%Prompt") as UsePrompt
	_second_driftwood(D + Vector2(-26, 0))
	await _stand(D + Vector2(-16, -2), Walk.Facing.RIGHT)
	assert_vector(prompt.global_position).is_equal(D + Vector2(0, -10))
	await _stand(D + Vector2(-16, -2), Walk.Facing.LEFT)
	assert_vector(prompt.global_position).is_equal(D + Vector2(-26, -10))
	await _stand(D + Vector2(-16, -2), Walk.Facing.UP)
	assert_vector(prompt.global_position).is_equal(D + Vector2(-26, -10))

func test_bar_counts_what_he_takes() -> void:
	var bar := beach.get_node("%ItemBar") as ItemBar
	await _stand(D + Vector2(-16, -2), Walk.Facing.RIGHT)
	await _press_e()
	assert_int(bar.slots[0].kind).is_equal(K.DRIFTWOOD)
	assert_str(bar.slots[0].count_text()).is_equal("")

func test_slot_name_on_pointer_rest() -> void:
	var bar := beach.get_node("%ItemBar") as ItemBar
	await _stand(D + Vector2(-16, -2), Walk.Facing.RIGHT)
	await _press_e()
	bar.slots[0].mouse_entered.emit()
	assert_str(bar.name_label.text).is_equal("Driftwood")
	assert_bool(bar.name_plank.visible).is_true()

func test_gain_line_rises_and_is_gone_within_a_second() -> void:
	await _stand(D + Vector2(-16, -2), Walk.Facing.RIGHT)
	await _press_e()
	var line := player.get_node_or_null("RisingLine") as RisingLine
	assert_object(line).is_not_null()
	assert_str((line.find_children("*", "Label", false, false)[0] as Label).text).is_equal("+1 Driftwood")
	await await_millis(300)
	assert_float(line.position.y).is_less(RisingLine.START.y)
	await await_millis(900)
	assert_object(player.get_node_or_null("RisingLine")).is_null()
