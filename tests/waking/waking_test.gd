extends GdUnitTestSuite
## The waking scene: black, face-down at the waterline, up by himself, then control, clock and hint.

var runner: GdUnitSceneRunner
var waking: Waking
var player: Player

func before_test() -> void:
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	player = waking.player

func _node(unique: String) -> Node:
	return waking.get_node("%" + unique)

func _animation() -> StringName:
	return (player.get_node("%Sprite") as AnimatedSprite2D).animation

func test_opens_black_with_him_face_down_at_the_waterline() -> void:
	assert_float(_node("Cover").modulate.a).is_greater(0.8)
	assert_vector(player.global_position).is_equal(Vector2(1480, 232))
	assert_int(BeachLayout.kind_at(Waking.WAKE_CELL)).is_equal(BeachLayout.Kind.WET_SAND)
	assert_that(_animation()).is_equal(&"lie")
	assert_bool(player.control_enabled).is_false()
	assert_vector((_node("Beach").get_node("%Camera") as Node2D).global_position).is_equal(Vector2(1480, 232))
	assert_bool(_node("MoveHint").visible).is_false()
	assert_bool(_node("DayNight").running).is_false()
	assert_bool(_node("DayNight").get_node("%Hud").visible).is_false()

func test_keys_do_nothing_while_he_wakes() -> void:
	runner.simulate_key_press(KEY_D)
	await await_millis(300)
	runner.simulate_key_release(KEY_D)
	await runner.await_input_processed()
	assert_vector(player.global_position).is_equal(Vector2(1480, 232))

func test_gets_himself_up_then_control_and_clock() -> void:
	waking.tick(1.2)
	assert_float(_node("Cover").modulate.a).is_equal_approx(0.0, 0.001)
	assert_that(_animation()).is_equal(&"lie")
	waking.tick(2.0)
	assert_that(_animation()).is_equal(&"push_up")
	waking.tick(0.4)
	assert_that(_animation()).is_equal(&"sit")
	assert_bool(player.control_enabled).is_false()
	waking.tick(0.8)
	assert_bool(player.control_enabled).is_true()
	assert_that(_animation()).is_equal(&"still_down")
	assert_bool(_node("MoveHint").visible).is_true()
	assert_str((_node("MoveHint").get_node("Label") as Label).text).is_equal("WASD or arrows · Move")
	assert_bool(_node("DayNight").running).is_true()
	assert_bool(_node("DayNight").get_node("%Hud").visible).is_true()

func test_a_key_held_through_the_waking_does_not_walk_him() -> void:
	runner.simulate_key_press(KEY_D)
	await runner.await_input_processed()
	waking.tick(5.0)
	await await_millis(300)
	runner.simulate_key_release(KEY_D)
	await runner.await_input_processed()
	assert_vector(player.global_position).is_equal(Vector2(1480, 232))
	assert_vector(player.velocity).is_equal(Vector2.ZERO)

func test_hint_stays_while_he_stands() -> void:
	waking.tick(5.0)
	waking.tick(30.0)
	assert_bool(_node("MoveHint").visible).is_true()
	assert_float(_node("MoveHint").modulate.a).is_equal_approx(1.0, 0.001)

func test_hint_fades_after_a_few_steps_and_stays_gone() -> void:
	waking.tick(5.0)
	runner.simulate_action_press("move_right")
	await await_millis(1000)
	runner.simulate_action_release("move_right")
	await runner.await_input_processed()
	waking.tick(0.01)
	assert_float(waking.wake.walked).is_greater_equal(32.0)
	waking.tick(0.25)
	assert_float(_node("MoveHint").modulate.a).is_equal_approx(0.5, 0.05)
	waking.tick(0.3)
	assert_bool(_node("MoveHint").visible).is_false()
	runner.simulate_action_press("move_right")
	await await_millis(500)
	runner.simulate_action_release("move_right")
	await runner.await_input_processed()
	waking.tick(0.1)
	assert_bool(_node("MoveHint").visible).is_false()

func test_wash_is_under_him() -> void:
	var decor := _node("Beach").get_node("%Decor")
	assert_int(decor.get_children().filter(func(n: Node) -> bool: return n is WaveWash).size()).is_equal(1)
	assert_object(player.get_parent()).is_same(_node("Beach").get_node("%World"))

func test_waves_are_heard_on_the_beach() -> void:
	assert_bool((_node("Surf") as SurfSound).audible).is_true()
	waking.tick(1.0)
	assert_float((_node("Surf") as AudioStreamPlayer).volume_linear).is_equal_approx(0.6, 0.001)
