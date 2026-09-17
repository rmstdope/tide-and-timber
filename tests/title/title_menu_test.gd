extends GdUnitTestSuite

func test_starts_on_new_game_unlocked() -> void:
	var menu := TitleMenu.new()
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
	assert_bool(menu.locked).is_false()

func test_move_down_then_wraps() -> void:
	var menu := TitleMenu.new()
	menu.move(1)
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.SETTINGS)
	menu.move(1)
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.QUIT)
	menu.move(1)
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)

func test_move_up_from_new_game_wraps_to_quit() -> void:
	var menu := TitleMenu.new()
	menu.move(-1)
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.QUIT)

func test_hover_moves_the_one_highlight() -> void:
	var menu := TitleMenu.new()
	menu.hover(TitleMenu.Choice.QUIT)
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.QUIT)
	menu.move(1)
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)

func test_pick_new_game_locks() -> void:
	var menu := TitleMenu.new()
	assert_int(menu.pick(TitleMenu.Choice.NEW_GAME)).is_equal(TitleMenu.Action.NEW_GAME)
	assert_bool(menu.locked).is_true()
	menu.move(1)
	menu.hover(TitleMenu.Choice.QUIT)
	assert_int(menu.pick(TitleMenu.Choice.QUIT)).is_equal(TitleMenu.Action.NONE)
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
	assert_bool(menu.locked).is_true()

func test_pick_quit_does_not_lock() -> void:
	var menu := TitleMenu.new()
	assert_int(menu.pick(TitleMenu.Choice.QUIT)).is_equal(TitleMenu.Action.QUIT)
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.QUIT)
	assert_bool(menu.locked).is_false()

const C := TitleMenu.Choice
const B := TitleMenu.BoxButton
const A := TitleMenu.Action

func _save_menu() -> TitleMenu:
	return TitleMenu.new(true, true)

func _start_over_open() -> TitleMenu:
	var menu := _save_menu()
	menu.pick(C.NEW_GAME)
	return menu

func test_no_save_has_three_choices() -> void:
	var menu := TitleMenu.new()
	assert_array(menu.choices).is_equal([C.NEW_GAME, C.SETTINGS, C.QUIT])
	menu.hover(C.CONTINUE)
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)
	assert_int(menu.pick(C.CONTINUE)).is_equal(A.NONE)
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)
	assert_bool(menu.locked).is_false()
	assert_int(menu.box).is_equal(TitleMenu.Box.NONE)

func test_save_has_four_choices_continue_highlighted() -> void:
	var menu := _save_menu()
	assert_array(menu.choices).is_equal([C.CONTINUE, C.NEW_GAME, C.SETTINGS, C.QUIT])
	assert_int(menu.highlighted).is_equal(C.CONTINUE)

func test_three_choices_wrap() -> void:
	var menu := _save_menu()
	menu.move(-1)
	assert_int(menu.highlighted).is_equal(C.QUIT)
	menu.move(1)
	assert_int(menu.highlighted).is_equal(C.CONTINUE)
	menu.move(1)
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)

func test_continue_that_opens_locks() -> void:
	var menu := _save_menu()
	assert_int(menu.pick(C.CONTINUE)).is_equal(A.CONTINUE)
	assert_bool(menu.locked).is_true()
	assert_int(menu.box).is_equal(TitleMenu.Box.NONE)

func test_new_game_with_save_opens_the_start_over_box() -> void:
	var menu := _save_menu()
	assert_int(menu.pick(C.NEW_GAME)).is_equal(A.NONE)
	assert_int(menu.box).is_equal(TitleMenu.Box.START_OVER)
	assert_int(menu.box_selected).is_equal(B.KEEP_MY_ISLAND)
	assert_bool(menu.locked).is_false()
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)

func test_menu_ignored_while_a_box_is_open() -> void:
	var menu := _start_over_open()
	menu.move(1)
	menu.hover(C.QUIT)
	assert_int(menu.pick(C.QUIT)).is_equal(A.NONE)
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)
	assert_int(menu.box).is_equal(TitleMenu.Box.START_OVER)

func test_select_box() -> void:
	var menu := _start_over_open()
	menu.select_box(B.START_OVER)
	assert_int(menu.box_selected).is_equal(B.START_OVER)
	menu.select_box(B.CANCEL)
	assert_int(menu.box_selected).is_equal(B.START_OVER)
	var closed := _save_menu()
	closed.select_box(B.START_OVER)
	assert_int(closed.box_selected).is_equal(B.KEEP_MY_ISLAND)

func _assert_kept(menu: TitleMenu, action: TitleMenu.Action) -> void:
	assert_int(action).is_equal(A.NONE)
	assert_int(menu.box).is_equal(TitleMenu.Box.NONE)
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)
	assert_bool(menu.locked).is_false()

func test_keep_my_island() -> void:
	var menu := _start_over_open()
	_assert_kept(menu, menu.press_box(B.KEEP_MY_ISLAND))

func test_cancel_start_over_box_keeps() -> void:
	var menu := _start_over_open()
	menu.select_box(B.START_OVER)
	_assert_kept(menu, menu.cancel_box())

func test_start_over_starts_a_new_game() -> void:
	var menu := _start_over_open()
	assert_int(menu.press_box(B.START_OVER)).is_equal(A.NEW_GAME)
	assert_int(menu.box).is_equal(TitleMenu.Box.NONE)
	assert_bool(menu.locked).is_true()

func test_box_buttons_outside_their_box_ignored() -> void:
	var menu := _replace_open()
	assert_int(menu.press_box(B.KEEP_MY_ISLAND)).is_equal(A.NONE)
	assert_int(menu.box).is_equal(TitleMenu.Box.REPLACE)
	assert_bool(menu.locked).is_false()
	var closed := _save_menu()
	assert_int(closed.press_box(B.CANCEL)).is_equal(A.NONE)
	assert_int(closed.cancel_box()).is_equal(A.NONE)
	assert_int(closed.highlighted).is_equal(C.CONTINUE)

func _dimmed_menu() -> TitleMenu:
	return TitleMenu.new(true, false)

func _replace_open() -> TitleMenu:
	var menu := _dimmed_menu()
	menu.pick(C.NEW_GAME)
	return menu

func test_unreadable_save_dims_continue() -> void:
	var menu := _dimmed_menu()
	assert_bool(menu.continue_dimmed).is_true()
	assert_array(menu.choices).is_equal([C.CONTINUE, C.NEW_GAME, C.SETTINGS, C.QUIT])
	assert_array(menu.selectable()).is_equal([C.NEW_GAME, C.SETTINGS, C.QUIT])
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)
	assert_bool(TitleMenu.new(true, true).continue_dimmed).is_false()
	assert_bool(TitleMenu.new().continue_dimmed).is_false()

func test_dimmed_continue_is_skipped() -> void:
	var menu := _dimmed_menu()
	menu.move(-1)
	assert_int(menu.highlighted).is_equal(C.QUIT)
	menu.move(-1)
	assert_int(menu.highlighted).is_equal(C.SETTINGS)
	menu.move(1)
	assert_int(menu.highlighted).is_equal(C.QUIT)
	menu.move(1)
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)

func test_dimmed_continue_ignores_hover_and_pick() -> void:
	var menu := _dimmed_menu()
	menu.hover(C.CONTINUE)
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)
	assert_int(menu.pick(C.CONTINUE)).is_equal(A.NONE)
	assert_int(menu.box).is_equal(TitleMenu.Box.NONE)
	assert_bool(menu.locked).is_false()
	assert_int(menu.highlighted).is_equal(C.NEW_GAME)

func test_new_game_over_unreadable_save_opens_replace_box() -> void:
	var menu := _dimmed_menu()
	assert_int(menu.pick(C.NEW_GAME)).is_equal(A.NONE)
	assert_int(menu.box).is_equal(TitleMenu.Box.REPLACE)
	assert_int(menu.box_selected).is_equal(B.CANCEL)
	assert_bool(menu.locked).is_false()

func test_replace_box_select() -> void:
	var menu := _replace_open()
	menu.select_box(B.START_OVER)
	assert_int(menu.box_selected).is_equal(B.START_OVER)
	menu.select_box(B.KEEP_MY_ISLAND)
	assert_int(menu.box_selected).is_equal(B.START_OVER)
	menu.select_box(B.CANCEL)
	assert_int(menu.box_selected).is_equal(B.CANCEL)

func test_replace_box_cancel() -> void:
	var menu := _replace_open()
	_assert_kept(menu, menu.press_box(B.CANCEL))
	menu.pick(C.NEW_GAME)
	menu.select_box(B.START_OVER)
	_assert_kept(menu, menu.cancel_box())

func test_replace_box_start_over() -> void:
	var menu := _replace_open()
	assert_int(menu.press_box(B.START_OVER)).is_equal(A.NEW_GAME)
	assert_int(menu.box).is_equal(TitleMenu.Box.NONE)
	assert_bool(menu.locked).is_true()

func test_readable_save_still_opens_start_over_box() -> void:
	var menu := TitleMenu.new(true, true)
	menu.pick(C.NEW_GAME)
	assert_int(menu.box).is_equal(TitleMenu.Box.START_OVER)
	assert_int(menu.box_selected).is_equal(B.KEEP_MY_ISLAND)

func test_pick_settings_opens_and_blocks_the_menu() -> void:
	var menu := TitleMenu.new()
	assert_int(menu.pick(C.SETTINGS)).is_equal(A.OPEN_SETTINGS)
	assert_bool(menu.settings_open).is_true()
	assert_bool(menu.locked).is_false()
	menu.move(1)
	menu.hover(C.QUIT)
	assert_int(menu.pick(C.QUIT)).is_equal(A.NONE)
	assert_int(menu.highlighted).is_equal(C.SETTINGS)

func test_close_settings_highlights_settings() -> void:
	var menu := TitleMenu.new()
	menu.pick(C.SETTINGS)
	menu.close_settings()
	assert_bool(menu.settings_open).is_false()
	assert_int(menu.highlighted).is_equal(C.SETTINGS)
	menu.move(1)
	assert_int(menu.highlighted).is_equal(C.QUIT)
