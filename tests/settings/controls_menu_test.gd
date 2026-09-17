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

# --- changing a slot (tr-eg9.5.4)

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	return e

func _button(index: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = index
	e.pressed = true
	return e

func _waiting_on(p_row: int, p_slot: int, device: Controls.Device = D.KEYBOARD) -> void:
	_open(device, true)
	menu.row = p_row
	menu.slot = p_slot
	assert_int(menu.pick()).is_equal(ControlsMenu.Outcome.CHANGE_SLOT)
	menu.begin_change(true)
	assert_int(menu.box).is_equal(ControlsMenu.Box.WAITING)

func test_change_opens_the_waiting_box() -> void:
	_open()
	assert_int(menu.pick()).is_equal(ControlsMenu.Outcome.CHANGE_SLOT)
	menu.begin_change(false)
	assert_int(menu.box).is_equal(ControlsMenu.Box.WAITING)
	assert_array(Array(menu.box_lines())).is_equal(["Walk up", "Press a new key"])

func test_controller_waiting_lines() -> void:
	_open(D.CONTROLLER)
	menu.row = 6
	menu.begin_change(true)
	assert_array(Array(menu.box_lines())).is_equal(["Build list", "Press a new button"])

func test_no_pad_on_controller() -> void:
	_open(D.CONTROLLER)
	menu.begin_change(false)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NO_PAD)
	assert_array(Array(menu.box_lines())).is_equal(["Connect a controller to change its buttons."])

func test_no_pad_ok_and_back_close() -> void:
	_open(D.CONTROLLER)
	menu.begin_change(false)
	assert_int(menu.box_press(ControlsMenu.BoxButton.SAFE)).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	menu.begin_change(false)
	menu.box_cancel()
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	menu.begin_change(false)
	menu.box_select(ControlsMenu.BoxButton.OTHER)
	assert_int(menu.box_selected).is_equal(ControlsMenu.BoxButton.SAFE)
	assert_int(menu.box_press(ControlsMenu.BoxButton.OTHER)).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	assert_bool(menu.is_open).is_true()

func test_no_pad_ignores_start() -> void:
	_open(D.CONTROLLER, true)
	menu.begin_change(false)
	assert_int(menu.start()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NO_PAD)

func test_begin_change_on_reset_row_does_nothing() -> void:
	_open()
	menu.move(-1)
	menu.begin_change(true)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)

func test_taken_key_goes_into_the_slot() -> void:
	_waiting_on(5, 1)
	menu.finish_change(_key(KEY_F))
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	assert_int((c.slot(A.USE, D.KEYBOARD, 1) as InputEventKey).physical_keycode).is_equal(KEY_F)
	assert_int(menu.row).is_equal(5)
	assert_int(menu.slot).is_equal(1)
	assert_str(menu.no_key_line).is_equal("")

func test_clash_that_leaves_no_key_shows_the_line() -> void:
	_waiting_on(6, 0)
	menu.finish_change(_key(KEY_E))
	assert_bool(c.has_no_key(A.USE, D.KEYBOARD)).is_true()
	assert_str(menu.no_key_line).is_equal("Use / take has no key")
	assert_bool(menu.is_orange(5)).is_true()

func test_clash_that_leaves_a_key_shows_no_line() -> void:
	_waiting_on(1, 1)
	menu.finish_change(_key(KEY_UP))
	assert_object(c.slot(A.WALK_UP, D.KEYBOARD, 1)).is_null()
	assert_int((c.slot(A.WALK_UP, D.KEYBOARD, 0) as InputEventKey).physical_keycode).is_equal(KEY_W)
	assert_str(menu.no_key_line).is_equal("")

func test_same_action_other_slot_moves_across() -> void:
	_waiting_on(0, 0)
	menu.finish_change(_key(KEY_UP))
	assert_int((c.slot(A.WALK_UP, D.KEYBOARD, 0) as InputEventKey).physical_keycode).is_equal(KEY_UP)
	assert_object(c.slot(A.WALK_UP, D.KEYBOARD, 1)).is_null()
	assert_str(menu.no_key_line).is_equal("")

func test_same_key_again_changes_nothing() -> void:
	_waiting_on(0, 0)
	var calls := [0]
	c.changed.connect(func() -> void: calls[0] += 1)
	menu.finish_change(_key(KEY_W))
	assert_int(calls[0]).is_equal(0)

func test_controller_clash() -> void:
	_waiting_on(6, 0, D.CONTROLLER)
	menu.finish_change(_button(JOY_BUTTON_A))
	assert_bool(c.has_no_key(A.USE, D.CONTROLLER)).is_true()
	assert_str(menu.no_key_line).is_equal("Use / take has no key")
	assert_int((c.slot(A.USE, D.KEYBOARD, 0) as InputEventKey).physical_keycode).is_equal(KEY_E)

func test_cancel_changes_nothing() -> void:
	_waiting_on(0, 0)
	var calls := [0]
	c.changed.connect(func() -> void: calls[0] += 1)
	menu.finish_change(null)
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	assert_int(calls[0]).is_equal(0)

func test_next_press_hides_the_clash_line() -> void:
	_waiting_on(6, 0)
	menu.finish_change(_key(KEY_E))
	menu.move(1)
	assert_str(menu.no_key_line).is_equal("")

func test_waiting_blocks_the_page() -> void:
	_waiting_on(2, 0)
	menu.move(1)
	menu.side(1)
	menu.switch_tab()
	menu.clear()
	assert_int(menu.back()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.start()).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box_press(ControlsMenu.BoxButton.OTHER)).is_equal(ControlsMenu.Outcome.NONE)
	assert_int(menu.box).is_equal(ControlsMenu.Box.WAITING)
	assert_int(menu.row).is_equal(2)
	assert_int(menu.slot).is_equal(0)
	assert_int(menu.device).is_equal(D.KEYBOARD)
	assert_object(c.slot(A.WALK_LEFT, D.KEYBOARD, 0)).is_not_null()

func test_pad_disconnect_closes_the_controller_box() -> void:
	_waiting_on(0, 0, D.CONTROLLER)
	menu.pad_disconnected()
	assert_int(menu.box).is_equal(ControlsMenu.Box.NONE)
	assert_object(c.slot(A.WALK_UP, D.CONTROLLER, 0)).is_not_null()

func test_pad_disconnect_leaves_the_keyboard_box() -> void:
	_waiting_on(0, 0)
	menu.pad_disconnected()
	assert_int(menu.box).is_equal(ControlsMenu.Box.WAITING)

func test_finish_without_waiting_does_nothing() -> void:
	_open()
	menu.finish_change(_key(KEY_F))
	assert_int((c.slot(A.WALK_UP, D.KEYBOARD, 0) as InputEventKey).physical_keycode).is_equal(KEY_W)
