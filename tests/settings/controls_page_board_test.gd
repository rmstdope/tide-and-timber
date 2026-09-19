extends GdUnitTestSuite
## The Controls page sits on the shared knobbed board, paints no background, and clips its content under everything else.

const PATH := "res://src/settings/controls_page.tscn"

func _page() -> Control:
	return auto_free((load(PATH) as PackedScene).instantiate())

func test_the_board_wears_the_frame() -> void:
	assert_bool(is_same(ControlsPage.BOARD_STYLE, HudFrame.STYLE)).is_true()

func test_the_page_paints_no_background() -> void:
	assert_bool((load("res://src/settings/controls_page.gd") as GDScript).get_script_constant_map().has("BACKGROUND")).is_false()

func test_the_view_clips_under_everything() -> void:
	var root := _page()
	assert_that(root.get_child(0).name).is_equal(&"View")
	var view := root.get_node("%View") as Control
	var content := root.get_node("%ViewContent") as Control
	assert_bool(view.clip_contents).is_true()
	assert_int(view.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_int(content.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_bool(content.get_parent() == view).is_true()
