extends GdUnitTestSuite
## Waking from a save: no story, where he stood with his things, the saved dawn, a fade up.

var runner: GdUnitSceneRunner
var game: Waking
var player: Player

func _sample() -> SaveData:
	var d := SaveData.new()
	var slots: Array[Dictionary] = [{"kind": Item.Kind.DRIFTWOOD, "count": 3}, {}, {}, {}, {}, {}, {}, {}]
	d.inventory_slots = slots
	var first: Array[Vector2i] = [BeachLayout.DRIFTWOOD[0]]
	var none: Array[Vector2i] = []
	d.taken = {"driftwood": first, "shellfish": none}
	d.player_position = Vector2(400, 200)
	d.player_facing = Walk.Facing.LEFT
	d.clock_minutes = 4680.0
	return d

func before_test() -> void:
	InputDevice.reset()
	game = auto_free(load("res://src/waking/waking.tscn").instantiate()) as Waking
	game.resume_data = _sample()
	runner = scene_runner(game)
	game.set_process(false)
	_node("DayNight").set_process(false)
	_node("Autosave").set_process(false)
	player = game.player

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
	assert_int(driftwood.size()).is_equal(BeachLayout.DRIFTWOOD.size() - 1)

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
	assert_that((player.get_node("%Sprite") as AnimatedSprite2D).animation).is_not_equal(&"lie")
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
