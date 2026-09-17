extends GdUnitTestSuite
## The Debug panel's rules: six pages, the highlight, scrolling, what rows do, and the story dimming.

const P := DebugMenu.Page
const O := DebugMenu.Outcome

var m: DebugMenu

func before_test() -> void:
	m = DebugMenu.new()

func _rows(p: DebugMenu.Page, n: int) -> void:
	for i in n:
		m.add_row(p, DebugRow.new("Row %d" % i))

func test_open_starts_on_time_first_row() -> void:
	assert_bool(m.open(true)).is_true()
	assert_bool(m.is_open).is_true()
	assert_int(m.page).is_equal(P.TIME)
	assert_int(m.highlighted).is_equal(0)
	assert_int(m.scroll).is_equal(0)
	assert_bool(m.in_story).is_true()
	assert_bool(m.open(false)).is_false()
	assert_bool(m.in_story).is_true()

func test_reopen_starts_on_time_again() -> void:
	_rows(P.SHOW, 3)
	m.open(false)
	m.flip(-1)
	m.move(1)
	m.back()
	m.open(false)
	assert_int(m.page).is_equal(P.TIME)
	assert_int(m.highlighted).is_equal(0)

func test_flip_wraps_round_six_pages_and_resets_highlight() -> void:
	_rows(P.SHOW, 12)
	m.open(false)
	m.flip(-1)
	assert_int(m.page).is_equal(P.SHOW)
	m.move(-1)
	assert_int(m.scroll).is_greater(0)
	m.flip(1)
	assert_int(m.page).is_equal(P.TIME)
	assert_int(m.highlighted).is_equal(0)
	assert_int(m.scroll).is_equal(0)
	m.flip(1)
	assert_int(m.page).is_equal(P.ITEMS)

func test_flip_and_set_page_ignored_when_closed() -> void:
	m.flip(1)
	m.set_page(P.STORY)
	assert_int(m.page).is_equal(P.TIME)

func test_set_page() -> void:
	m.open(false)
	m.set_page(P.STORY)
	assert_int(m.page).is_equal(P.STORY)

func test_tab_names() -> void:
	assert_array(DebugMenu.TAB_NAMES).is_equal(["Time", "Items", "Place", "Story", "Surv.", "Show"])

func test_move_on_an_empty_page_does_nothing() -> void:
	m.open(false)
	m.move(1)
	m.move(-1)
	assert_int(m.highlighted).is_equal(0)
	assert_int(m.scroll).is_equal(0)

func test_move_wraps_round_rows() -> void:
	_rows(P.TIME, 3)
	m.open(false)
	m.move(-1)
	assert_int(m.highlighted).is_equal(2)
	m.move(1)
	assert_int(m.highlighted).is_equal(0)

func test_scroll_keeps_highlight_visible() -> void:
	_rows(P.TIME, 12)
	m.open(false)
	for i in 9:
		m.move(1)
	assert_int(m.highlighted).is_equal(9)
	assert_int(m.scroll).is_equal(1)
	for i in 9:
		m.move(-1)
	assert_int(m.highlighted).is_equal(0)
	assert_int(m.scroll).is_equal(0)
	m.move(-1)
	assert_int(m.highlighted).is_equal(11)
	assert_int(m.scroll).is_equal(3)

func test_hover_highlights_in_range() -> void:
	_rows(P.TIME, 3)
	m.open(false)
	m.hover(2)
	assert_int(m.highlighted).is_equal(2)
	m.hover(3)
	assert_int(m.highlighted).is_equal(2)

func test_change_calls_step_with_delta() -> void:
	var got: Array[int] = []
	m.add_row(P.TIME, DebugRow.new("A", Callable(), func(d: int) -> void: got.append(d)))
	m.add_row(P.TIME, DebugRow.new("B"))
	assert_bool(m.change(1)).is_false()
	m.open(false)
	assert_bool(m.change(-1)).is_true()
	assert_bool(m.change(1)).is_true()
	assert_array(got).is_equal([-1, 1])
	m.move(1)
	assert_bool(m.change(1)).is_false()

func test_pick_results() -> void:
	var called: Array[String] = []
	m.add_row(P.TIME, DebugRow.new("Done", Callable(), Callable(), func() -> DebugRow.Result: return DebugRow.Result.DONE))
	m.add_row(P.TIME, DebugRow.new("No", Callable(), Callable(), func() -> DebugRow.Result: return DebugRow.Result.REFUSED))
	m.add_row(P.TIME, DebugRow.new("Plain", func() -> String: called.append("value"); return "", func(_d: int) -> void: called.append("step")))
	m.add_row(P.TIME, DebugRow.new("Go", Callable(), Callable(), func() -> DebugRow.Result: return DebugRow.Result.RESUME))
	m.open(false)
	assert_int(m.pick()).is_equal(O.NONE)
	assert_bool(m.is_open).is_true()
	m.move(1)
	assert_int(m.pick()).is_equal(O.SHAKE)
	m.move(1)
	assert_int(m.pick()).is_equal(O.NONE)
	assert_array(called).is_empty()
	m.move(1)
	assert_int(m.pick()).is_equal(O.RESUME_PLAY)
	assert_bool(m.is_open).is_false()
	assert_int(m.pick()).is_equal(O.NONE)

func test_pick_on_an_empty_page() -> void:
	m.open(false)
	assert_int(m.pick()).is_equal(O.NONE)

func test_in_story_only_story_and_show_work() -> void:
	m.open(true)
	for p: DebugMenu.Page in [P.TIME, P.ITEMS, P.PLACE, P.SURVIVAL]:
		assert_bool(m.page_works(p)).is_false()
	for p: DebugMenu.Page in [P.STORY, P.SHOW]:
		assert_bool(m.page_works(p)).is_true()
	m.back()
	m.open(false)
	for p in P.values():
		assert_bool(m.page_works(p)).is_true()

func test_dimmed_page_rows_are_inert_but_highlight_moves() -> void:
	var called: Array[String] = []
	for i in 2:
		m.add_row(P.PLACE, DebugRow.new("R", Callable(), func(_d: int) -> void: called.append("step"),
				func() -> DebugRow.Result: called.append("select"); return DebugRow.Result.DONE))
	m.open(true)
	m.set_page(P.PLACE)
	assert_bool(m.change(1)).is_false()
	assert_int(m.pick()).is_equal(O.NONE)
	assert_array(called).is_empty()
	m.move(1)
	assert_int(m.highlighted).is_equal(1)

func test_back_and_start() -> void:
	assert_int(m.back()).is_equal(O.NONE)
	assert_int(m.start()).is_equal(O.NONE)
	m.open(false)
	assert_int(m.back()).is_equal(O.CLOSED)
	assert_bool(m.is_open).is_false()
	m.open(false)
	assert_int(m.start()).is_equal(O.RESUME_PLAY)
	assert_bool(m.is_open).is_false()

func test_rows_survive_close_and_reopen() -> void:
	_rows(P.ITEMS, 2)
	m.open(false)
	m.back()
	m.open(false)
	assert_int(m.rows_of(P.ITEMS).size()).is_equal(2)
	assert_int(m.rows_of(P.TIME).size()).is_equal(0)

func test_value_text() -> void:
	assert_str(DebugRow.new("A").value_text()).is_equal("")
	assert_str(DebugRow.new("A", func() -> String: return "x1").value_text()).is_equal("x1")
