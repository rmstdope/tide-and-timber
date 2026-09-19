extends GdUnitTestSuite
## Waking from a save: no story, where he stood with his things, the saved dawn, a fade up.

var runner: GdUnitSceneRunner
var game: Waking
var player: Player

func _sample() -> SaveData:
	var d := SaveData.new()
	var slots: Array[Dictionary] = [{"kind": Item.Kind.DRIFTWOOD, "count": 3}, {}, {}, {}, {}, {}, {}, {}]
	d.inventory_slots = slots
	var first: Array[Vector2i] = [BeachLayout.driftwood()[0]]
	var none: Array[Vector2i] = []
	d.taken = {"driftwood": first, "shellfish": none}
	d.player_position = Vector2(400, 200)
	d.player_facing = Walk.Facing.LEFT
	d.clock_minutes = 4680.0
	return d

func before_test() -> void:
	Pause.debug_tools = false   # the release board; tests/debug covers the debug one
	InputDevice.reset()
	game = auto_free(load("res://src/waking/waking.tscn").instantiate()) as Waking
	game.resume_data = _sample()
	runner = scene_runner(game)
	game.set_process(false)
	_node("DayNight").set_process(false)
	_node("Autosave").set_process(false)
	player = game.player

func after_test() -> void:
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false

func _node(unique: String) -> Node:
	return game.get_node("%" + unique)

func test_he_is_where_he_stood_with_his_things() -> void:
	var beach := _node("Beach") as Beach
	assert_vector(player.global_position).is_equal(Vector2(400, 200))
	assert_int(player.facing).is_equal(Walk.Facing.LEFT)
	assert_bool(player.control_enabled).is_true()
	assert_int(beach.inventory.slot_kind(0)).is_equal(Item.Kind.DRIFTWOOD)
	assert_int(beach.inventory.slot_count(0)).is_equal(3)
	await await_idle_frame()
	var driftwood := beach.get_node("%Decor").get_children().filter(func(n: Node) -> bool:
		return n.scene_file_path == Beach.DRIFTWOOD.resource_path and not n.is_queued_for_deletion())
	assert_int(driftwood.size()).is_equal(BeachLayout.driftwood().size() - 1)

func test_the_clock_is_the_saved_dawn() -> void:
	var day_night := _node("DayNight") as DayNight
	assert_bool(day_night.running).is_true()
	assert_str((day_night.get_node("%DayLabel") as Label).text).is_equal("DAY 4")
	assert_str((day_night.get_node("%TimeLabel") as Label).text).is_equal("06:00")

func test_fades_up_with_nothing_said() -> void:
	assert_float(_node("Cover").modulate.a).is_equal(1.0)
	assert_bool(_node("MoveHint").visible).is_false()
	game.tick(0.5)
	assert_float(_node("Cover").modulate.a).is_equal_approx(0.5, 0.001)
	game.tick(0.6)
	assert_float(_node("Cover").modulate.a).is_equal_approx(0.0, 0.001)
	assert_bool(_node("MoveHint").visible).is_false()
	assert_that((player.get_node("%Sprite") as AnimatedSprite2D).animation).is_equal(&"still_down")
	var decor := _node("Beach").get_node("%Decor")
	assert_int(decor.get_children().filter(func(n: Node) -> bool: return n is WaveWash).size()).is_equal(0)

func test_no_dawn_on_arriving() -> void:
	var dawns: Array[int] = [0]
	var day_night := _node("DayNight") as DayNight
	day_night.dawn.connect(func() -> void: dawns[0] += 1)
	day_night.tick(1.0)
	assert_int(dawns[0]).is_equal(0)
	assert_bool((_node("Autosave").get_node("%Dawn") as CanvasItem).visible).is_false()

func test_autosave_watches_after_continue() -> void:
	assert_bool((_node("DayNight") as DayNight).dawn.is_connected((_node("Autosave") as Autosave).on_dawn)).is_true()

func test_esc_pauses_after_continue_and_quit_warns_about_this_morning() -> void:
	var pause := _node("Pause") as Pause
	assert_bool(pause.try_open()).is_false()   # still fading up
	game.tick(1.1)
	for key: Key in [KEY_ESCAPE, KEY_UP, KEY_ENTER]:
		await runner.simulate_key_pressed(key)
		await runner.await_input_processed()
	assert_bool(get_tree().paused).is_true()
	assert_bool((pause.get_node("%QuitBox") as Control).visible).is_true()
	assert_str((pause.get_node("%SecondLine") as Label).text).is_equal("Anything since this morning will be lost.")


func test_no_camp_in_the_save_no_camp_on_the_beach() -> void:
	var b := _node("Beach").get_node("%Builder") as Builder
	assert_object(b.lean_to).is_null()
	assert_object(b.fire).is_null()

func test_the_camp_comes_back_lit_and_goes_out_at_0700() -> void:
	var data := _sample()
	data.lean_to_cells = BuildSite.cells_for(BuildMenu.Thing.LEAN_TO, Vector2i(92, 11), Walk.Facing.DOWN)
	data.has_fire = true
	data.fire_cell = Vector2i(92, 14)
	data.fire_lit = true
	data.fire_out_at = 4680.0 + 60.0
	data.clock_minutes = 4680.0
	var g := auto_free(load("res://src/waking/waking.tscn").instantiate()) as Waking
	g.resume_data = data
	scene_runner(g)
	g.set_process(false)
	var d := g.get_node("%DayNight") as DayNight
	d.set_process(false)
	g.get_node("%Autosave").set_process(false)
	var b := g.get_node("%Beach").get_node("%Builder") as Builder
	assert_array(b.lean_to.cells).is_equal(data.lean_to_cells)
	assert_vector(b.fire.cell).is_equal(Vector2i(92, 14))
	assert_bool(b.fire.lit).is_true()
	assert_bool(b.fire.glow.visible).is_true()
	assert_float(d.clock.total_minutes).is_equal(4680.0)
	d.clock.total_minutes = 4739.0
	b.tick(0.0)
	assert_bool(b.fire.lit).is_true()
	d.clock.total_minutes = 4740.0
	b.tick(0.0)
	assert_bool(b.fire.lit).is_false()

## The fall came from a run-time call inside the new-game branch, so a loaded game had no animation
## to collapse with. It is built for every game now, and this is what holds that.
func test_a_loaded_game_can_still_fall() -> void:
	var sprite := player.get_node("%Sprite") as AnimatedSprite2D
	assert_bool(sprite.sprite_frames.has_animation(&"death_down")).is_true()
