extends GdUnitTestSuite
## The pause board, the settings board and the Debug panel wear the one shared knobbed frame.

func _scene(path: String) -> Node:
	return auto_free((load(path) as PackedScene).instantiate())

func test_the_pause_board_wears_the_frame() -> void:
	var panel := _scene("res://src/pause/pause.tscn").get_node("Board/Panel") as Control
	assert_bool(is_same(panel.get_theme_stylebox(&"panel"), HudFrame.STYLE)).is_true()

func test_the_settings_board_wears_the_frame() -> void:
	var panel := _scene("res://src/settings/settings_board.tscn").get_node("Panel") as Control
	assert_bool(is_same(panel.get_theme_stylebox(&"panel"), HudFrame.STYLE)).is_true()

func test_the_debug_panel_wears_the_frame() -> void:
	assert_bool(is_same(DebugPanel.BOARD_STYLE, HudFrame.STYLE)).is_true()

func test_the_quit_box_shares_the_one_frame() -> void:
	# tr-1ci.5 framed it; both boards in the scene read the one frame resource.
	var panel := _scene("res://src/pause/pause.tscn").get_node("Board/QuitBox/Panel") as Control
	assert_bool(is_same(panel.get_theme_stylebox(&"panel"), HudFrame.STYLE)).is_true()

func test_the_dev_tag_sits_inside_the_rim_level_with_the_heading() -> void:
	assert_float(Pause.DEV_TAG_RIGHT).is_equal(HudFrame.RIM + 16.0)
	assert_float(Pause.DEV_TAG_TOP).is_equal(Pause.HEADING_TOP)
	var tag := _scene("res://src/pause/pause.tscn").get_node("Board/Panel/DevTag") as Control
	assert_that(tag.get_rect()).is_equal(Rect2(122, 8, 16, 7))
	assert_bool(Rect2(0, 0, 144, 96).grow(-HudFrame.RIM).encloses(tag.get_rect())).is_true()
