extends GdUnitTestSuite

const SCENE := "res://src/beach/beach.tscn"

var runner: GdUnitSceneRunner
var beach: Beach

func before_test() -> void:
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach

func _player(b: Beach) -> Player:
	return b.get_node("%Player") as Player

func _count(b: Beach, suffix: String) -> int:
	return b.get_node("%Decor").get_children().filter(func(n: Node) -> bool:
		return n.scene_file_path.ends_with(suffix) and not n.is_queued_for_deletion()).size()

func _prop_at(b: Beach, scene: PackedScene, cell: Vector2i) -> Node:
	for n in b.get_node("%Decor").get_children():
		if n.scene_file_path == scene.resource_path and n.get_meta(Beach.CELL_META, null) == cell and not n.is_queued_for_deletion():
			return n
	return null

func _take(b: Beach, scene: PackedScene, cell: Vector2i) -> void:
	(_prop_at(b, scene, cell).get_node("Pickup") as Pickup).use(b.inventory)

func test_fresh_beach_captures_nothing_taken() -> void:
	var d := beach.capture()
	assert_dict(d.taken).is_equal({"driftwood": [], "shellfish": []})
	for slot in d.inventory_slots:
		assert_dict(slot).is_equal({})
	assert_int(d.inventory_slots.size()).is_equal(Inventory.SLOT_COUNT)
	assert_vector(d.player_position).is_equal(BeachLayout.cell_centre(BeachLayout.SPAWN_CELL))
	assert_int(d.player_facing).is_equal(Walk.Facing.DOWN)

func test_taken_prop_is_captured() -> void:
	_take(beach, Beach.DRIFTWOOD, BeachLayout.DRIFTWOOD[2])
	var d := beach.capture()
	assert_array(d.taken["driftwood"]).is_equal([BeachLayout.DRIFTWOOD[2]])
	assert_dict(d.inventory_slots[0]).is_equal({"kind": Item.Kind.DRIFTWOOD, "count": 1})

func test_restore_into_a_fresh_beach() -> void:
	_take(beach, Beach.DRIFTWOOD, BeachLayout.DRIFTWOOD[1])
	_take(beach, Beach.SHELLFISH, BeachLayout.SHELLFISH[0])
	_player(beach).global_position = Vector2(400, 200)
	_player(beach).facing = Walk.Facing.UP
	var data := beach.capture()
	var b := scene_runner(SCENE).scene() as Beach
	assert_bool(b.restore(data)).is_true()
	var again := b.capture()
	assert_vector(again.player_position).is_equal(data.player_position)
	assert_int(again.player_facing).is_equal(data.player_facing)
	assert_array(again.inventory_slots).is_equal(data.inventory_slots)
	assert_dict(again.taken).is_equal(data.taken)
	await await_idle_frame()
	assert_int(_count(b, "driftwood.tscn")).is_equal(BeachLayout.DRIFTWOOD.size() - 1)
	assert_int(_count(b, "shellfish.tscn")).is_equal(BeachLayout.SHELLFISH.size() - 1)

func test_restore_refuses_unknown_prop_or_cell_unchanged() -> void:
	var none: Array[Vector2i] = []
	var bad_cell: Array[Vector2i] = [Vector2i(0, 0)]
	for taken: Dictionary in [{"rope": none}, {"driftwood": bad_cell}]:
		var data := beach.capture()
		data.player_position = Vector2(400, 200)
		var slots: Array[Dictionary] = [{"kind": Item.Kind.DRIFTWOOD, "count": 3}, {}, {}, {}, {}, {}, {}, {}]
		data.inventory_slots = slots
		data.taken = taken
		assert_bool(beach.restore(data)).is_false()
		assert_vector(_player(beach).global_position).is_equal(BeachLayout.cell_centre(BeachLayout.SPAWN_CELL))
		assert_int(beach.inventory.slot_kind(0)).is_equal(Inventory.EMPTY)
		await await_idle_frame()
		assert_int(_count(beach, "driftwood.tscn")).is_equal(BeachLayout.DRIFTWOOD.size())

func test_restore_refuses_bad_inventory_unchanged() -> void:
	var data := beach.capture()
	data.player_position = Vector2(400, 200)
	var cells: Array[Vector2i] = [BeachLayout.DRIFTWOOD[0]]
	data.taken = {"driftwood": cells}
	var twice: Array[Dictionary] = [{"kind": Item.Kind.DRIFTWOOD, "count": 1}, {"kind": Item.Kind.DRIFTWOOD, "count": 2}, {}, {}, {}, {}, {}, {}]
	data.inventory_slots = twice
	assert_bool(beach.restore(data)).is_false()
	assert_vector(_player(beach).global_position).is_equal(BeachLayout.cell_centre(BeachLayout.SPAWN_CELL))
	assert_int(beach.inventory.slot_kind(0)).is_equal(Inventory.EMPTY)
	await await_idle_frame()
	assert_int(_count(beach, "driftwood.tscn")).is_equal(BeachLayout.DRIFTWOOD.size())

func test_restore_does_not_raise_a_gain_line() -> void:
	var data := beach.capture()
	var slots: Array[Dictionary] = [{"kind": Item.Kind.DRIFTWOOD, "count": 3}, {}, {}, {}, {}, {}, {}, {}]
	data.inventory_slots = slots
	assert_bool(beach.restore(data)).is_true()
	assert_object(_player(beach).get_node_or_null("RisingLine")).is_null()
