extends GdUnitTestSuite
## The Debug panel's Story page rules: the five points, the star, the jumps and the world at each.

const P := StoryPoints.Point

var menu: DebugMenu
var jumped: Array = []
var now: StoryPoints.Point = P.FIRST_DAY

func before_test() -> void:
	menu = DebugMenu.new()
	jumped = []
	now = P.FIRST_DAY
	StoryPoints.add_rows(menu, func() -> StoryPoints.Point: return now, func(p: StoryPoints.Point) -> void: jumped.append(p))

func _rows() -> Array[DebugRow]:
	return menu.rows_of(DebugMenu.Page.STORY)

func _values() -> Array:
	return _rows().map(func(r: DebugRow) -> String: return r.value_text())

func test_story_rows_in_order() -> void:
	assert_array(_rows().map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Shipwreck story", "Waking on the beach", "First day", "First night", "Morning after"])
	for page: DebugMenu.Page in DebugMenu.Page.values():
		if page != DebugMenu.Page.STORY:
			assert_int(menu.rows_of(page).size()).is_equal(0)

func test_star_marks_only_the_current_point() -> void:
	assert_array(_values()).is_equal(["", "", "★", "", ""])
	now = P.MORNING_AFTER
	assert_array(_values()).is_equal(["", "", "", "", "★"])

func test_rows_have_no_step() -> void:
	for row in _rows():
		assert_bool(row.step.is_valid()).is_false()

func test_select_jumps_and_resumes() -> void:
	for row in _rows():
		assert_int(row.select.call()).is_equal(DebugRow.Result.RESUME)
	assert_array(jumped).is_equal([P.SHIPWRECK, P.WAKING, P.FIRST_DAY, P.FIRST_NIGHT, P.MORNING_AFTER])

func test_selecting_the_current_point_still_jumps() -> void:
	_rows()[2].select.call()
	_rows()[2].select.call()
	assert_array(jumped).is_equal([P.FIRST_DAY, P.FIRST_DAY])

func test_current_by_clock() -> void:
	assert_int(StoryPoints.current(true, 5000.0)).is_equal(P.SHIPWRECK)
	var cases := {0.0: P.WAKING, 780.0: P.WAKING, 959.0: P.WAKING, 960.0: P.FIRST_DAY, 1199.0: P.FIRST_DAY,
		1200.0: P.FIRST_NIGHT, 1829.0: P.FIRST_NIGHT, 1830.0: P.MORNING_AFTER, 9000.0: P.MORNING_AFTER}
	for minutes: float in cases:
		assert_int(StoryPoints.current(false, minutes)).override_failure_message(str(minutes)).is_equal(cases[minutes])

func test_each_world_is_its_own_current_point() -> void:
	for p: StoryPoints.Point in [P.FIRST_DAY, P.FIRST_NIGHT, P.MORNING_AFTER]:
		assert_int(StoryPoints.current(false, StoryPoints.world_for(p).clock_minutes)).is_equal(p)
	assert_int(StoryPoints.current(false, GameClock.START_MINUTES)).is_equal(P.WAKING)

func test_scenes_have_no_save() -> void:
	assert_object(StoryPoints.world_for(P.SHIPWRECK)).is_null()
	assert_object(StoryPoints.world_for(P.WAKING)).is_null()

func test_worlds_would_restore() -> void:
	for p: StoryPoints.Point in [P.FIRST_DAY, P.FIRST_NIGHT, P.MORNING_AFTER]:
		assert_bool(Beach.can_restore(StoryPoints.world_for(p))).is_true()
		assert_object(SaveData.from_files(StoryPoints.world_for(p).to_files())).is_not_null()

func test_first_day_world() -> void:
	var d := StoryPoints.world_for(P.FIRST_DAY)
	assert_bool(is_same(d, StoryPoints.world_for(P.FIRST_DAY))).is_false()
	assert_float(d.clock_minutes).is_equal(960.0)
	assert_int(d.day()).is_equal(1)
	assert_vector(d.player_position).is_equal(BeachLayout.cell_centre(StoryPoints.CAMP_CELL))
	assert_int(d.player_facing).is_equal(Walk.Facing.DOWN)
	assert_array(d.inventory_slots).is_equal([{"kind": Item.Kind.DRIFTWOOD, "count": 6}, {"kind": Item.Kind.SHELLFISH, "count": 2},
		{"kind": Item.Kind.COCONUT, "count": 1}, {"kind": Item.Kind.FRESH_WATER, "count": 1}, {}, {}, {}, {}])
	assert_int(d.taken["driftwood"].size()).is_equal(6)
	assert_array(d.taken["shellfish"]).is_equal(StoryPoints.SHELLFISH_TAKEN)
	assert_int(d.lean_to_cells.size()).is_equal(0)
	assert_bool(d.has_fire).is_false()

func _assert_camp(d: SaveData) -> void:
	assert_vector(d.player_position).is_equal(BeachLayout.cell_centre(StoryPoints.BY_THE_FIRE))
	assert_int(d.player_facing).is_equal(Walk.Facing.DOWN)
	assert_array(d.inventory_slots).is_equal([{}, {"kind": Item.Kind.SHELLFISH, "count": 2},
		{"kind": Item.Kind.COCONUT, "count": 1}, {"kind": Item.Kind.FRESH_WATER, "count": 1}, {}, {}, {}, {}])
	assert_array(d.taken["driftwood"]).is_equal(StoryPoints.DRIFTWOOD_BY_NIGHT)
	assert_array(d.lean_to_cells).is_equal(StoryPoints.CAMP_LEAN_TO)
	assert_bool(d.has_fire).is_true()
	assert_that(d.fire_cell).is_equal(StoryPoints.CAMP_FIRE)
	assert_bool(d.fire_lit).is_true()
	assert_float(d.fire_out_at).is_equal(StoryPoints.FIRE_OUT_AT)

func test_first_night_world() -> void:
	var d := StoryPoints.world_for(P.FIRST_NIGHT)
	assert_float(d.clock_minutes).is_equal(1200.0)
	_assert_camp(d)

func test_morning_after_world() -> void:
	var d := StoryPoints.world_for(P.MORNING_AFTER)
	assert_float(d.clock_minutes).is_equal(1830.0)
	assert_int(d.day()).is_equal(2)
	_assert_camp(d)
	assert_bool(FireLife.is_out(d.fire_out_at, d.clock_minutes)).is_false()

func test_camp_constants_agree_with_building() -> void:
	assert_array(BuildSite.cells_for(BuildMenu.Thing.LEAN_TO, StoryPoints.CAMP_CELL, Walk.Facing.DOWN)).is_equal(StoryPoints.CAMP_LEAN_TO)
	assert_that(BuildSite.fire_spot(BuildSite.anchor_of(StoryPoints.CAMP_LEAN_TO))).is_equal(StoryPoints.CAMP_FIRE)
	assert_that(WakeSpot.beside_lean_to(BuildSite.anchor_of(StoryPoints.CAMP_LEAN_TO), Waking.WAKE_CELL)).is_equal(StoryPoints.BY_THE_FIRE)
	assert_float(FireLife.out_at(1170.0)).is_equal(StoryPoints.FIRE_OUT_AT)
	var seen := {}
	for cell in StoryPoints.DRIFTWOOD_BY_NIGHT:
		assert_bool(cell in BeachLayout.driftwood()).is_true()
		seen[cell] = true
	assert_int(seen.size()).is_equal(StoryPoints.DRIFTWOOD_BY_NIGHT.size())
	for cell in StoryPoints.SHELLFISH_TAKEN:
		assert_bool(cell in BeachLayout.shellfish()).is_true()
