extends GdUnitTestSuite
## The Place page's rules: its rows, where each place is, and which way he faces there.

const Place := DebugPlaces.Place

var menu: DebugMenu
var went: Array
var rows: Array[DebugRow]

func before_test() -> void:
	menu = DebugMenu.new()
	went = []
	DebugPlaces.add_rows(menu, func(p: DebugPlaces.Place) -> void: went.append(p))
	rows = menu.rows_of(DebugMenu.Page.PLACE)

func after_test() -> void:
	DebugSwitches.walk_through = false

func test_place_page_rows_in_order() -> void:
	assert_array(rows.map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Walk through things", "Where he woke", "Wreck", "Beach", "Spring", "Camp"])
	for p: DebugMenu.Page in DebugMenu.Page.values():
		if p != DebugMenu.Page.PLACE:
			assert_array(menu.rows_of(p)).is_empty()

func test_walk_through_row_shows_off_then_on() -> void:
	assert_str(rows[0].value_text()).is_equal("Off")
	rows[0].step.call(1)
	assert_bool(DebugSwitches.walk_through).is_true()
	assert_str(rows[0].value_text()).is_equal("On")
	rows[0].step.call(-1)
	assert_str(rows[0].value_text()).is_equal("Off")

func test_walk_through_select_flips_and_is_done() -> void:
	assert_int(rows[0].select.call()).is_equal(DebugRow.Result.DONE)
	assert_bool(DebugSwitches.walk_through).is_true()
	rows[0].select.call()
	assert_bool(DebugSwitches.walk_through).is_false()

func test_place_rows_go_to_their_place() -> void:
	for i in range(1, 6):
		assert_int(rows[i].select.call()).is_equal(DebugRow.Result.DONE)
		assert_str(rows[i].value_text()).is_equal("")
		assert_bool(rows[i].step.is_valid()).is_false()
	assert_array(went).is_equal([Place.WOKE, Place.WRECK, Place.BEACH, Place.SPRING, Place.CAMP])

func test_selecting_the_same_place_twice_goes_twice() -> void:
	rows[3].select.call()
	rows[3].select.call()
	assert_array(went).is_equal([Place.BEACH, Place.BEACH])

func test_without_go_to_place_rows_have_no_select() -> void:
	var menu2 := DebugMenu.new()
	DebugPlaces.add_rows(menu2, Callable())
	var rows2 := menu2.rows_of(DebugMenu.Page.PLACE)
	for i in range(1, 6):
		assert_bool(rows2[i].select.is_valid()).is_false()
	rows2[0].select.call()
	assert_bool(DebugSwitches.walk_through).is_true()

func test_cells_for_places() -> void:
	assert_vector(DebugPlaces.cell_for(Place.WOKE, false, Vector2i.ZERO)).is_equal(Waking.WAKE_CELL)
	assert_vector(DebugPlaces.cell_for(Place.WRECK, false, Vector2i.ZERO)).is_equal(Vector2i(92, 17))
	assert_vector(DebugPlaces.cell_for(Place.BEACH, false, Vector2i.ZERO)).is_equal(BeachLayout.SPAWN_CELL)
	assert_vector(DebugPlaces.cell_for(Place.SPRING, false, Vector2i.ZERO)).is_equal(Vector2i(96, 10))
	assert_vector(DebugPlaces.cell_for(Place.CAMP, false, Vector2i.ZERO)).is_equal(Vector2i(86, 10))
	assert_vector(DebugPlaces.cell_for(Place.CAMP, true, Vector2i(40, 12))) \
		.is_equal(WakeSpot.beside_lean_to(Vector2i(40, 12), Waking.WAKE_CELL))

func test_places_are_open_ground() -> void:
	for p: DebugPlaces.Place in [Place.WOKE, Place.BEACH, Place.SPRING, Place.CAMP]:
		assert_bool(WakeSpot.is_open(DebugPlaces.cell_for(p, false, Vector2i.ZERO))) \
			.override_failure_message("place %d is not open" % p).is_true()
	assert_int(BeachLayout.kind_at(DebugPlaces.WRECK_CELL)).is_equal(BeachLayout.Kind.SHALLOWS)

func test_a_lean_to_fits_down_from_camp() -> void:
	var cells := BuildSite.cells_for(BuildMenu.Thing.LEAN_TO, DebugPlaces.CAMP_CELL, Walk.Facing.DOWN)
	assert_bool(BuildSite.can_place(BuildMenu.Thing.LEAN_TO, cells, BuildSite.prop_cells(),
			BuildSite.feet_rect(BeachLayout.cell_centre(DebugPlaces.CAMP_CELL)), false, Vector2i.ZERO)).is_true()

func test_facing() -> void:
	assert_int(DebugPlaces.facing_for(Place.SPRING)).is_equal(Walk.Facing.UP)
	for p: DebugPlaces.Place in [Place.WOKE, Place.WRECK, Place.BEACH, Place.CAMP]:
		assert_int(DebugPlaces.facing_for(p)).is_equal(Walk.Facing.DOWN)
