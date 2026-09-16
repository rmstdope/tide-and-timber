extends GdUnitTestSuite
## Holding the man still while he wakes, and handing him to the player.

var runner: GdUnitSceneRunner
var player: Player

func before_test() -> void:
	runner = scene_runner("res://src/beach/beach.tscn")
	player = runner.scene().get_node("%Player") as Player

func _animation() -> StringName:
	return (player.get_node("%Sprite") as AnimatedSprite2D).animation

func test_without_control_keys_do_nothing() -> void:
	player.control_enabled = false
	runner.simulate_action_press("move_right")
	await await_millis(300)
	runner.simulate_action_release("move_right")
	assert_vector(player.global_position).is_equal(Vector2(1480, 184))
	assert_vector(player.velocity).is_equal(Vector2.ZERO)

func test_without_control_the_pose_is_kept() -> void:
	player.control_enabled = false
	player.play_pose(&"still_up")
	await await_millis(200)
	assert_that(_animation()).is_equal(&"still_up")

func test_give_control_releases_held_keys_and_faces_down() -> void:
	player.control_enabled = false
	runner.simulate_key_press(KEY_D)
	await runner.await_input_processed()
	player.give_control()
	await await_millis(300)
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()
	assert_vector(player.global_position).is_equal(Vector2(1480, 184))
	assert_that(_animation()).is_equal(&"still_down")
	assert_bool(player.control_enabled).is_true()
	runner.simulate_key_release(KEY_D)
	runner.simulate_key_press(KEY_D)
	await await_millis(300)
	runner.simulate_key_release(KEY_D)
	await runner.await_input_processed()
	assert_float(player.global_position.x).is_greater(1480.0)
