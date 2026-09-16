extends GdUnitTestSuite
## Where a lean-to or fire would go, and whether it may.

const T := BuildMenu.Thing
const F := Walk.Facing

func _rows_cols(cells: Array[Vector2i]) -> Array:
	var xs := {}
	var ys := {}
	for c in cells:
		xs[c.x] = true
		ys[c.y] = true
	var cx := xs.keys()
	var cy := ys.keys()
	cx.sort()
	cy.sort()
	return [cx, cy]

func test_lean_to_cells_each_facing() -> void:
	var at := Vector2i(10, 10)
	var down := BuildSite.cells_for(T.LEAN_TO, at, F.DOWN)
	assert_array(_rows_cols(down)).is_equal([[9, 10, 11], [11, 12]])
	assert_that(down[0]).is_equal(Vector2i(9, 11))
	assert_that(down[5]).is_equal(Vector2i(11, 12))
	assert_array(_rows_cols(BuildSite.cells_for(T.LEAN_TO, at, F.UP))).is_equal([[9, 10, 11], [8, 9]])
	assert_array(_rows_cols(BuildSite.cells_for(T.LEAN_TO, at, F.LEFT))).is_equal([[7, 8, 9], [9, 10]])
	assert_array(_rows_cols(BuildSite.cells_for(T.LEAN_TO, at, F.RIGHT))).is_equal([[11, 12, 13], [9, 10]])
	for f: F in [F.DOWN, F.UP, F.LEFT, F.RIGHT]:
		assert_int(BuildSite.cells_for(T.LEAN_TO, at, f).size()).is_equal(6)

func test_fire_cell_is_in_front() -> void:
	var at := Vector2i(10, 10)
	assert_array(BuildSite.cells_for(T.FIRE, at, F.DOWN)).is_equal([Vector2i(10, 11)])
	assert_array(BuildSite.cells_for(T.FIRE, at, F.UP)).is_equal([Vector2i(10, 9)])
	assert_array(BuildSite.cells_for(T.FIRE, at, F.LEFT)).is_equal([Vector2i(9, 10)])
	assert_array(BuildSite.cells_for(T.FIRE, at, F.RIGHT)).is_equal([Vector2i(11, 10)])

func test_anchor_origin_and_fire_spot() -> void:
	var cells := BuildSite.cells_for(T.LEAN_TO, Vector2i(92, 11), F.DOWN)
	assert_that(BuildSite.anchor_of(cells)).is_equal(Vector2i(92, 13))
	assert_that(BuildSite.origin_for(T.LEAN_TO, cells)).is_equal(Vector2(1480, 224))
	assert_that(BuildSite.fire_spot(Vector2i(92, 13))).is_equal(Vector2i(92, 14))
	var fire: Array[Vector2i] = [Vector2i(92, 14)]
	assert_that(BuildSite.origin_for(T.FIRE, fire)).is_equal(Vector2(1480, 240))

func test_cell_of() -> void:
	assert_that(BuildSite.cell_of(Vector2(1480, 184))).is_equal(Vector2i(92, 11))
	assert_that(BuildSite.cell_of(Vector2(15.9, 16.0))).is_equal(Vector2i(0, 1))

func test_prop_cells_cover_palms_rocks_boulders() -> void:
	var p := BuildSite.prop_cells()
	for c in [Vector2i(20, 9), Vector2i(26, 12), Vector2i(61, 9), Vector2i(62, 9), Vector2i(63, 9), Vector2i(61, 10), Vector2i(62, 10), Vector2i(63, 10)]:
		assert_bool(p.has(c)).override_failure_message("missing %s" % c).is_true()
	assert_bool(p.has(Vector2i(62, 11))).is_false()
	assert_bool(p.has(Vector2i(60, 10))).is_false()
	for c in [Vector2i(95, 9), Vector2i(96, 9), Vector2i(97, 9)]:
		assert_bool(p.has(c)).override_failure_message("spring base missing %s" % c).is_true()

func test_ground_ok() -> void:
	assert_bool(BuildSite.is_ground_ok(Vector2i(92, 11))).is_true()
	assert_bool(BuildSite.is_ground_ok(Vector2i(92, 14))).is_true()
	for c in [Vector2i(92, 8), Vector2i(92, 15), Vector2i(92, 16), Vector2i(92, 18), Vector2i(14, 12)]:
		assert_bool(BuildSite.is_ground_ok(c)).is_false()

func _can(facing: F, feet_cell: Vector2i, taken: Dictionary = BuildSite.prop_cells(), feet: Vector2 = BeachLayout.cell_centre(feet_cell)) -> bool:
	return BuildSite.can_place(T.LEAN_TO, BuildSite.cells_for(T.LEAN_TO, feet_cell, facing), taken,
		BuildSite.feet_rect(feet), false, Vector2i.ZERO)

func test_can_place_lean_to_open_sand() -> void:
	assert_bool(_can(F.DOWN, Vector2i(92, 11))).is_true()

func test_red_on_rock() -> void:
	assert_bool(_can(F.DOWN, Vector2i(99, 11))).is_false()

func test_red_on_boulder_cover() -> void:
	assert_bool(_can(F.UP, Vector2i(62, 12))).is_false()

func test_red_on_jungle_and_water() -> void:
	assert_bool(_can(F.UP, Vector2i(92, 10))).is_false()
	assert_bool(_can(F.DOWN, Vector2i(92, 14))).is_false()

func test_red_on_taken_cell() -> void:
	assert_bool(_can(F.DOWN, Vector2i(92, 11), {Vector2i(93, 13): true})).is_false()

func test_red_when_over_his_feet() -> void:
	assert_bool(_can(F.UP, Vector2i(92, 11), BuildSite.prop_cells(), Vector2(1480, 178))).is_false()
	assert_bool(_can(F.UP, Vector2i(92, 11), BuildSite.prop_cells(), Vector2(1480, 184))).is_true()

func test_fire_only_in_front_of_lean_to() -> void:
	var feet := BuildSite.feet_rect(BeachLayout.cell_centre(Vector2i(91, 14)))
	var spot: Array[Vector2i] = [Vector2i(92, 14)]
	var wrong: Array[Vector2i] = [Vector2i(90, 14)]
	assert_bool(BuildSite.can_place(T.FIRE, spot, {}, feet, true, Vector2i(92, 13))).is_true()
	assert_bool(BuildSite.can_place(T.FIRE, wrong, {}, feet, true, Vector2i(92, 13))).is_false()
	assert_bool(BuildSite.can_place(T.FIRE, spot, {}, feet, false, Vector2i(92, 13))).is_false()
