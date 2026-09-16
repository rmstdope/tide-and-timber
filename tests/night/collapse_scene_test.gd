extends "res://tests/night/night_scene_base.gd"
## The collapse and the morning after, on the beach with the clock.

const K := Item.Kind

func _collapse_now() -> void:
	_out_of_light()
	_at(1300.0)
	night.tick(0.0)
	night.tick(4.5)
	night.tick(0.5)

func _card_texts() -> Array[String]:
	var out: Array[String] = []
	for l in (_n("Card") as MorningCardView).labels:
		out.append(l.text)
	return out

func test_collapse_takes_control_and_falls() -> void:
	_collapse_now()
	assert_object(night.collapse).is_not_null()
	assert_bool(player.control_enabled).is_false()
	assert_bool(_n("CollapseCover").visible).is_false()
	night.tick(1.5)
	assert_that((player.get_node("%Sprite") as AnimatedSprite2D).animation).is_equal(&"lie")

func test_input_ignored_during_collapse() -> void:
	_collapse_now()
	var p := player.global_position
	runner.simulate_key_press(KEY_D)
	await await_millis(200)
	runner.simulate_key_release(KEY_D)
	await runner.await_input_processed()
	assert_vector(player.global_position).is_equal(p)
	runner.simulate_key_pressed(KEY_B)
	await runner.await_input_processed()
	assert_int(builder.mode).is_equal(Builder.Mode.CLOSED)
	assert_bool(beach.get_node("%BuildList").visible).is_false()
	runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.await_input_processed()
	assert_int(builder.mode).is_equal(Builder.Mode.CLOSED)
	assert_vector(player.global_position).is_equal(p)
	assert_object(night.collapse).is_not_null()

func test_black_line_then_morning_at_0600_next_day_half_lost() -> void:
	inventory.add(K.DRIFTWOOD, 9)
	inventory.add(K.SHELLFISH, 3)
	inventory.add(K.COCONUT, 1)
	await await_idle_frame()   # each add replaces the last "+n" RisingLine, freed only at frame end
	_collapse_now()
	night.tick(2.0)
	night.tick(0.5)
	assert_float(_n("CollapseCover").modulate.a).is_equal(1.0)
	assert_int(inventory.count(K.DRIFTWOOD)).is_equal(5)
	assert_int(inventory.count(K.SHELLFISH)).is_equal(2)
	assert_int(inventory.count(K.COCONUT)).is_equal(1)
	assert_float(dn.clock.total_minutes).is_equal(1800.0)
	assert_int(dn.clock.day()).is_equal(2)
	assert_bool(_n("Frost").visible).is_false()
	night.tick(1.5)
	assert_bool(_n("BlackLine").visible).is_true()
	assert_str((_n("BlackLine") as Label).text).is_equal("So cold... just... rest a moment...")
	night.tick(1.5)
	assert_bool(_n("Card").visible).is_true()
	assert_array(_card_texts()).is_equal(["DAY 2", "The night took:", "4 Driftwood", "1 Shellfish"])
	night.tick(2.2)
	assert_object(night.collapse).is_null()
	assert_bool(player.control_enabled).is_true()
	night.tick(1.0)
	assert_bool(_n("Card").visible).is_true()
	night.tick(1.0)
	assert_bool(_n("Card").visible).is_false()

func test_collapse_after_midnight_wakes_same_calendar_day() -> void:
	_out_of_light()
	_at(1440.0 + 120.0)
	night.tick(0.0)
	night.tick(4.5)
	night.tick(0.5)
	night.tick(2.5)
	assert_float(dn.clock.total_minutes).is_equal(1800.0)

func test_wakes_where_he_first_woke_without_lean_to() -> void:
	_collapse_now()
	night.tick(2.5)
	assert_vector(player.global_position).is_equal(Vector2(1480, 232))

func test_wakes_beside_the_lean_to() -> void:
	_lean_to()
	_collapse_now()
	night.tick(2.5)
	assert_vector(player.global_position).is_equal(BeachLayout.cell_centre(Vector2i(91, 14)))
	assert_vector(player.global_position).is_equal(Vector2(1464, 232))

func test_nothing_lost_card() -> void:
	_collapse_now()
	night.tick(2.5)
	night.tick(3.0)
	assert_array(_card_texts()).is_equal(["DAY 2", "I made it through."])

func test_collapse_abandons_placing_with_nothing_spent() -> void:
	inventory.add(K.DRIFTWOOD, 9)
	builder.open_list()
	builder.choose(BuildMenu.Thing.LEAN_TO)
	assert_int(builder.mode).is_equal(Builder.Mode.PLACING)
	_collapse_now()
	assert_int(builder.mode).is_equal(Builder.Mode.CLOSED)
	assert_bool(beach.get_node("%Ghost").visible).is_false()
	assert_int(inventory.count(K.DRIFTWOOD)).is_equal(9)
	night.tick(2.5)
	assert_int(inventory.count(K.DRIFTWOOD)).is_equal(5)

func test_built_things_stay_and_fire_keeps_its_rules() -> void:
	_lean_to()
	_fire()
	builder.fire.out_at = 1860.0
	player.global_position = Vector2(1300, 232)
	_at(1300.0)
	night.tick(0.0)
	night.tick(4.5)
	night.tick(0.5)
	night.tick(2.5)
	assert_object(builder.lean_to).is_not_null()
	assert_bool(builder.fire.lit).is_true()

func test_can_collapse_again_next_night() -> void:
	_collapse_now()
	night.tick(100.0)
	assert_object(night.collapse).is_null()
	_out_of_light()
	_at(2700.0)
	night.tick(0.0)
	night.tick(4.5)
	night.tick(0.5)
	assert_object(night.collapse).is_not_null()

func test_interactor_frozen_while_down_and_back_after() -> void:
	_collapse_now()
	assert_int(beach.get_node("%Interactor").process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	night.tick(100.0)
	assert_int(beach.get_node("%Interactor").process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
