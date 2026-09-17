extends GdUnitTestSuite

const SCENE := "res://src/beach/beach.tscn"

var runner: GdUnitSceneRunner
var beach: Node
var player: Player
var camera: LooseCamera

func before_test() -> void:
	runner = scene_runner(SCENE)
	beach = runner.scene()
	player = beach.get_node("%Player") as Player
	camera = beach.get_node("%Camera") as LooseCamera

func _place(cell: Vector2i) -> void:
	player.global_position = BeachLayout.cell_centre(cell)
	camera.snap_to_target()

func _animation() -> StringName:
	return (player.get_node("%Sprite") as AnimatedSprite2D).animation

func _from(parent: Node, suffix: String) -> Array[Node]:
	return parent.get_children().filter(func(n: Node) -> bool: return n.scene_file_path.ends_with(suffix))

func _count(parent: Node, suffix: String) -> int:
	return _from(parent, suffix).size()

func test_wakes_in_the_middle_facing_down_still() -> void:
	assert_vector(player.global_position).is_equal(Vector2(1480, 184))
	assert_int(player.facing).is_equal(Walk.Facing.DOWN)
	assert_that(_animation()).is_equal(&"still_down")
	assert_vector(camera.global_position).is_equal(Vector2(1480, 184))

func test_ground_matches_layout() -> void:
	var ground := beach.get_node("%Ground") as TileMapLayer
	for y in BeachLayout.MAP_SIZE.y:
		for x in BeachLayout.MAP_SIZE.x:
			var cell := Vector2i(x, y)
			if ground.get_cell_atlas_coords(cell) != Vector2i(BeachLayout.kind_at(cell), 0):
				fail("ground at %s is %s" % [cell, ground.get_cell_atlas_coords(cell)])
				return

func test_props_are_placed() -> void:
	var world := beach.get_node("%World")
	assert_int(_count(world, "palm.tscn")).is_equal(BeachLayout.PALMS.size())
	assert_int(_count(world, "rock.tscn")).is_equal(BeachLayout.ROCKS.size())
	assert_int(_count(world, "boulder.tscn")).is_equal(BeachLayout.BOULDERS.size())
	assert_int(_count(world, "spring.tscn")).is_equal(BeachLayout.SPRINGS.size())
	assert_int(_count(beach.get_node("%Decor"), "driftwood.tscn")).is_equal(BeachLayout.DRIFTWOOD.size())
	var base := BeachLayout.cell_base(BeachLayout.PALMS[0])
	assert_bool(world.get_children().any(func(n: Node) -> bool:
		return n.scene_file_path.ends_with("palm.tscn") and (n as Node2D).position == base)).is_true()

func test_vegetation_is_placed() -> void:
	var decor := beach.get_node("%Decor")
	assert_int(_count(decor, "bush.tscn")).is_equal(BeachLayout.BUSHES.size())
	assert_int(_count(decor, "tuft.tscn")).is_equal(BeachLayout.TUFTS.size())
	var at := BeachLayout.cell_base(BeachLayout.BUSHES[0])
	assert_bool(_from(decor, "bush.tscn").any(func(n: Node) -> bool: return (n as Node2D).position == at)).is_true()

func test_tall_things_sort_with_him() -> void:
	var world := beach.get_node("%World") as Node2D
	assert_bool(world.y_sort_enabled).is_true()
	assert_object(player.get_parent()).is_same(world)
	for n in world.get_children():
		if n.scene_file_path.ends_with("palm.tscn"):
			assert_float((n.get_node("Sprite") as Sprite2D).offset.y).is_equal(-24.0)
		elif n.scene_file_path.ends_with("boulder.tscn"):
			assert_float((n.get_node("Sprite") as Sprite2D).offset.y).is_equal(-16.0)

func test_no_words_on_arrival() -> void:
	await await_millis(50)
	for label: Label in beach.find_children("*", "Label", true, false):
		if label.is_visible_in_tree():
			assert_str(label.text).override_failure_message("%s shows words" % label.get_path()).is_empty()
	assert_array(beach.find_children("*", "RichTextLabel", true, false)).is_empty()

func test_walks_right_at_walking_pace() -> void:
	runner.simulate_action_press("move_right")
	await await_millis(300)
	assert_vector(player.velocity).is_equal_approx(Vector2(48, 0), Vector2(0.01, 0.01))
	assert_float(player.global_position.x).is_greater(1480.0)
	assert_int(player.facing).is_equal(Walk.Facing.RIGHT)
	assert_that(_animation()).is_equal(&"walk_right")
	runner.simulate_action_release("move_right")

func test_keys_and_arrows_both_walk() -> void:
	runner.simulate_key_press(KEY_A)
	await await_millis(200)
	assert_float(player.velocity.x).is_less(0.0)
	runner.simulate_key_release(KEY_A)
	runner.simulate_key_press(KEY_UP)
	await await_millis(200)
	assert_float(player.velocity.y).is_less(0.0)
	assert_float(player.velocity.x).is_equal(0.0)
	runner.simulate_key_release(KEY_UP)

func test_diagonal_no_faster_and_faces_sideways() -> void:
	runner.simulate_action_press("move_up")
	runner.simulate_action_press("move_left")
	await await_millis(300)
	assert_float(player.velocity.length()).is_equal_approx(48.0, 0.01)
	assert_int(player.facing).is_equal(Walk.Facing.LEFT)
	runner.simulate_action_release("move_up")
	runner.simulate_action_release("move_left")

func test_opposite_keys_cancel() -> void:
	runner.simulate_action_press("move_left")
	runner.simulate_action_press("move_right")
	await await_millis(300)
	assert_vector(player.global_position).is_equal(Vector2(1480, 184))
	assert_that(_animation()).is_equal(&"still_down")
	runner.simulate_action_release("move_left")
	runner.simulate_action_release("move_right")

func test_stops_facing_last_way() -> void:
	runner.simulate_action_press("move_up")
	await await_millis(200)
	runner.simulate_action_release("move_up")
	await await_millis(200)
	assert_that(_animation()).is_equal(&"still_up")

func test_jungle_edge_stops_straight_walk() -> void:
	_place(Vector2i(92, 9))
	runner.simulate_action_press("move_up")
	await await_millis(600)
	assert_float(player.global_position.y).is_equal_approx(150.0, 0.5)
	assert_float(player.global_position.x).is_equal(1480.0)
	assert_that(_animation()).is_equal(&"still_up")
	runner.simulate_action_release("move_up")

func test_diagonal_into_jungle_slides() -> void:
	_place(Vector2i(92, 9))
	runner.simulate_action_press("move_up")
	runner.simulate_action_press("move_right")
	await await_millis(600)
	assert_float(player.global_position.y).is_equal_approx(150.0, 0.5)
	assert_float(player.global_position.x).is_greater_equal(1488.0)
	assert_that(_animation()).is_equal(&"walk_right")
	runner.simulate_action_release("move_up")
	runner.simulate_action_release("move_right")

func test_deep_water_blocks() -> void:
	_place(Vector2i(92, 17))
	runner.simulate_action_press("move_down")
	await await_millis(600)
	assert_float(player.global_position.y).is_less_equal(288.5)
	runner.simulate_action_release("move_down")

func test_headland_blocks() -> void:
	_place(Vector2i(17, 12))
	runner.simulate_action_press("move_left")
	await await_millis(800)
	assert_float(player.global_position.x).is_equal_approx(261.0, 0.5)
	runner.simulate_action_release("move_left")

func test_palm_trunk_blocks() -> void:
	_place(Vector2i(47, 11))
	runner.simulate_action_press("move_up")
	await await_millis(800)
	assert_float(player.global_position.y).is_equal_approx(166.0, 0.5)
	runner.simulate_action_release("move_up")
	await await_millis(50)
	player.global_position = Vector2(760, 152)
	camera.snap_to_target()
	await await_millis(100)
	assert_vector(player.global_position).is_equal(Vector2(760, 152))

func test_camera_follows_loosely_on_whole_pixels() -> void:
	runner.simulate_action_press("move_right")
	await await_millis(1500)
	assert_float(player.global_position.x - camera.global_position.x).is_between(24.0, 48.0)
	assert_vector(camera.global_position).is_equal(camera.global_position.round())
	runner.simulate_action_release("move_right")
	await await_millis(1500)
	var settled := camera.global_position
	await await_millis(300)
	assert_vector(camera.global_position).is_equal(settled)
	assert_float(player.global_position.x - camera.global_position.x).is_between(23.0, 25.0)

func test_focus_loss_stops_him() -> void:
	runner.simulate_key_press(KEY_D)
	await runner.await_input_processed()
	await await_millis(200)
	player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await await_millis(200)
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()
	assert_vector(player.velocity).is_equal(Vector2.ZERO)
	assert_that(_animation()).is_equal(&"still_right")

func test_escape_does_nothing() -> void:
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.await_input_processed()
	await await_millis(100)
	assert_bool(is_instance_valid(beach) and beach.is_inside_tree()).is_true()
	assert_bool(beach.get_tree().paused).is_false()
	assert_vector(player.global_position).is_equal(Vector2(1480, 184))

func _sprite() -> AnimatedSprite2D:
	return player.get_node("%Sprite") as AnimatedSprite2D

func _marks(suffix: String) -> Array[Node]:
	return _from(beach.get_node("%Decor"), suffix)

func test_shift_runs_at_double_pace_with_puffs() -> void:
	_place(Vector2i(92, 12))
	runner.simulate_action_press("run")
	runner.simulate_action_press("move_right")
	await await_millis(300)
	assert_vector(player.velocity).is_equal_approx(Vector2(96, 0), Vector2(0.01, 0.01))
	assert_that(_animation()).is_equal(&"run_right")
	assert_float(_sprite().speed_scale).is_equal(1.0)
	var puffs := _marks("puff.tscn")
	assert_array(puffs).is_not_empty()
	for puff: Node2D in puffs:
		assert_float(puff.position.y).is_equal(200.0)
		assert_float(puff.position.x).is_less(player.global_position.x)
	runner.simulate_action_release("run")
	runner.simulate_action_release("move_right")

func test_letting_go_of_shift_walks() -> void:
	_place(Vector2i(92, 12))
	runner.simulate_action_press("run")
	runner.simulate_action_press("move_right")
	await await_millis(300)
	var x0 := player.global_position.x
	var before := _marks("puff.tscn")
	assert_array(before).is_not_empty()
	runner.simulate_action_release("run")
	await await_millis(300)
	assert_vector(player.velocity).is_equal_approx(Vector2(48, 0), Vector2(0.01, 0.01))
	assert_float(_sprite().speed_scale).is_equal(1.0)
	for puff: Node2D in _marks("puff.tscn"):
		assert_bool(before.has(puff)).override_failure_message("a puff appeared after letting go").is_true()
		assert_float(puff.position.x).is_less(x0)
	runner.simulate_action_release("move_right")

func test_walking_leaves_no_puffs() -> void:
	_place(Vector2i(92, 12))
	runner.simulate_action_press("move_right")
	await await_millis(400)
	assert_array(_marks("puff.tscn")).is_empty()
	runner.simulate_action_release("move_right")

func test_wades_at_half_pace_legs_hidden_with_ripples() -> void:
	_place(Vector2i(92, 16))
	runner.simulate_action_press("move_right")
	await await_millis(400)
	assert_vector(player.velocity).is_equal_approx(Vector2(24, 0), Vector2(0.01, 0.01))
	assert_bool(player.wading).is_true()
	assert_that(_animation()).is_equal(&"wade_walk_right")
	assert_float(_sprite().speed_scale).is_equal(0.5)
	assert_array(_marks("ripple.tscn")).is_not_empty()
	runner.simulate_action_release("move_right")

func test_shift_does_not_speed_wading() -> void:
	_place(Vector2i(92, 16))
	runner.simulate_action_press("run")
	runner.simulate_action_press("move_right")
	await await_millis(400)
	assert_vector(player.velocity).is_equal_approx(Vector2(24, 0), Vector2(0.01, 0.01))
	assert_array(_marks("puff.tscn")).is_empty()
	runner.simulate_action_release("run")
	runner.simulate_action_release("move_right")

func test_standing_in_water_hides_legs_without_ripples() -> void:
	_place(Vector2i(92, 17))
	await await_millis(400)
	assert_that(_animation()).is_equal(&"wade_still_down")
	assert_array(_marks("ripple.tscn")).is_empty()

func test_foam_is_dry() -> void:
	_place(Vector2i(92, 15))
	runner.simulate_action_press("move_left")
	await await_millis(300)
	assert_vector(player.velocity).is_equal_approx(Vector2(-48, 0), Vector2(0.01, 0.01))
	assert_bool(player.wading).is_false()
	assert_that(_animation()).is_equal(&"walk_left")
	runner.simulate_action_release("move_left")

func test_walking_out_of_the_water_shows_legs() -> void:
	_place(Vector2i(92, 16))
	runner.simulate_action_press("move_up")
	await await_millis(800)
	assert_float(player.global_position.y).is_less(256.0)
	assert_that(_animation()).is_equal(&"walk_up")
	runner.simulate_action_release("move_up")

func test_focus_loss_releases_shift() -> void:
	runner.simulate_action_press("run")
	runner.simulate_action_press("move_right")
	await await_millis(200)
	player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await await_millis(100)
	assert_bool(Input.is_action_pressed(&"run")).is_false()
