extends GdUnitTestSuite

func test_starts_on_new_game_unlocked() -> void:
	var menu := TitleMenu.new()
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
	assert_bool(menu.locked).is_false()

func test_move_down_then_wraps() -> void:
	var menu := TitleMenu.new()
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
	assert_bool(menu.pick(TitleMenu.Choice.NEW_GAME)).is_true()
	assert_bool(menu.locked).is_true()
	menu.move(1)
	menu.hover(TitleMenu.Choice.QUIT)
	assert_bool(menu.pick(TitleMenu.Choice.QUIT)).is_false()
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
	assert_bool(menu.locked).is_true()

func test_pick_quit_does_not_lock() -> void:
	var menu := TitleMenu.new()
	assert_bool(menu.pick(TitleMenu.Choice.QUIT)).is_true()
	assert_int(menu.highlighted).is_equal(TitleMenu.Choice.QUIT)
	assert_bool(menu.locked).is_false()
