extends GdUnitTestSuite
## Gathering anything plays the one-shot crouch, wherever the use came from, and walking cuts it short.

const SCENE := "res://src/beach/beach.tscn"

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var camera: LooseCamera
var walker: ClickWalker

func before_test() -> void:
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	camera = beach.get_node("%Camera") as LooseCamera
	walker = beach.get_node("%ClickWalker") as ClickWalker

func _sprite() -> AnimatedSprite2D:
	return player.get_node("%Sprite") as AnimatedSprite2D

func _driftwood() -> Vector2:
	return BeachLayout.cell_base(BeachLayout.DRIFTWOOD[2])

func _stand(at: Vector2, facing: Walk.Facing) -> void:
	player.global_position = at
	player.facing = facing
	camera.snap_to_target()
	await await_millis(50)

func _press_e() -> void:
	runner.simulate_key_pressed(KEY_E)
	await runner.await_input_processed()
	await await_millis(50)

## Stands him just left of the driftwood, facing it, and presses E.
func _gather() -> void:
	await _stand(_driftwood() + Vector2(-10, 0), Walk.Facing.RIGHT)
	await _press_e()

func test_using_something_plays_the_gathering_move() -> void:
	await _gather()
	assert_bool(player.collecting).override_failure_message("he is not gathering").is_true()
	assert_that(_sprite().animation).is_equal(Walk.collect_animation_for(player.facing))

func test_the_gathering_move_ends_by_itself() -> void:
	await _gather()
	await await_millis(900)
	assert_bool(player.collecting).is_false()
	assert_that(_sprite().animation).is_equal(Walk.animation_for(player.facing, false))

func test_walking_cuts_the_gathering_move_short() -> void:
	await _gather()
	runner.simulate_action_press("move_left")
	await await_millis(200)
	runner.simulate_action_release("move_left")
	assert_that(_sprite().animation).is_equal(&"walk_left")
	assert_bool(player.collecting).is_false()

func test_a_click_walk_that_arrives_gathers() -> void:
	await _stand(_driftwood() + Vector2(-60, 0), Walk.Facing.RIGHT)
	walker.click_at(_driftwood())
	await assert_signal(walker).is_emitted("arrived")
	await await_millis(50)
	assert_str(String(_sprite().animation)).starts_with("collect_")

func test_give_control_drops_the_gathering_move() -> void:
	await _gather()
	assert_bool(player.collecting).is_true()
	player.give_control()
	assert_bool(player.collecting).is_false()

func test_he_gathers_in_the_shallows_with_his_legs_hidden() -> void:
	await _stand(_driftwood() + Vector2(-10, 0), Walk.Facing.RIGHT)
	player.wading = true
	player.collect()
	await await_millis(50)
	assert_bool(player.collecting).is_true()
	assert_that(_sprite().animation).is_equal(&"wade_collect_right")
	var cut := _sprite().sprite_frames.get_frame_texture(&"wade_collect_right", 0) as AtlasTexture
	assert_that(cut.region.size).is_equal(Vector2(64, 44))

func test_the_gathering_move_is_ignored_while_control_is_off() -> void:
	await _stand(_driftwood() + Vector2(-10, 0), Walk.Facing.RIGHT)
	player.control_enabled = false
	# Stands in for a collapse or the waking, which drive the sprite themselves while control is off.
	player.play_pose(&"still_up")
	player.collect()
	assert_bool(player.collecting).override_failure_message("a pose he cannot control was cut short").is_false()
	assert_that(_sprite().animation).is_equal(&"still_up")
