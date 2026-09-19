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
	_take(beach, Beach.DRIFTWOOD, BeachLayout.driftwood()[2])
	var d := beach.capture()
	assert_array(d.taken["driftwood"]).is_equal([BeachLayout.driftwood()[2]])
	assert_dict(d.inventory_slots[0]).is_equal({"kind": Item.Kind.DRIFTWOOD, "count": 1})

func test_restore_into_a_fresh_beach() -> void:
	_take(beach, Beach.DRIFTWOOD, BeachLayout.driftwood()[1])
	_take(beach, Beach.SHELLFISH, BeachLayout.shellfish()[0])
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
	assert_int(_count(b, "driftwood.tscn")).is_equal(BeachLayout.driftwood().size() - 1)
	assert_int(_count(b, "shellfish.tscn")).is_equal(BeachLayout.shellfish().size() - 1)

func test_restored_beach_keeps_each_shell() -> void:
	_take(beach, Beach.SHELLFISH, BeachLayout.shellfish()[0])
	var data := beach.capture()
	var b := scene_runner(SCENE).scene() as Beach
	assert_bool(b.restore(data)).is_true()
	await await_idle_frame()
	for i in [1, 3]:
		var shell := _prop_at(b, Beach.SHELLFISH, BeachLayout.shellfish()[i]) as Node2D
		var region := ((shell.get_node("Sprite") as Sprite2D).texture as AtlasTexture).region
		assert_bool(region == Rect2(BeachArt.SHELL_SHAPES[i])).override_failure_message("shell %d %s" % [i, region]).is_true()

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
		assert_int(_count(beach, "driftwood.tscn")).is_equal(BeachLayout.driftwood().size())

func test_restore_refuses_bad_inventory_unchanged() -> void:
	var data := beach.capture()
	data.player_position = Vector2(400, 200)
	var cells: Array[Vector2i] = [BeachLayout.driftwood()[0]]
	data.taken = {"driftwood": cells}
	var twice: Array[Dictionary] = [{"kind": Item.Kind.DRIFTWOOD, "count": 1}, {"kind": Item.Kind.DRIFTWOOD, "count": 2}, {}, {}, {}, {}, {}, {}]
	data.inventory_slots = twice
	assert_bool(beach.restore(data)).is_false()
	assert_vector(_player(beach).global_position).is_equal(BeachLayout.cell_centre(BeachLayout.SPAWN_CELL))
	assert_int(beach.inventory.slot_kind(0)).is_equal(Inventory.EMPTY)
	await await_idle_frame()
	assert_int(_count(beach, "driftwood.tscn")).is_equal(BeachLayout.driftwood().size())

func test_restore_does_not_raise_a_gain_line() -> void:
	var data := beach.capture()
	var slots: Array[Dictionary] = [{"kind": Item.Kind.DRIFTWOOD, "count": 3}, {}, {}, {}, {}, {}, {}, {}]
	data.inventory_slots = slots
	assert_bool(beach.restore(data)).is_true()
	assert_object(_player(beach).get_node_or_null("RisingLine")).is_null()

func _data(slots: Array[Dictionary], taken: Dictionary) -> SaveData:
	var d := SaveData.new()
	d.inventory_slots = slots
	d.taken = taken
	return d

func _empty_slots(n: int) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for i in n:
		slots.append({})
	return slots

func test_can_restore() -> void:
	var first: Array[Vector2i] = [BeachLayout.driftwood()[0]]
	var none: Array[Vector2i] = []
	var origin: Array[Vector2i] = [Vector2i(0, 0)]
	assert_bool(Beach.can_restore(_data(_empty_slots(8), {"driftwood": first, "shellfish": none}))).is_true()
	assert_bool(Beach.can_restore(_data(_empty_slots(8), {"rope": none}))).is_false()
	assert_bool(Beach.can_restore(_data(_empty_slots(8), {"driftwood": origin}))).is_false()
	var twice := _empty_slots(8)
	twice[0] = {"kind": Item.Kind.DRIFTWOOD, "count": 1}
	twice[1] = {"kind": Item.Kind.DRIFTWOOD, "count": 1}
	assert_bool(Beach.can_restore(_data(twice, {}))).is_false()
	assert_bool(Beach.can_restore(_data(_empty_slots(7), {}))).is_false()
	assert_bool(Beach.can_restore(_with_camp(_data(_empty_slots(8), {}), _good_cells(), true, FIRE_CELL))).is_true()
	for bad: SaveData in _bad_camps():
		assert_bool(Beach.can_restore(bad)).is_false()

const LEAN := BuildMenu.Thing.LEAN_TO
const FIRE_CELL := Vector2i(92, 14)

func _builder(b: Beach) -> Builder:
	return b.get_node("%Builder") as Builder

func _good_cells() -> Array[Vector2i]:
	return BuildSite.cells_for(LEAN, Vector2i(92, 11), Walk.Facing.DOWN)

func _lean_to(b: Beach) -> void:
	var l := LeanTo.new()
	l.cells = _good_cells()
	l.position = BuildSite.origin_for(LEAN, l.cells)
	b.get_node("%World").add_child(l)
	_builder(b).lean_to = l

func _fire(b: Beach) -> void:
	var f := CampFire.new()
	f.cell = FIRE_CELL
	f.position = Vector2(1480, 240)
	b.get_node("%World").add_child(f)
	_builder(b).fire = f

func _with_camp(d: SaveData, cells: Array[Vector2i], fire: bool, fire_cell: Vector2i) -> SaveData:
	d.lean_to_cells = cells
	d.has_fire = fire
	d.fire_cell = fire_cell
	d.fire_lit = fire
	return d

func _bad_camps() -> Array[SaveData]:
	var none: Array[Vector2i] = []
	var swapped := _good_cells()
	var first := swapped[0]
	swapped[0] = swapped[1]
	swapped[1] = first
	return [
		_with_camp(_data(_empty_slots(8), {}), none, true, FIRE_CELL),
		_with_camp(_data(_empty_slots(8), {}), swapped, false, FIRE_CELL),
		_with_camp(_data(_empty_slots(8), {}), BuildSite.cells_for(LEAN, Vector2i(92, 13), Walk.Facing.DOWN), false, FIRE_CELL),
		_with_camp(_data(_empty_slots(8), {}), _good_cells(), true, Vector2i(93, 14)),
		_with_camp(_data(_empty_slots(8), {}), _good_cells().slice(0, 5), false, FIRE_CELL),
	]

func test_camp_restores_into_a_fresh_beach() -> void:
	_lean_to(beach)
	_fire(beach)
	_builder(beach).fire.out_at = 1860.0
	var data := beach.capture()
	var b := scene_runner(SCENE).scene() as Beach
	assert_bool(b.restore(data)).is_true()
	var builder := _builder(b)
	assert_array(builder.lean_to.cells).is_equal(_good_cells())
	assert_vector(builder.lean_to.position).is_equal(BuildSite.origin_for(LEAN, _good_cells()))
	assert_vector(builder.fire.cell).is_equal(FIRE_CELL)
	assert_bool(builder.fire.lit).is_true()
	assert_float(builder.fire.out_at).is_equal(1860.0)
	assert_bool(builder.fire.glow.visible).is_true()
	assert_object(builder.lean_to.get_parent()).is_same(b.get_node("%World"))
	assert_object(builder.fire.get_parent()).is_same(b.get_node("%World"))

func test_ash_fire_restores_as_ash() -> void:
	_lean_to(beach)
	_fire(beach)
	_builder(beach).fire.put_out()
	var data := beach.capture()
	var b := scene_runner(SCENE).scene() as Beach
	assert_bool(b.restore(data)).is_true()
	var builder := _builder(b)
	assert_bool(builder.fire.lit).is_false()
	assert_bool(builder.fire.glow.visible).is_false()
	b.inventory.add(Item.Kind.DRIFTWOOD, 4)
	builder.open_list()
	assert_bool(builder.menu.can_build(BuildMenu.Thing.FIRE)).is_true()
	builder.close_list()

func test_lean_to_alone_restores_with_no_fire() -> void:
	_lean_to(beach)
	var data := beach.capture()
	var b := scene_runner(SCENE).scene() as Beach
	assert_bool(b.restore(data)).is_true()
	assert_object(_builder(b).lean_to).is_not_null()
	assert_object(_builder(b).fire).is_null()

func test_fresh_beach_captures_no_camp() -> void:
	var d := beach.capture()
	assert_array(d.lean_to_cells).is_empty()
	assert_bool(d.has_fire).is_false()

func test_restore_refuses_bad_camp_unchanged() -> void:
	for bad: SaveData in _bad_camps():
		bad.player_position = Vector2(400, 200)
		bad.inventory_slots[0] = {"kind": Item.Kind.DRIFTWOOD, "count": 3}
		assert_bool(beach.restore(bad)).is_false()
		assert_vector(_player(beach).global_position).is_equal(BeachLayout.cell_centre(BeachLayout.SPAWN_CELL))
		assert_object(_builder(beach).lean_to).is_null()
		assert_object(_builder(beach).fire).is_null()
		assert_int(beach.inventory.slot_kind(0)).is_equal(Inventory.EMPTY)
