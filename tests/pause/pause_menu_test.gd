extends GdUnitTestSuite
## The pause board's rules: planks, the one highlight, the quit box and what a pick leads to.

const I := PauseMenu.Plank
const C := PauseMenu.Choice
const O := PauseMenu.Outcome

var m: PauseMenu

func before_test() -> void:
	m = PauseMenu.new()

func test_open_starts_on_resume_with_the_box_closed() -> void:
	assert_bool(m.open()).is_true()
	assert_bool(m.is_open).is_true()
	assert_int(m.highlighted).is_equal(I.RESUME)
	assert_bool(m.box_open).is_false()

func test_open_while_open_is_refused() -> void:
	m.open()
	assert_bool(m.open()).is_false()

func test_items_on_the_beach_and_in_the_story() -> void:
	assert_array(PauseMenu.new().items).is_equal([I.RESUME, I.SETTINGS, I.QUIT_TO_TITLE])
	assert_array(PauseMenu.new(true).items).is_equal([I.RESUME, I.SKIP_STORY, I.SETTINGS, I.QUIT_TO_TITLE])

func test_move_wraps_round_three() -> void:
	m.open()
	for expected in [I.SETTINGS, I.QUIT_TO_TITLE, I.RESUME]:
		m.move(1)
		assert_int(m.highlighted).is_equal(expected)
	m.move(-1)
	assert_int(m.highlighted).is_equal(I.QUIT_TO_TITLE)

func test_move_wraps_round_four_with_skip_story() -> void:
	m = PauseMenu.new(true)
	m.open()
	m.move(1)
	assert_int(m.highlighted).is_equal(I.SKIP_STORY)
	m.move(-1)
	m.move(-1)
	assert_int(m.highlighted).is_equal(I.QUIT_TO_TITLE)

func test_reopening_starts_on_resume_again() -> void:
	m.open()
	m.move(1)
	m.back()
	m.open()
	assert_int(m.highlighted).is_equal(I.RESUME)

func test_nothing_works_while_closed() -> void:
	m.move(1)
	m.hover(I.SETTINGS)
	assert_int(m.pick(I.QUIT_TO_TITLE)).is_equal(O.NONE)
	assert_int(m.back()).is_equal(O.NONE)
	assert_int(m.highlighted).is_equal(I.RESUME)
	assert_bool(m.box_open).is_false()

func test_hover_ignores_an_item_not_on_the_board() -> void:
	m.open()
	m.hover(I.SKIP_STORY)
	assert_int(m.highlighted).is_equal(I.RESUME)
	assert_int(m.pick(I.SKIP_STORY)).is_equal(O.NONE)
	assert_bool(m.is_open).is_true()

func test_pick_resume_closes() -> void:
	m.open()
	assert_int(m.pick(I.RESUME)).is_equal(O.RESUMED)
	assert_bool(m.is_open).is_false()

func test_back_is_resume() -> void:
	m.open()
	m.hover(I.SETTINGS)
	assert_int(m.back()).is_equal(O.RESUMED)
	assert_bool(m.is_open).is_false()

func test_pick_skip_story_closes() -> void:
	m = PauseMenu.new(true)
	m.open()
	assert_int(m.pick(I.SKIP_STORY)).is_equal(O.SKIP_STORY)
	assert_bool(m.is_open).is_false()

func test_pick_settings_stays_open() -> void:
	m.open()
	assert_int(m.pick(I.SETTINGS)).is_equal(O.OPEN_SETTINGS)
	assert_bool(m.is_open).is_true()
	assert_int(m.highlighted).is_equal(I.SETTINGS)

func test_pick_quit_to_title_opens_the_box_on_stay() -> void:
	m.open()
	assert_int(m.pick(I.QUIT_TO_TITLE)).is_equal(O.NONE)
	assert_bool(m.box_open).is_true()
	assert_int(m.box_selected).is_equal(C.STAY)
	assert_bool(m.is_open).is_true()

func test_board_ignores_moves_and_back_while_the_box_is_open() -> void:
	m.open()
	m.pick(I.QUIT_TO_TITLE)
	m.move(1)
	assert_int(m.pick(I.RESUME)).is_equal(O.NONE)
	assert_int(m.back()).is_equal(O.NONE)
	assert_int(m.highlighted).is_equal(I.QUIT_TO_TITLE)
	assert_bool(m.box_open).is_true()
	assert_bool(m.is_open).is_true()

func test_box_select_stops_at_the_ends() -> void:
	m.open()
	m.pick(I.QUIT_TO_TITLE)
	m.box_select(C.QUIT)
	m.box_select(C.QUIT)
	assert_int(m.box_selected).is_equal(C.QUIT)
	m.box_select(C.STAY)
	m.box_select(C.STAY)
	assert_int(m.box_selected).is_equal(C.STAY)

func _assert_back_on_quit_to_title() -> void:
	assert_bool(m.box_open).is_false()
	assert_bool(m.is_open).is_true()
	assert_int(m.highlighted).is_equal(I.QUIT_TO_TITLE)

func test_stay_returns_to_quit_to_title() -> void:
	m.open()
	m.pick(I.QUIT_TO_TITLE)
	assert_int(m.box_press(C.STAY)).is_equal(O.NONE)
	_assert_back_on_quit_to_title()

func test_box_cancel_is_stay() -> void:
	m.open()
	m.pick(I.QUIT_TO_TITLE)
	m.box_select(C.QUIT)
	assert_int(m.box_cancel()).is_equal(O.NONE)
	_assert_back_on_quit_to_title()

func test_quit_locks_everything() -> void:
	m.open()
	m.pick(I.QUIT_TO_TITLE)
	assert_int(m.box_press(C.QUIT)).is_equal(O.QUITTING)
	assert_bool(m.quitting).is_true()
	assert_bool(m.open()).is_false()
	m.move(1)
	assert_int(m.back()).is_equal(O.NONE)
	assert_int(m.box_cancel()).is_equal(O.NONE)
	m.box_select(C.STAY)
	assert_int(m.box_press(C.STAY)).is_equal(O.NONE)
	assert_int(m.box_selected).is_equal(C.QUIT)
	assert_bool(m.box_open).is_true()
	assert_int(m.highlighted).is_equal(I.QUIT_TO_TITLE)

func test_quit_warning_words() -> void:
	assert_str(PauseMenu.quit_warning(true)).is_equal("Anything since this morning will be lost.")
	assert_str(PauseMenu.quit_warning(false)).is_equal("Nothing has been saved yet.")

func test_settings_blocks_the_board_until_closed() -> void:
	m.open()
	assert_int(m.pick(I.SETTINGS)).is_equal(O.OPEN_SETTINGS)
	assert_bool(m.settings_open).is_true()
	m.move(1)
	assert_int(m.back()).is_equal(O.NONE)
	assert_int(m.pick(I.RESUME)).is_equal(O.NONE)
	assert_bool(m.is_open).is_true()
	assert_int(m.highlighted).is_equal(I.SETTINGS)

func test_close_settings_returns_on_settings() -> void:
	m.open()
	m.pick(I.SETTINGS)
	m.close_settings()
	assert_bool(m.settings_open).is_false()
	assert_bool(m.is_open).is_true()
	assert_int(m.highlighted).is_equal(I.SETTINGS)
	m.move(1)
	assert_int(m.highlighted).is_equal(I.QUIT_TO_TITLE)

func test_resume_from_settings_closes_both() -> void:
	m.open()
	m.pick(I.SETTINGS)
	assert_int(m.resume_from_settings()).is_equal(O.RESUMED)
	assert_bool(m.is_open).is_false()
	assert_bool(m.settings_open).is_false()

func test_resume_from_settings_without_settings_does_nothing() -> void:
	m.open()
	assert_int(m.resume_from_settings()).is_equal(O.NONE)
	assert_bool(m.is_open).is_true()

func test_reopening_clears_settings() -> void:
	m.open()
	m.pick(I.SETTINGS)
	m.resume_from_settings()
	m.open()
	assert_bool(m.settings_open).is_false()

func test_items_with_debug_on_the_beach_and_in_the_story() -> void:
	assert_array(PauseMenu.new(false, true).items).is_equal([I.RESUME, I.SETTINGS, I.DEBUG, I.QUIT_TO_TITLE])
	assert_array(PauseMenu.new(true, true).items).is_equal([I.RESUME, I.SKIP_STORY, I.SETTINGS, I.DEBUG, I.QUIT_TO_TITLE])

func test_pick_debug_opens_debug_and_board_stops_taking_input() -> void:
	var d := PauseMenu.new(false, true)
	d.open()
	assert_int(d.pick(I.DEBUG)).is_equal(O.OPEN_DEBUG)
	assert_bool(d.debug_open).is_true()
	d.move(1)
	assert_int(d.highlighted).is_equal(I.DEBUG)

func test_close_debug_highlights_debug() -> void:
	var d := PauseMenu.new(false, true)
	d.open()
	d.pick(I.DEBUG)
	d.close_debug()
	assert_bool(d.debug_open).is_false()
	assert_bool(d.is_open).is_true()
	assert_int(d.highlighted).is_equal(I.DEBUG)

func test_resume_from_debug_closes_both() -> void:
	var d := PauseMenu.new(false, true)
	d.open()
	assert_int(d.resume_from_debug()).is_equal(O.NONE)
	d.pick(I.DEBUG)
	assert_int(d.resume_from_debug()).is_equal(O.RESUMED)
	assert_bool(d.is_open).is_false()
	assert_bool(d.debug_open).is_false()

func test_open_clears_debug_open() -> void:
	var d := PauseMenu.new(false, true)
	d.open()
	d.pick(I.DEBUG)
	d.resume_from_debug()
	d.debug_open = true
	d.is_open = false
	d.open()
	assert_bool(d.debug_open).is_false()

func test_leave_closes_everything_and_refuses_open() -> void:
	var d := PauseMenu.new(false, true)
	d.open()
	d.pick(I.DEBUG)
	d.leave()
	assert_bool(d.is_open).is_false()
	assert_bool(d.debug_open).is_false()
	assert_bool(d.box_open).is_false()
	assert_bool(d.settings_open).is_false()
	assert_bool(d.leaving).is_true()
	assert_bool(d.open()).is_false()
	assert_int(d.resume_from_debug()).is_equal(O.NONE)
	var highlighted := d.highlighted
	d.move(1)
	assert_int(d.highlighted).is_equal(highlighted)
	assert_int(d.pick(I.RESUME)).is_equal(O.NONE)
	assert_bool(d.is_open).is_false()
