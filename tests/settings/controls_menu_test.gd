extends GdUnitTestSuite
## The Controls page's rules: tabs, rows and slots, Clear and its line, Reset, leaving and Start.

const A := Controls.Action
const D := Controls.Device

var c: Controls
var menu: ControlsMenu

func before_test() -> void:
	c = Controls.new()
	menu = ControlsMenu.new(c)

func _open(device: Controls.Device = D.KEYBOARD, from_pause: bool = false) -> void:
	menu.open(device, from_pause)

func _clear_all(a: Controls.Action) -> void:
	for d: Controls.Device in D.values():
		for i in Controls.slot_count(d):
			c.clear_slot(a, d, i)

# --- tabs, rows and slots

func test_opens_on_the_given_tab_on_walk_up() -> void:
	_open(D.CONTROLLER)
	assert_int(menu.device).is_equal(D.CONTROLLER)
	assert_int(menu.row).is_equal(0)
	assert_int(menu.slot).is_equal(0)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	assert_str(menu.no_key_line).is_equal("")
	assert_bool(menu.is_open).is_true()

func test_move_wraps_over_nine_rows() -> void:
	_open()
	menu.move(-1)
	assert_int(menu.row).is_equal(ControlsMenu.RESET_ROW)
	assert_int(menu.action()).is_equal(-1)
	menu.move(1)
	assert_int(menu.row).is_equal(0)

func test_side_stops_at_the_ends_on_keyboard() -> void:
	_open()
	menu.side(1)
	menu.side(1)
	assert_int(menu.slot).is_equal(1)
	menu.side(-1)
	menu.side(-1)
	assert_int(menu.slot).is_equal(0)

func test_side_does_nothing_on_controller_and_reset() -> void:
	_open(D.CONTROLLER)
	menu.side(1)
	assert_int(menu.slot).is_equal(0)
	_open()
	menu.move(-1)
	menu.side(1)
	assert_int(menu.slot).is_equal(0)

func test_switch_tab_keeps_the_row_and_clamps_the_slot() -> void:
	_open()
	menu.move(3)
	menu.side(1)
	menu.switch_tab()
	assert_int(menu.device).is_equal(D.CONTROLLER)
	assert_int(menu.row).is_equal(3)
	assert_int(menu.slot).is_equal(0)
	menu.switch_tab()
	assert_int(menu.device).is_equal(D.KEYBOARD)
	assert_int(menu.row).is_equal(3)
	assert_int(menu.slot).is_equal(0)

func test_hover_highlights_without_clearing_the_line() -> void:
	_open()
	menu.note_no_key(A.RUN)
	menu.hover(4, 1)
	assert_int(menu.row).is_equal(4)
	assert_int(menu.slot).is_equal(1)
	assert_str(menu.no_key_line).is_equal("Run (hold) has no key")

func test_pick_on_a_slot_asks_for_change() -> void:
	_open()
	assert_int(menu.pick()).is_equal(ControlsMenu.Outcome.CHANGE_SLOT)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)

# --- clear and the line

func test_clear_empties_the_slot() -> void:
	_open()
	menu.side(1)
	menu.clear()
	assert_object(c.slot(A.WALK_UP, D.KEYBOARD, 1)).is_null()
	assert_str(menu.no_key_line).is_equal("")

func test_clear_to_no_key_shows_the_line() -> void:
	_open()
	menu.move(6)
	menu.clear()
	assert_str(menu.no_key_line).is_equal("Build list has no key")
	assert_bool(menu.is_orange(6)).is_true()
	assert_bool(menu.is_orange(5)).is_false()

func test_next_press_hides_the_line() -> void:
	_open()
	menu.move(6)
	menu.clear()
	menu.move(1)
	assert_str(menu.no_key_line).is_equal("")

func test_clear_on_empty_slot_changes_nothing() -> void:
	_open()
	menu.move(4)
	menu.side(1)
	var emitted := [0]
	c.changed.connect(func() -> void: emitted[0] += 1)
	menu.clear()
	assert_int(emitted[0]).is_equal(0)
	assert_str(menu.no_key_line).is_equal("")

func test_clear_on_reset_row_does_nothing() -> void:
	_open()
	menu.move(-1)
	var emitted := [0]
	c.changed.connect(func() -> void: emitted[0] += 1)
	menu.clear()
	assert_int(emitted[0]).is_equal(0)

func test_clear_on_controller_tab() -> void:
	_open(D.CONTROLLER)
	menu.move(5)
	menu.clear()
	assert_object(c.slot(A.USE, D.CONTROLLER, 0)).is_null()
	assert_object(c.slot(A.USE, D.KEYBOARD, 0)).is_not_null()
	assert_str(menu.no_key_line).is_equal("Use / take has no key")

# --- reset

func test_reset_asks_and_keep_mine_changes_nothing() -> void:
	_open()
	menu.move(5)
	menu.clear()
	menu.move(3)
	assert_int(menu.row).is_equal(ControlsMenu.RESET_ROW)
	assert_int(menu.pick()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.RESET)
	assert_int(menu.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_array(Array(menu.box_lines())).is_equal(["Put every keyboard key back as it was?"])
	menu.box_cancel()
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	assert_int(menu.row).is_equal(ControlsMenu.RESET_ROW)
	assert_object(c.slot(A.USE, D.KEYBOARD, 0)).is_null()

func test_reset_resets_only_this_tab() -> void:
	c.clear_slot(A.USE, D.KEYBOARD, 0)
	c.clear_slot(A.USE, D.CONTROLLER, 0)
	_open()
	menu.move(-1)
	menu.pick()
	assert_int(menu.box_press(ControlsMenu.BoxButton.OTHER)).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	assert_bool(Controls.same_input(c.slot(A.USE, D.KEYBOARD, 0), Controls.default_slot(A.USE, D.KEYBOARD, 0))).is_true()
	assert_object(c.slot(A.USE, D.CONTROLLER, 0)).is_null()
	assert_int(menu.row).is_equal(ControlsMenu.RESET_ROW)

func test_controller_reset_question() -> void:
	_open(D.CONTROLLER)
	menu.move(-1)
	menu.pick()
	assert_array(Array(menu.box_lines())).is_equal(["Put every controller button back as it was?"])

func test_box_blocks_the_page() -> void:
	c.clear_slot(A.RUN, D.KEYBOARD, 0)
	_open(D.KEYBOARD, true)
	menu.move(-1)
	menu.pick()
	menu.move(1)
	menu.side(1)
	menu.switch_tab()
	menu.clear()
	assert_int(menu.back()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.start()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.row).is_equal(ControlsMenu.RESET_ROW)
	assert_int(menu.device).is_equal(D.KEYBOARD)
	assert_int(menu.box).is_equal(ControlsMenu.Box.RESET)
	assert_bool(menu.is_open).is_true()
	assert_object(c.slot(A.WALK_UP, D.KEYBOARD, 0)).is_not_null()

# --- leaving

func test_back_with_no_empty_action_closes() -> void:
	_open()
	assert_int(menu.back()).is_equal(ControlsMenu.Outcome.CLOSED)
	assert_bool(menu.is_open).is_false()

func test_back_with_one_empty_action_warns() -> void:
	c.clear_slot(A.BUILD_LIST, D.KEYBOARD, 0)
	_open()
	assert_int(menu.back()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.LEAVING)
	assert_int(menu.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_array(Array(menu.box_lines())).is_equal(["Build list has no key.", "Leave anyway?"])

func test_same_action_empty_on_both_tabs_is_one_action() -> void:
	_clear_all(A.BUILD_LIST)
	_open()
	menu.back()
	assert_str(menu.box_lines()[0]).is_equal("Build list has no key.")
	assert_array(menu.empty_actions()).is_equal([A.BUILD_LIST])

func test_two_empty_actions_use_the_plural() -> void:
	c.clear_slot(A.BUILD_LIST, D.KEYBOARD, 0)
	c.clear_slot(A.USE, D.CONTROLLER, 0)
	_open()
	menu.back()
	assert_array(Array(menu.box_lines())).is_equal(["Some actions have no key.", "Leave anyway?"])

func test_every_action_empty_is_allowed_and_plural() -> void:
	for a: Controls.Action in A.values():
		_clear_all(a)
	_open()
	assert_int(menu.back()).is_equal(ControlsMenu.Outcome.NONE)
	assert_array(Array(menu.box_lines())).is_equal(["Some actions have no key.", "Leave anyway?"])

func test_set_a_key_goes_to_the_first_empty_action() -> void:
	c.clear_slot(A.RUN, D.KEYBOARD, 0)
	c.clear_slot(A.PAUSE, D.KEYBOARD, 0)
	_open()
	menu.back()
	assert_int(menu.box_press(ControlsMenu.BoxButton.SAFE)).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	assert_int(menu.row).is_equal(A.RUN)
	assert_int(menu.slot).is_equal(0)
	assert_int(menu.device).is_equal(D.KEYBOARD)
	assert_bool(menu.is_open).is_true()

func test_set_a_key_switches_tab_when_needed() -> void:
	c.clear_slot(A.USE, D.CONTROLLER, 0)
	_open()
	menu.side(1)
	menu.back()
	menu.box_cancel()
	assert_int(menu.device).is_equal(D.CONTROLLER)
	assert_int(menu.row).is_equal(A.USE)
	assert_int(menu.slot).is_equal(0)

func test_leave_closes_with_the_action_kept_empty() -> void:
	c.clear_slot(A.BUILD_LIST, D.KEYBOARD, 0)
	_open()
	menu.back()
	assert_int(menu.box_press(ControlsMenu.BoxButton.OTHER)).is_equal(ControlsMenu.Outcome.CLOSED)
	assert_bool(menu.is_open).is_false()
	assert_object(c.slot(A.BUILD_LIST, D.KEYBOARD, 0)).is_null()

# --- start

func test_start_from_the_title_does_nothing() -> void:
	_open(D.KEYBOARD, false)
	menu.note_no_key(A.RUN)
	assert_int(menu.start()).is_equal(ControlsMenu.Outcome.NONE)
	assert_bool(menu.is_open).is_true()
	assert_str(menu.no_key_line).is_equal("Run (hold) has no key")

func test_start_from_pause_resumes() -> void:
	_open(D.KEYBOARD, true)
	assert_int(menu.start()).is_equal(ControlsMenu.Outcome.RESUME_PLAY)
	assert_bool(menu.is_open).is_false()

func test_start_with_an_empty_action_warns_and_leave_resumes() -> void:
	c.clear_slot(A.BUILD_LIST, D.KEYBOARD, 0)
	_open(D.KEYBOARD, true)
	assert_int(menu.start()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.LEAVING)
	assert_int(menu.box_press(ControlsMenu.BoxButton.OTHER)).is_equal(ControlsMenu.Outcome.RESUME_PLAY)
	assert_bool(menu.is_open).is_false()

func test_back_warning_leave_after_start_warning_closes() -> void:
	c.clear_slot(A.BUILD_LIST, D.KEYBOARD, 0)
	_open(D.KEYBOARD, true)
	menu.start()
	menu.box_cancel()
	menu.back()
	assert_int(menu.box_press(ControlsMenu.BoxButton.OTHER)).is_equal(ControlsMenu.Outcome.CLOSED)

func test_start_warning_set_a_key_stays() -> void:
	c.clear_slot(A.BUILD_LIST, D.KEYBOARD, 0)
	_open(D.KEYBOARD, true)
	menu.start()
	assert_int(menu.box_cancel()).is_equal(ControlsMenu.Outcome.NONE)
	assert_bool(menu.is_open).is_true()
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)

func test_start_in_a_box_is_ignored() -> void:
	_open(D.KEYBOARD, true)
	menu.move(-1)
	menu.pick()
	assert_int(menu.start()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.RESET)

func test_box_select_moves_the_highlight() -> void:
	_open()
	menu.box_select(ControlsMenu.BoxButton.OTHER)
	assert_int(menu.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	menu.move(-1)
	menu.pick()
	menu.box_select(ControlsMenu.BoxButton.OTHER)
	assert_int(menu.box_selected).is_equal(ControlsMenu.BoxButton.OTHER)

func test_closed_page_ignores_everything() -> void:
	assert_int(menu.back()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.start()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.pick()).is_equal(ControlsMenu.Outcome.NONE)
	menu.clear()
	assert_object(c.slot(A.WALK_UP, D.KEYBOARD, 0)).is_not_null()
	assert_bool(menu.is_open).is_false()
