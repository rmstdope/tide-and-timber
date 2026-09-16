extends GdUnitTestSuite
## The build list's rules: costs, texts, what can be built, the one highlight.

const T := BuildMenu.Thing

func _menu(driftwood: int, lean_to: bool, fire: bool) -> BuildMenu:
	var m := BuildMenu.new()
	m.set_state(driftwood, lean_to, fire)
	return m

func test_costs_and_names() -> void:
	assert_array(BuildMenu.COSTS).is_equal([8, 4])
	assert_array(BuildMenu.NAMES).is_equal(["Lean-to", "Fire"])

func test_texts_no_lean_to() -> void:
	var m := _menu(9, false, false)
	assert_str(m.cost_text(T.LEAN_TO)).is_equal("9/8 driftwood")
	assert_str(m.cost_text(T.FIRE)).is_equal("Needs a lean-to")
	assert_bool(m.can_build(T.LEAN_TO)).is_true()
	assert_bool(m.can_build(T.FIRE)).is_false()

func test_texts_short() -> void:
	var m := _menu(3, false, false)
	assert_str(m.cost_text(T.LEAN_TO)).is_equal("3/8 driftwood")
	assert_bool(m.can_build(T.LEAN_TO)).is_false()
	assert_str(_menu(0, false, false).cost_text(T.LEAN_TO)).is_equal("0/8 driftwood")

func test_texts_lean_to_built() -> void:
	var m := _menu(5, true, false)
	assert_str(m.cost_text(T.LEAN_TO)).is_equal("Already built")
	assert_str(m.cost_text(T.FIRE)).is_equal("5/4 driftwood")
	assert_bool(m.can_build(T.FIRE)).is_true()
	m = _menu(2, true, false)
	assert_str(m.cost_text(T.FIRE)).is_equal("2/4 driftwood")
	assert_bool(m.can_build(T.FIRE)).is_false()

func test_texts_camp_complete() -> void:
	var m := _menu(23, true, true)
	assert_str(m.cost_text(T.LEAN_TO)).is_equal("Already built")
	assert_str(m.cost_text(T.FIRE)).is_equal("Already lit")
	assert_bool(m.can_build(T.LEAN_TO)).is_false()
	assert_bool(m.can_build(T.FIRE)).is_false()

func test_many_driftwood_shown_as_is() -> void:
	assert_str(_menu(23, false, false).cost_text(T.LEAN_TO)).is_equal("23/8 driftwood")

func test_open_highlights_first_buildable() -> void:
	for c: Array in [[9, false, false, 0], [5, true, false, 1], [3, false, false, -1], [9, true, true, -1]]:
		var m := _menu(c[0], c[1], c[2])
		m.open()
		assert_int(m.highlighted).is_equal(c[3])

func test_move_from_none_and_wraps() -> void:
	var m := _menu(0, false, false)
	m.move(1)
	assert_int(m.highlighted).is_equal(0)
	m.move(1)
	assert_int(m.highlighted).is_equal(1)
	m.move(1)
	assert_int(m.highlighted).is_equal(0)
	m = _menu(0, false, false)
	m.move(-1)
	assert_int(m.highlighted).is_equal(1)
	m.move(-1)
	assert_int(m.highlighted).is_equal(0)

func test_hover_sets_highlight_even_on_greyed() -> void:
	var m := _menu(3, false, false)
	m.open()
	m.hover(T.FIRE)
	assert_int(m.highlighted).is_equal(1)
