extends GdUnitTestSuite
## The build list's words grow with Text size: the list grows with them, stacks from the grown row,
## and a stacked line too wide for the list wraps between words.

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

func _open(ui_size: int, text_size: int, window := Vector2i(640, 360)) -> BuildList:
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
	assert_vector(list.size).is_equal(Vector2(260, 53))
	assert_vector(list.rows[0].position).is_equal(Vector2(3, 18))
	assert_vector(list.rows[1].position).is_equal(Vector2(3, 35))
	assert_vector(list.rows[0].size).is_equal(Vector2(254, 15))
	assert_vector(list.rows[1].size).is_equal(Vector2(254, 15))
	assert_vector(list.title_label.scale).is_equal(Vector2(1.5, 1.5))
	assert_vector(list.name_labels[0].scale).is_equal(Vector2(1.5, 1.5))
	assert_float(list.name_labels[0].size.x * 1.5).is_equal_approx(248.0, 0.01)
	assert_vector(list.cost_labels[0].position).is_equal(Vector2(0, 2))
	assert_int(list.cost_labels[0].horizontal_alignment).is_equal(HORIZONTAL_ALIGNMENT_RIGHT)
	assert_vector(list.position).is_equal(BuildList.top_left_for(HIM, 1.0, Vector2(260, 53)))

func test_text_normal_is_exactly_as_today() -> void:
	for ui_size in 3:
		var list := _open(ui_size, 0)
		var stacked: bool = ui_size == 2
		assert_bool(list.stacked).is_equal(stacked)
		assert_vector(list.size).is_equal(BuildList.STACKED_SIZE if stacked else BuildList.SIZE)
		for i in BuildMenu.LINE_COUNT:
			var top: int = (BuildList.STACKED_ROW_TOP if stacked else BuildList.ROW_TOP)[i]
			assert_vector(list.rows[i].size).is_equal(
					BuildList.STACKED_ROW_SIZE if stacked else BuildList.ROW_SIZE)
			assert_vector(list.rows[i].position).is_equal(Vector2(3, top))
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
	var list := _open(0, 2)
	assert_bool(list.stacked).is_true()
	assert_vector(list.size).is_equal(Vector2(252, 101))
	for i in BuildMenu.LINE_COUNT:
		assert_vector(list.rows[i].size).is_equal(Vector2(246, 37))
		assert_vector(list.cost_labels[i].position).is_equal(Vector2(3, 19))
		assert_int(list.cost_labels[i].horizontal_alignment).is_equal(HORIZONTAL_ALIGNMENT_LEFT)
	assert_float(list.rows[0].position.y).is_equal(22.0)
	assert_float(list.rows[1].position.y).is_equal(61.0)
	assert_int(list.cost_labels[1].autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_str(list.cost_labels[1].text).is_equal("Needs a lean-to")
	assert_vector(list.title_label.scale).is_equal(Vector2(2, 2))

func test_large_ui_and_large_text_stacks_without_wrapping() -> void:
	var list := _open(1, 1)
	assert_bool(list.stacked).is_true()
	assert_vector(list.size).is_equal(Vector2(212, 91))
	for i in BuildMenu.LINE_COUNT:
		assert_vector(list.rows[i].size).is_equal(Vector2(206, 33))
		assert_vector(list.cost_labels[i].position).is_equal(Vector2(3, 17))
		assert_int(list.cost_labels[i].autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
		assert_int(list.name_labels[i].autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_float(list.rows[0].position.y).is_equal(20.0)
	assert_float(list.rows[1].position.y).is_equal(55.0)
	assert_vector(list.scale).is_equal(Vector2(1.5, 1.5))

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
						assert_float(w).is_less_equal(list.size.x - 12.0)
			remove_child(list)

func test_a_text_size_change_relays_out_at_once() -> void:
	var list := _open(0, 0)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	assert_bool(list.stacked).is_true()
	assert_vector(list.size).is_equal(Vector2(252, 101))
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, -2)
	assert_bool(list.stacked).is_false()
	assert_vector(list.size).is_equal(BuildList.SIZE)
	assert_vector(list.title_label.scale).is_equal(Vector2.ONE)
	assert_vector(list.name_labels[0].scale).is_equal(Vector2.ONE)

func test_the_highlight_keeps_its_row_when_text_grows() -> void:
	var list := _open(0, 0)
	_menu.move(1)
	assert_int(_menu.highlighted).is_equal(1)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	assert_int(_menu.highlighted).is_equal(1)
	assert_float(list.rows[1].position.y).is_equal(61.0)

func test_side_by_side_width_grows_with_the_words() -> void:
	var list := _open(0, 0)
	assert_float(list.side_by_side_width()).is_equal(196.0)
	assert_float(list.side_by_side_width(1.5)).is_equal(260.0)
	assert_float(list.side_by_side_width(2.0)).is_equal(340.0)

func test_a_small_window_still_fits() -> void:
	var list := _open(0, 2, Vector2i(320, 180))
	assert_vector(list.size).is_equal(Vector2(252, 101))
	assert_float(list.position.x).is_greater_equal(0.0)
	assert_float(list.position.x + list.size.x).is_less_equal(320.0)

func test_largest_ui_and_text_wraps_the_cost() -> void:
	var list := _open(2, 2)
	assert_bool(list.stacked).is_true()
	# The grown list is taller than the screen at UI Largest, so frame() scrolls it and `size` is the
	# framed window; list_size() is the whole list.
	assert_vector(list.list_size()).is_equal(Vector2(156, 145))
	assert_bool(list.scrolls).is_true()
	assert_float(list.size.x).is_equal(156.0)
	for i in BuildMenu.LINE_COUNT:
		assert_vector(list.rows[i].size).is_equal(Vector2(150, 59))
		assert_vector(list.cost_labels[i].position).is_equal(Vector2(3, 19))
		assert_int(list.cost_labels[i].autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
		assert_int(list.name_labels[i].autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
		assert_float(list.cost_labels[i].size.x).is_equal(72.0)
	assert_float(list.rows[0].position.y).is_equal(22.0)
	assert_float(list.rows[1].position.y).is_equal(83.0)
	assert_float(list.position.x + list.size.x * 2.0).is_less_equal(316.0)

func test_largest_ui_and_large_text_wraps_the_cost() -> void:
	var list := _open(2, 1)
	assert_vector(list.list_size()).is_equal(Vector2(156, 115))
	for i in BuildMenu.LINE_COUNT:
		assert_vector(list.rows[i].size).is_equal(Vector2(150, 46))
		assert_vector(list.cost_labels[i].position).is_equal(Vector2(3, 15))
		assert_float(list.cost_labels[i].size.x).is_equal(96.0)
	assert_float(list.rows[0].position.y).is_equal(18.0)
	assert_float(list.rows[1].position.y).is_equal(66.0)

func test_large_ui_and_largest_text_wraps_the_cost() -> void:
	var list := _open(1, 2)
	assert_vector(list.list_size()).is_equal(Vector2(208, 145))
	for i in BuildMenu.LINE_COUNT:
		assert_float(list.cost_labels[i].size.x).is_equal(98.0)
	assert_float(list.position.x + list.size.x * 1.5).is_less_equal(316.0)

func test_wrapped_lines_never_breaks_a_word() -> void:
	var list := _open(0, 0)
	var label := list.cost_labels[0]
	assert_int(BuildList.wrapped_lines(label, "Needs a lean-to", 120.0)).is_equal(1)
	assert_int(BuildList.wrapped_lines(label, "Needs a lean-to", 72.0)).is_equal(2)
	# "Needs a" is exactly 56 wide, so it still fits; 48 is the width that forces a third line.
	assert_int(BuildList.wrapped_lines(label, "Needs a lean-to", 56.0)).is_equal(2)
	assert_int(BuildList.wrapped_lines(label, "Needs a lean-to", 48.0)).is_equal(3)
	assert_int(BuildList.wrapped_lines(label, "0/8 driftwood", 72.0)).is_equal(2)
	assert_int(BuildList.wrapped_lines(label, "driftwood", 72.0)).is_equal(1)
	assert_int(BuildList.wrapped_lines(label, "driftwood", 40.0)).is_equal(1)

func test_godot_wraps_where_we_counted() -> void:
	var list := _open(2, 2)
	await await_idle_frame()
	await await_idle_frame()
	for i in BuildMenu.LINE_COUNT:
		assert_int(list.cost_labels[i].get_line_count()).is_equal(
				BuildList.wrapped_lines(list.cost_labels[i], list.cost_labels[i].text, 72.0))
		assert_int(list.cost_labels[i].get_line_count()).is_equal(2)
		assert_int(list.name_labels[i].get_line_count()).is_equal(1)
