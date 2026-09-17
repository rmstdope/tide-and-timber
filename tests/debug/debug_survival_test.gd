extends GdUnitTestSuite
## The Survival page's rows: Place lean-to, Place fire, Remove builds, Collapse now.

const LABELS := ["Place lean-to", "Place fire", "Remove builds", "Collapse now"]

var menu: DebugMenu
var placed: Array = []
var place_ok := true
var removed := 0
var collapsed := 0

func before_test() -> void:
	menu = DebugMenu.new()
	placed = []
	place_ok = true
	removed = 0
	collapsed = 0

func _place(thing: BuildMenu.Thing) -> bool:
	placed.append(thing)
	return place_ok

func _remove() -> void:
	removed += 1

func _collapse() -> void:
	collapsed += 1

func _rows() -> Array[DebugRow]:
	return menu.rows_of(DebugMenu.Page.SURVIVAL)

func _labels() -> Array:
	return _rows().map(func(r: DebugRow) -> String: return r.label)

func test_four_rows_in_order() -> void:
	DebugSurvival.add_rows(menu, _place, _remove, _collapse)
	assert_array(_labels()).is_equal(LABELS)
	for p: DebugMenu.Page in DebugMenu.Page.values():
		if p != DebugMenu.Page.SURVIVAL:
			assert_array(menu.rows_of(p)).is_empty()
	for r in _rows():
		assert_str(r.value_text()).is_equal("")
		assert_bool(r.step.is_valid()).is_false()

func test_place_rows_pass_their_thing_and_report() -> void:
	DebugSurvival.add_rows(menu, _place, _remove, _collapse)
	assert_int(_rows()[0].select.call()).is_equal(DebugRow.Result.DONE)
	assert_array(placed).is_equal([BuildMenu.Thing.LEAN_TO])
	place_ok = false
	assert_int(_rows()[1].select.call()).is_equal(DebugRow.Result.REFUSED)
	assert_array(placed).is_equal([BuildMenu.Thing.LEAN_TO, BuildMenu.Thing.FIRE])

func test_remove_builds_row_calls_and_is_done() -> void:
	DebugSurvival.add_rows(menu, _place, _remove, _collapse)
	assert_int(_rows()[2].select.call()).is_equal(DebugRow.Result.DONE)
	assert_int(removed).is_equal(1)

func test_collapse_row_calls_and_resumes() -> void:
	DebugSurvival.add_rows(menu, _place, _remove, _collapse)
	assert_int(_rows()[3].select.call()).is_equal(DebugRow.Result.RESUME)
	assert_int(collapsed).is_equal(1)

func test_without_callables_rows_have_no_select() -> void:
	DebugSurvival.add_rows(menu)
	assert_array(_labels()).is_equal(LABELS)
	for r in _rows():
		assert_bool(r.select.is_valid()).is_false()
