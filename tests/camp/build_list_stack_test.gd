extends GdUnitTestSuite
## Build list rows show their cost under their name when the list would be wider than the screen.

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

func _open(ui_size: int, window: Vector2i) -> BuildList:
	get_tree().root.size = window
	var p := DisplayPrefs.new()
	p.step(DisplayPrefs.Setting.UI_SIZE, ui_size)
	Display.use_prefs(p)
	var list := auto_free(BuildList.new()) as BuildList
	add_child(list)
	_menu = BuildMenu.new()
	_menu.set_state(8, false, false)
	_menu.open()
	list.place_beside(HIM)
	list.show_menu(_menu)
	return list

func test_normal_is_side_by_side() -> void:
	var list := _open(0, Vector2i(2560, 1440))
	assert_bool(list.stacked).is_false()
	assert_vector(list.size).is_equal(BuildList.SIZE)
	assert_vector(list.scale).is_equal(Vector2.ONE)
	assert_vector(list.rows[1].position).is_equal(Vector2(3, 27))
	assert_vector(list.position).is_equal(Vector2(112, 81))

func test_largest_stacks_every_row() -> void:
	var list := _open(2, Vector2i(2560, 1440))
	assert_bool(list.stacked).is_true()
	assert_vector(list.size).is_equal(BuildList.STACKED_SIZE)
	assert_vector(list.scale).is_equal(Vector2(2, 2))
	for i in BuildMenu.LINE_COUNT:
		assert_vector(list.rows[i].size).is_equal(BuildList.STACKED_ROW_SIZE)
		assert_vector(list.name_labels[i].position).is_equal(Vector2(3, 2))
		assert_vector(list.cost_labels[i].position).is_equal(Vector2(3, 11))
		assert_int(list.cost_labels[i].horizontal_alignment).is_equal(HORIZONTAL_ALIGNMENT_LEFT)
	assert_vector(list.rows[0].position).is_equal(Vector2(3, 14))
	assert_vector(list.rows[1].position).is_equal(Vector2(3, 37))
	assert_vector(list.position).is_equal(Vector2(16, 2))
	assert_float(list.position.x + list.size.x * 2).is_less_equal(316)
	assert_str(list.cost_labels[1].text).is_equal("Needs a lean-to")

func test_large_in_a_big_window_stays_side_by_side() -> void:
	var list := _open(1, Vector2i(2560, 1440))
	assert_bool(list.stacked).is_false()
	assert_vector(list.scale).is_equal(Vector2(1.5, 1.5))
	assert_vector(list.size).is_equal(BuildList.SIZE)
	assert_vector(list.cost_labels[0].position).is_equal(Vector2(0, 2))
	assert_int(list.cost_labels[0].horizontal_alignment).is_equal(HORIZONTAL_ALIGNMENT_RIGHT)

func test_large_stacks_where_the_window_rounds_it_to_twice() -> void:
	var list := _open(1, Vector2i(1280, 720))
	assert_vector(list.scale).is_equal(Vector2(2, 2))
	assert_bool(list.stacked).is_true()

func test_a_size_change_restacks_at_once_highlight_unmoved() -> void:
	var list := _open(2, Vector2i(2560, 1440))
	_menu.move(1)
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, -1)
	assert_bool(list.stacked).is_false()
	assert_vector(list.size).is_equal(BuildList.SIZE)
	assert_vector(list.position).is_equal(BuildList.top_left_for(HIM, 1.5))
	assert_int(_menu.highlighted).is_equal(1)
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	assert_bool(list.stacked).is_true()
	assert_vector(list.position).is_equal(Vector2(16, 2))
	assert_int(_menu.highlighted).is_equal(1)

func test_a_window_resize_restacks() -> void:
	var list := _open(1, Vector2i(2560, 1440))
	get_tree().root.size = Vector2i(1280, 720)
	assert_bool(list.stacked).is_true()
	get_tree().root.size = Vector2i(2560, 1440)
	assert_bool(list.stacked).is_false()

func test_side_by_side_width_is_the_list_width_for_todays_words() -> void:
	var list := _open(0, Vector2i(2560, 1440))
	assert_float(list.side_by_side_width()).is_equal(196.0)
	_menu.set_state(0, true, true)
	list.show_menu(_menu)
	assert_float(list.side_by_side_width()).is_equal(196.0)

func test_one_row_too_wide_stacks_both() -> void:
	var list := _open(1, Vector2i(2560, 1440))
	list.cost_labels[0].text = "W".repeat(40)
	list.place_beside(HIM)
	assert_float(list.side_by_side_width()).is_greater(196.0)
	assert_bool(list.stacked).is_true()
	assert_vector(list.rows[1].size).is_equal(BuildList.STACKED_ROW_SIZE)
