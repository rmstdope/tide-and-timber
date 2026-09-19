extends GdUnitTestSuite
## The scenes the Story page starts: the intro, a new game's waking, and the three worlds loaded as Continue loads them.

const P := StoryPoints.Point

var runner: GdUnitSceneRunner
var game: Waking
var beach: Beach
var builder: Builder

func before_test() -> void:
	Pause.debug_tools = false

func after_test() -> void:
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false

func _load(point: StoryPoints.Point) -> void:
	game = auto_free(StoryPoints.scene_for(point)) as Waking
	runner = scene_runner(game)
	game.set_process(false)
	_node("DayNight").set_process(false)
	_node("Autosave").set_process(false)
	beach = _node("Beach") as Beach
	builder = beach.get_node("%Builder") as Builder

func _node(unique: String) -> Node:
	return game.get_node("%" + unique)

func _clock() -> GameClock:
	return (_node("DayNight") as DayNight).clock

func _driftwood_left() -> int:
	await runner.simulate_frames(1)
	return beach.get_node("%Decor").get_children().filter(func(n: Node) -> bool:
		return n.scene_file_path == Beach.DRIFTWOOD.resource_path and not n.is_queued_for_deletion()).size()

func _assert_camp() -> void:
	assert_object(builder.lean_to).is_not_null()
	assert_array(builder.lean_to.cells).is_equal(StoryPoints.CAMP_LEAN_TO)
	assert_object(builder.fire).is_not_null()
	assert_bool(builder.fire.lit).is_true()
	assert_that(builder.fire.cell).is_equal(StoryPoints.CAMP_FIRE)
	assert_float(builder.fire.out_at).is_equal(1860.0)
	assert_bool(builder.in_firelight(game.player.global_position)).is_true()
	assert_int(await _driftwood_left()).is_equal(BeachLayout.driftwood().size() - 12)
	assert_int(beach.inventory.count(Item.Kind.DRIFTWOOD)).is_equal(0)

func test_shipwreck_is_the_intro() -> void:
	var intro: Node = auto_free(StoryPoints.scene_for(P.SHIPWRECK))
	assert_bool(intro is Intro).is_true()
	assert_int((intro as Intro).story.panel).is_equal(0)

func test_waking_is_a_new_games_waking() -> void:
	_load(P.WAKING)
	assert_object(game.resume_data).is_null()
	assert_bool(game.player.control_enabled).is_false()
	assert_float(_clock().total_minutes).is_equal(780.0)
	for i in Inventory.SLOT_COUNT:
		assert_int(beach.inventory.slot_kind(i)).is_equal(Inventory.EMPTY)

func test_first_day_loads_with_his_gatherings() -> void:
	_load(P.FIRST_DAY)
	assert_float(_clock().total_minutes).is_equal(960.0)
	assert_int(beach.inventory.count(Item.Kind.DRIFTWOOD)).is_equal(6)
	assert_int(beach.inventory.count(Item.Kind.SHELLFISH)).is_equal(2)
	assert_int(beach.inventory.count(Item.Kind.COCONUT)).is_equal(1)
	assert_int(beach.inventory.count(Item.Kind.FRESH_WATER)).is_equal(1)
	assert_object(builder.lean_to).is_null()
	assert_vector(game.player.global_position).is_equal(BeachLayout.cell_centre(StoryPoints.CAMP_CELL))
	assert_bool(game.player.control_enabled).is_true()
	assert_int(await _driftwood_left()).is_equal(BeachLayout.driftwood().size() - 6)

func test_first_night_loads_with_camp_lit_and_him_by_the_fire() -> void:
	_load(P.FIRST_NIGHT)
	assert_float(_clock().total_minutes).is_equal(1200.0)
	await _assert_camp()

func test_morning_after_loads_on_day_two() -> void:
	_load(P.MORNING_AFTER)
	assert_int(_clock().day()).is_equal(2)
	assert_str(_clock().time_text()).is_equal("06:30")
	await _assert_camp()
