extends GdUnitTestSuite

const K := BeachLayout.Kind

func _expect(cell: Vector2i, kind: int) -> void:
	assert_int(BeachLayout.kind_at(cell)).override_failure_message(
		"%s: expected %s, got %s" % [cell, K.keys()[kind], K.keys()[BeachLayout.kind_at(cell)]]).is_equal(kind)

func test_rows_top_to_bottom_in_the_middle() -> void:
	for y in 26:
		var expected: int
		if y <= 8: expected = K.JUNGLE
		elif y <= 13: expected = K.SAND
		elif y == 14: expected = K.WET_SAND
		elif y == 15: expected = K.FOAM
		elif y <= 17: expected = K.SHALLOWS
		else: expected = K.DEEP
		_expect(Vector2i(92, y), expected)

func test_headlands_close_both_ends() -> void:
	for cell: Vector2i in [Vector2i(12, 9), Vector2i(15, 17), Vector2i(168, 9), Vector2i(171, 17)]:
		_expect(cell, K.CLIFF)
	_expect(Vector2i(16, 9), K.SAND)
	_expect(Vector2i(167, 9), K.SAND)

func test_scenery_beyond_ends() -> void:
	_expect(Vector2i(0, 14), K.JUNGLE)
	_expect(Vector2i(183, 9), K.JUNGLE)
	_expect(Vector2i(0, 15), K.DEEP)
	_expect(Vector2i(183, 17), K.DEEP)

func test_solid_kinds() -> void:
	for kind: int in K.values():
		var solid := kind in [K.JUNGLE, K.DEEP, K.CLIFF]
		assert_bool(BeachLayout.is_solid(kind)).override_failure_message(K.keys()[kind]).is_equal(solid)

func test_spawn_is_middle_sand() -> void:
	_expect(BeachLayout.SPAWN_CELL, K.SAND)
	assert_int(BeachLayout.SPAWN_CELL.x).is_equal(BeachLayout.map_size().x / 2)
	assert_vector(BeachLayout.cell_centre(BeachLayout.SPAWN_CELL)).is_equal(Vector2(1480, 184))

func _all_props() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(BeachLayout.palms())
	cells.append_array(BeachLayout.rocks())
	cells.append_array(BeachLayout.boulders())
	cells.append_array(BeachLayout.driftwood())
	cells.append_array(BeachLayout.shellfish())
	cells.append_array(BeachLayout.springs())
	return cells

func test_shellfish_on_wet_sand() -> void:
	for cell in BeachLayout.shellfish():
		_expect(cell, K.WET_SAND)
	var seen := {}
	for cell in _all_props():
		assert_bool(seen.has(cell)).override_failure_message("%s used twice" % cell).is_false()
		seen[cell] = true

func test_props_stand_on_walkable_ground_away_from_spawn() -> void:
	for cell in _all_props():
		assert_bool(BeachLayout.is_solid(BeachLayout.kind_at(cell))).override_failure_message("%s solid" % cell).is_false()
		var d := cell - BeachLayout.SPAWN_CELL
		assert_int(maxi(absi(d.x), absi(d.y))).override_failure_message("%s near spawn" % cell).is_greater_equal(3)

func test_both_headlands_reachable() -> void:
	var blocked := {}
	for c in BeachLayout.rocks(): blocked[c] = true
	for c in BeachLayout.palms(): blocked[c] = true
	for c in BeachLayout.boulders() + BeachLayout.springs():
		blocked[c] = true
		blocked[c + Vector2i(-1, 0)] = true
		blocked[c + Vector2i(1, 0)] = true
	var seen := {BeachLayout.SPAWN_CELL: true}
	var queue: Array[Vector2i] = [BeachLayout.SPAWN_CELL]
	var bounds := Rect2i(Vector2i.ZERO, BeachLayout.map_size())
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if not bounds.has_point(next) or seen.has(next) or blocked.has(next):
				continue
			if BeachLayout.is_solid(BeachLayout.kind_at(next)):
				continue
			seen[next] = true
			queue.append(next)
	assert_bool(seen.has(Vector2i(16, 12))).is_true()
	assert_bool(seen.has(Vector2i(167, 12))).is_true()

func test_cell_base_is_bottom_centre() -> void:
	assert_vector(BeachLayout.cell_base(Vector2i(47, 9))).is_equal(Vector2(760, 160))

func test_spring_on_sand_against_the_jungle() -> void:
	assert_int(BeachLayout.springs().size()).is_equal(1)
	_expect(BeachLayout.springs()[0], K.SAND)
	_expect(BeachLayout.springs()[0] + Vector2i.UP, K.JUNGLE)

func test_coconuts_land_on_open_sand() -> void:
	var props := _all_props()
	for c in BeachLayout.boulders() + BeachLayout.springs():
		props.append(c + Vector2i(-1, 0))
		props.append(c + Vector2i(1, 0))
	for palm in BeachLayout.palms():
		for d in Shake.DROPS:
			var cell := Vector2i(((BeachLayout.cell_base(palm) + d) / BeachLayout.TILE).floor())
			_expect(cell, K.SAND)
			assert_bool(props.has(cell)).override_failure_message("%s lands on a prop" % cell).is_false()

func test_only_shallows_are_wadeable() -> void:
	for kind: int in BeachLayout.Kind.values():
		assert_bool(BeachLayout.is_wadeable(kind)).override_failure_message("kind %d" % kind) \
			.is_equal(kind == BeachLayout.Kind.SHALLOWS)

func test_cell_at_floors() -> void:
	assert_that(BeachLayout.cell_at(Vector2(1480, 184))).is_equal(Vector2i(92, 11))
	assert_that(BeachLayout.cell_at(Vector2(1480, 256))).is_equal(Vector2i(92, 16))
	assert_that(BeachLayout.cell_at(Vector2(1480, 255.9))).is_equal(Vector2i(92, 15))


func test_enough_driftwood_for_camp() -> void:
	var need: int = BuildMenu.COSTS[BuildMenu.Thing.LEAN_TO] + 2 * BuildMenu.COSTS[BuildMenu.Thing.FIRE] + 8
	assert_int(BeachLayout.driftwood().size()).is_greater_equal(need)
	for i in BeachLayout.driftwood().size():
		var cell := BeachLayout.driftwood()[i]
		assert_int(BeachLayout.kind_at(cell)).override_failure_message("%s not sand" % cell).is_equal(K.SAND)
		# The first five are the original pieces; driftwood()[2] stands by spawn on purpose.
		if i >= 5:
			assert_bool(cell.x >= 83 and cell.x <= 103).override_failure_message("%s near the camp" % cell).is_false()

func test_vegetation_stands_on_jungle() -> void:
	var seen := {}
	for cell: Vector2i in BeachLayout.bushes() + BeachLayout.tufts():
		assert_int(BeachLayout.kind_at(cell)).override_failure_message("%s" % cell).is_equal(BeachLayout.Kind.JUNGLE)
		assert_bool(seen.has(cell)).override_failure_message("%s twice" % cell).is_false()
		seen[cell] = true

func test_world_rect_is_the_whole_map_in_px() -> void:
	assert_that(BeachLayout.world_rect()).is_equal(Rect2(0, 0, 2944, 416))
	assert_vector(BeachLayout.world_rect().size).is_equal(Vector2(BeachLayout.map_size() * BeachLayout.TILE))

func test_prop_lists_are_read_only() -> void:
	for cells: Array[Vector2i] in [BeachLayout.palms(), BeachLayout.rocks(), BeachLayout.boulders(), BeachLayout.driftwood(),
			BeachLayout.shellfish(), BeachLayout.springs(), BeachLayout.bushes(), BeachLayout.tufts()]:
		assert_bool(cells.is_read_only()).is_true()

func test_cell_of_base_inverts_cell_base() -> void:
	for cell: Vector2i in [Vector2i(47, 9), Vector2i(0, 0), Vector2i(183, 25)]:
		assert_vector(Vector2(BeachLayout.cell_of_base(BeachLayout.cell_base(cell)))).is_equal(Vector2(cell))
	assert_vector(Vector2(BeachLayout.cell_of_base(Vector2(760, 161)))).is_equal(Vector2(47, 10))
	assert_vector(Vector2(BeachLayout.cell_of_base(Vector2(767.5, 150)))).is_equal(Vector2(47, 9))

## Saves name taken driftwood and shellfish by cell: moving one breaks saves, so it must fail here on purpose
## and come with a save migration (docs/beach-authoring.md).
func test_takeable_props_stay_where_saves_expect_them() -> void:
	assert_array(BeachLayout.driftwood()).is_equal([Vector2i(30, 13), Vector2i(69, 12), Vector2i(88, 13), Vector2i(130, 13),
		Vector2i(155, 12), Vector2i(19, 12), Vector2i(23, 12), Vector2i(37, 13), Vector2i(44, 13), Vector2i(50, 12),
		Vector2i(53, 13), Vector2i(61, 13), Vector2i(64, 13), Vector2i(74, 12), Vector2i(80, 13), Vector2i(107, 13),
		Vector2i(111, 13), Vector2i(116, 12), Vector2i(124, 13), Vector2i(137, 13), Vector2i(142, 12), Vector2i(152, 13),
		Vector2i(161, 12), Vector2i(164, 12)])
	assert_array(BeachLayout.shellfish()).is_equal([Vector2i(24, 14), Vector2i(51, 14), Vector2i(75, 14), Vector2i(96, 14),
		Vector2i(116, 14), Vector2i(143, 14), Vector2i(160, 14)])

func test_painted_map_starts_at_the_origin() -> void:
	var beach := (load(BeachLayout.SCENE) as PackedScene).instantiate()
	var used := (beach.get_node("%Ground") as TileMapLayer).get_used_rect()
	beach.free()
	assert_vector(Vector2(used.position)).is_equal(Vector2.ZERO)
