extends GdUnitTestSuite
## The build list's words grow with Text size: the list grows with them and stacks from the grown row.
##
## At 640x360 the list stacks only at UI Largest and Text Largest (its grown side-by-side width, 350,
## drawn 2x, is wider than Screen.WIDTH); UI size alone never stacks it (206 * 2 fits). The stacked list
## there is 262 wide, well inside the picture, so no combination wraps a line: wrapping was retired in
## tr-1o0.1.

const HIM := Vector2(100, 150)

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var _menu: BuildMenu

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _open(ui_size: int, text_size: int, window := Vector2i(1280, 720)) -> BuildList:
	get_tree().root.size = window
	var p := DisplayPrefs.new()
	p.step(DisplayPrefs.Setting.UI_SIZE, ui_size)
	p.step(DisplayPrefs.Setting.TEXT_SIZE, text_size)
	Display.use_prefs(p)
	var list := auto_free(BuildList.new()) as BuildList
	add_child(list)
	_menu = BuildMenu.new()
	_menu.set_state(8, false, false)
	_menu.open()
	list.place_beside(HIM)
	list.show_menu(_menu)
	return list

func test_text_large_widens_the_side_by_side_list() -> void:
	var list := _open(0, 1)
	assert_bool(list.stacked).is_false()
	assert_vector(list.size).is_equal(Vector2(270, 63))
	assert_vector(list.rows[0].position).is_equal(Vector2(8, 23))
	assert_vector(list.rows[1].position).is_equal(Vector2(8, 40))
	assert_vector(list.rows[0].size).is_equal(Vector2(254, 15))
	assert_vector(list.rows[1].size).is_equal(Vector2(254, 15))
	assert_vector(list.title_label.scale).is_equal(Vector2(1.5, 1.5))
	assert_vector(list.name_labels[0].scale).is_equal(Vector2(1.5, 1.5))
	assert_float(list.name_labels[0].size.x * 1.5).is_equal_approx(248.0, 0.01)
	assert_vector(list.cost_labels[0].position).is_equal(Vector2(0, 2))
	assert_int(list.cost_labels[0].horizontal_alignment).is_equal(HORIZONTAL_ALIGNMENT_RIGHT)
	assert_vector(list.position).is_equal(BuildList.top_left_for(HIM, 1.0, Vector2(270, 63)))

func test_text_normal_is_exactly_as_today() -> void:
	for ui_size in 3:
		var list := _open(ui_size, 0)
		var stacked := false     # UI size alone never stacks it: 206 * 2 < Screen.WIDTH
		assert_bool(list.stacked).is_equal(stacked)
		assert_vector(list.size).is_equal(BuildList.STACKED_SIZE if stacked else BuildList.SIZE)
		for i in BuildMenu.LINE_COUNT:
			var top: int = (BuildList.STACKED_ROW_TOP if stacked else BuildList.ROW_TOP)[i]
			assert_vector(list.rows[i].size).is_equal(
					BuildList.STACKED_ROW_SIZE if stacked else BuildList.ROW_SIZE)
			assert_vector(list.rows[i].position).is_equal(Vector2(BuildList.EDGE, top))
			assert_vector(list.name_labels[i].position).is_equal(Vector2(3, 2))
			assert_vector(list.cost_labels[i].position).is_equal(
					Vector2(3, 11) if stacked else Vector2(0, 2))
			assert_int(list.cost_labels[i].horizontal_alignment).is_equal(
					HORIZONTAL_ALIGNMENT_LEFT if stacked else HORIZONTAL_ALIGNMENT_RIGHT)
			assert_vector(list.name_labels[i].scale).is_equal(Vector2.ONE)
			assert_vector(list.cost_labels[i].scale).is_equal(Vector2.ONE)
		assert_vector(list.title_label.scale).is_equal(Vector2.ONE)
		remove_child(list)

func test_text_largest_stacks_and_widens() -> void:
	var list := _open(2, 2)
	assert_bool(list.stacked).is_true()
	assert_vector(list.size).is_equal(Vector2(262, 111))
	for i in BuildMenu.LINE_COUNT:
		assert_vector(list.rows[i].size).is_equal(Vector2(246, 37))
		assert_vector(list.cost_labels[i].position).is_equal(Vector2(3, 19))
		assert_int(list.cost_labels[i].horizontal_alignment).is_equal(HORIZONTAL_ALIGNMENT_LEFT)
	assert_float(list.rows[0].position.y).is_equal(27.0)
	assert_float(list.rows[1].position.y).is_equal(66.0)
	assert_int(list.cost_labels[1].autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_str(list.cost_labels[1].text).is_equal("Needs a lean-to")
	assert_vector(list.title_label.scale).is_equal(Vector2(2, 2))

func test_no_word_runs_past_the_list() -> void:
	for ui_size in 3:
		for text_size in 3:
			var list := _open(ui_size, text_size)
			var rel: float = list.name_labels[0].scale.x
			for i in BuildMenu.LINE_COUNT:
				for label: Label in [list.name_labels[i], list.cost_labels[i]]:
					for word in label.text.split(" ", false):
						var w: float = label.get_theme_font(&"font").get_string_size(
								word, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x * rel
						assert_float(w).is_less_equal(list.size.x - BuildList.WORDS_INSET)
			remove_child(list)

func test_a_text_size_change_relays_out_at_once() -> void:
	var list := _open(2, 0)
	assert_bool(list.stacked).is_false()
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	assert_bool(list.stacked).is_true()
	assert_vector(list.size).is_equal(Vector2(262, 111))
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, -2)
	assert_bool(list.stacked).is_false()
	assert_vector(list.size).is_equal(BuildList.SIZE)
	assert_vector(list.title_label.scale).is_equal(Vector2.ONE)
	assert_vector(list.name_labels[0].scale).is_equal(Vector2.ONE)

func test_the_highlight_keeps_its_row_when_text_grows() -> void:
	var list := _open(2, 0)
	_menu.move(1)
	assert_int(_menu.highlighted).is_equal(1)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	assert_bool(list.stacked).is_true()
	assert_int(_menu.highlighted).is_equal(1)
	assert_float(list.rows[1].position.y).is_equal(66.0)

func test_side_by_side_width_grows_with_the_words() -> void:
	var list := _open(0, 0)
	assert_float(list.side_by_side_width()).is_equal(206.0)
	assert_float(list.side_by_side_width(1.5)).is_equal(270.0)
	assert_float(list.side_by_side_width(2.0)).is_equal(350.0)

func test_a_small_window_still_fits() -> void:
	var list := _open(2, 2, Screen.MIN_WINDOW)
	assert_bool(list.stacked).is_true()
	assert_vector(list.size).is_equal(Vector2(262, 111))
	assert_float(list.position.x).is_greater_equal(0.0)
	assert_float(list.position.x + list.size.x * list.scale.x).is_less_equal(Screen.WIDTH)
