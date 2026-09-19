extends GdUnitTestSuite

const SCENE := "res://src/beach/beach.tscn"
const K := Item.Kind

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var camera: LooseCamera
var inventory: Inventory
var prompt: UsePrompt
var P := BeachLayout.cell_base(BeachLayout.palms()[6])
var R := BeachLayout.cell_base(BeachLayout.rocks()[5])
var B := BeachLayout.cell_base(BeachLayout.boulders()[3])
var W := BeachLayout.cell_base(BeachLayout.springs()[0])

func before_test() -> void:
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	camera = beach.get_node("%Camera") as LooseCamera
	inventory = beach.inventory
	prompt = beach.get_node("%Prompt") as UsePrompt

func _stand(at: Vector2, facing: Walk.Facing) -> void:
	player.global_position = at
	player.facing = facing
	camera.snap_to_target()
	await await_millis(50)

func _press_e() -> void:
	runner.simulate_key_pressed(KEY_E)
	await runner.await_input_processed()
	await await_millis(50)

func _rising() -> String:
	var line := player.get_node_or_null("RisingLine")
	if line == null:
		return ""
	var labels := line.find_children("*", "Label", false, false)
	return "" if labels.is_empty() else (labels[0] as Label).text

func _count(parent: Node, suffix: String) -> int:
	return parent.get_children().filter(func(n: Node) -> bool:
		return n.scene_file_path.ends_with(suffix) and not n.is_queued_for_deletion()).size()

func _all_empty() -> bool:
	for i in Inventory.SLOT_COUNT:
		if inventory.slot_kind(i) != Inventory.EMPTY:
			return false
	return true

func test_rock_without_coconut_shows_nothing() -> void:
	await _stand(R + Vector2(-14, 0), Walk.Facing.RIGHT)
	assert_bool(prompt.visible).is_false()
	await _press_e()
	assert_bool(_all_empty()).is_true()

func test_crack_at_rock_turns_coconut_into_shell() -> void:
	inventory.add(K.COCONUT)
	await _stand(R + Vector2(-14, 0), Walk.Facing.RIGHT)
	assert_bool(prompt.visible).is_true()
	assert_str(prompt.verb_label.text).is_equal("Crack")
	assert_vector(prompt.global_position).is_equal(R + Vector2(0, -12))
	await _press_e()
	assert_int(inventory.count(K.COCONUT)).is_equal(0)
	assert_int(inventory.count(K.EMPTY_SHELL)).is_equal(1)
	assert_str(_rising()).is_equal("+1 Empty shell")
	assert_bool(prompt.visible).is_false()
	assert_int(_count(beach.get_node("%World"), "/rock.tscn")).is_equal(BeachLayout.rocks().size())

func test_crack_at_boulder_uses_one_of_several() -> void:
	inventory.add(K.COCONUT, 3)
	await _stand(B + Vector2(-18, 0), Walk.Facing.RIGHT)
	assert_bool(prompt.visible).is_true()
	assert_str(prompt.verb_label.text).is_equal("Crack")
	assert_vector(prompt.global_position).is_equal(B + Vector2(0, -30))
	await _press_e()
	assert_int(inventory.count(K.COCONUT)).is_equal(2)
	assert_int(inventory.count(K.EMPTY_SHELL)).is_equal(1)
	assert_bool(prompt.visible).is_true()

func test_spring_without_shell_shows_nothing() -> void:
	inventory.add(K.COCONUT)
	await _stand(W + Vector2(0, 8), Walk.Facing.UP)
	assert_bool(prompt.visible).is_false()
	await _press_e()
	assert_int(inventory.count(K.FRESH_WATER)).is_equal(0)
	assert_int(inventory.count(K.COCONUT)).is_equal(1)

func test_fill_turns_shell_into_fresh_water() -> void:
	inventory.add(K.EMPTY_SHELL, 2)
	await _stand(W + Vector2(0, 8), Walk.Facing.UP)
	assert_bool(prompt.visible).is_true()
	assert_str(prompt.verb_label.text).is_equal("Fill")
	assert_vector(prompt.global_position).is_equal(W + Vector2(0, -16))
	await _press_e()
	assert_int(inventory.count(K.EMPTY_SHELL)).is_equal(1)
	assert_int(inventory.count(K.FRESH_WATER)).is_equal(1)
	assert_str(_rising()).is_equal("+1 Fresh water")

func test_spring_rim_blocks_walking() -> void:
	player.global_position = W + Vector2(0, 16)
	camera.snap_to_target()
	runner.simulate_action_press("move_up")
	await await_millis(800)
	runner.simulate_action_release("move_up")
	assert_float(player.global_position.y).is_equal_approx(W.y + 6, 0.5)

func test_new_game_palms_full_spring_placed() -> void:
	var world := beach.get_node("%World")
	for n in world.get_children():
		if n.scene_file_path.ends_with("palm.tscn"):
			assert_bool((n.get_node("Shake") as Shake).can_use(inventory)).is_true()
			assert_bool((n.get_node("Crown") as Node2D).visible).is_true()
	assert_int(_count(beach.get_node("%Decor"), "coconut.tscn")).is_equal(0)
	assert_int(_count(world, "spring.tscn")).is_equal(1)

func _shake_palm() -> void:
	await _stand(P + Vector2(-10, 0), Walk.Facing.RIGHT)
	await _press_e()

func test_shake_palm_drops_coconuts_and_palm_goes_bare() -> void:
	await _stand(P + Vector2(-10, 0), Walk.Facing.RIGHT)
	assert_bool(prompt.visible).is_true()
	assert_str(prompt.verb_label.text).is_equal("Shake")
	assert_vector(prompt.global_position).is_equal(P + Vector2(0, -48))
	await _press_e()
	assert_int(_count(beach.get_node("%Decor"), "coconut.tscn")).is_equal(2)
	assert_bool(_all_empty()).is_true()
	assert_str(_rising()).is_equal("")

func test_bare_palm_shows_nothing() -> void:
	await _shake_palm()
	for c in beach.get_node("%Decor").get_children():
		if c.scene_file_path.ends_with("coconut.tscn"):
			c.free()
	await await_millis(50)
	await _stand(P + Vector2(-10, 0), Walk.Facing.RIGHT)
	assert_bool(prompt.visible).is_false()
	await _press_e()
	assert_int(_count(beach.get_node("%Decor"), "coconut.tscn")).is_equal(0)
	assert_bool(_all_empty()).is_true()

func test_take_fallen_coconut() -> void:
	await _shake_palm()
	await _stand(P + Shake.DROPS[0] + Vector2(-10, -2), Walk.Facing.RIGHT)
	assert_bool(prompt.visible).is_true()
	assert_str(prompt.verb_label.text).is_equal("Take")
	await _press_e()
	assert_int(inventory.count(K.COCONUT)).is_equal(1)
	assert_str(_rising()).is_equal("+1 Coconut")
	assert_int(_count(beach.get_node("%Decor"), "coconut.tscn")).is_equal(1)

func test_leaning_palm_drops_under_its_crown() -> void:
	var L := BeachLayout.cell_base(BeachLayout.palms()[5])
	await _stand(L + Vector2(-10, 0), Walk.Facing.RIGHT)
	await _press_e()
	var drops := beach.get_node("%Decor").get_children().filter(func(n: Node) -> bool:
		return n.scene_file_path.ends_with("coconut.tscn"))
	assert_int(drops.size()).is_equal(2)
	for j in drops.size():
		assert_vector((drops[j] as Node2D).global_position).is_equal(L + Shake.DROPS[j] + Vector2(-35, 0))
