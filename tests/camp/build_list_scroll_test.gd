extends GdUnitTestSuite
## A build list taller than the room above its hint is framed to fit and scrolls to the highlight.
##
## At 640x360 the list stacks only at UI Largest and Text Largest (1280x720), and there it is 252 x 101
## drawn 2x: 202 tall, while the real build hint's top never rises above Screen.HEIGHT - 90 (lifted over
## the grown bar, its words 2x). No player combination makes the list scroll, so the scrolling tests
## below fail on their precondition until the navigator decides what becomes of this layout.

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

func _open(ui_size: int, window: Vector2i, text_size := 0) -> BuildList:
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

## A stand-in build hint whose on-screen top is `top`, bounding the list from below.
func _hint(list: BuildList, top: float) -> Control:
	var h := auto_free(Control.new()) as Control
	add_child(h)
	h.position = Vector2(0, top)
	h.size = Vector2(10, 24)
	list.use_hint(h)
	return h

func _visible(list: BuildList, i: int) -> bool:
	return list.clip.get_global_rect().encloses(list.rows[i].get_global_rect())

func _show(list: BuildList) -> void:
	list.show_menu(_menu)

func test_largest_above_a_lifted_hint_scrolls_from_the_top() -> void:
	var list := _open(2, Vector2i(1280, 720))
	_hint(list, 108)
	assert_bool(list.scrolls).is_true()
	assert_int(list.offset).is_equal(0)
	assert_vector(list.position).is_equal(Vector2(16, 2))
	assert_vector(list.size).is_equal(Vector2(150, 52))
	assert_vector(list.scale).is_equal(Vector2(2, 2))
	assert_object(list.clip.get_rect()).is_equal(Rect2(0, 10, 150, 32))
	assert_vector(list.content.position).is_equal(Vector2(0, -3))
	assert_vector(list.content.size).is_equal(BuildList.STACKED_SIZE)
	assert_bool(list.shows_mark_above()).is_false()
	assert_bool(list.shows_mark_below()).is_true()
	assert_bool(_visible(list, 0)).is_true()
	assert_vector(list.rows[1].position).is_equal(Vector2(3, 37))

func test_moving_scrolls_to_the_highlight_and_back() -> void:
	var list := _open(2, Vector2i(1280, 720))
	_hint(list, 108)
	assert_bool(list.scrolls).is_true()
	_menu.move(1)
	_show(list)
	assert_int(_menu.highlighted).is_equal(1)
	assert_int(list.offset).is_equal(23)
	assert_vector(list.content.position).is_equal(Vector2(0, -26))
	assert_bool(list.shows_mark_above()).is_true()
	assert_bool(list.shows_mark_below()).is_false()
	assert_bool(_visible(list, 1)).is_true()
	_menu.move(-1)
	_show(list)
	assert_int(list.offset).is_equal(0)
	assert_bool(list.shows_mark_above()).is_false()
	assert_bool(list.shows_mark_below()).is_true()

func test_hovered_row_scrolls_into_view() -> void:
	var list := _open(2, Vector2i(1280, 720))
	_hint(list, 108)
	assert_bool(list.scrolls).is_true()
	_menu.hover(BuildMenu.Thing.FIRE)
	_show(list)
	assert_int(list.offset).is_equal(23)
	assert_bool(_visible(list, 1)).is_true()

func test_opening_again_starts_at_the_top() -> void:
	var list := _open(2, Vector2i(1280, 720))
	_hint(list, 108)
	assert_bool(list.scrolls).is_true()
	_menu.move(1)
	_show(list)
	assert_int(list.offset).is_equal(23)
	_menu.set_state(0, false, false)
	_menu.open()
	assert_int(_menu.highlighted).is_equal(-1)
	list.place_beside(HIM)
	_show(list)
	assert_int(list.offset).is_equal(0)
	assert_bool(list.shows_mark_above()).is_false()
	assert_bool(list.shows_mark_below()).is_true()

func test_no_highlight_keeps_the_offset() -> void:
	var list := _open(2, Vector2i(1280, 720))
	_hint(list, 108)
	assert_bool(list.scrolls).is_true()
	_menu.move(1)
	_show(list)
	assert_int(list.offset).is_equal(23)
	_menu.highlighted = -1
	_show(list)
	assert_int(list.offset).is_equal(23)

func test_fits_below_a_low_hint_exactly_as_before() -> void:
	var list := _open(2, Vector2i(1280, 720), 2)
	assert_bool(list.stacked).is_true()
	# the hint at its unlifted Normal top: the 202-tall list fits the room above it
	_hint(list, KeyHint.TOP)
	assert_bool(list.scrolls).is_false()
	assert_int(list.offset).is_equal(0)
	assert_vector(list.size).is_equal(list.list_size())
	assert_vector(list.list_size()).is_equal(Vector2(252, 101))
	# 100 + RIGHT_OF_HIM fits; 150 - ABOVE_HIM - 202 is above the picture, so held at 2
	assert_vector(list.position).is_equal(Vector2(112, 2))
	assert_object(list.clip.get_rect()).is_equal(Rect2(Vector2.ZERO, list.list_size()))
	assert_vector(list.content.position).is_equal(Vector2.ZERO)
	assert_bool(list.shows_mark_above()).is_false()
	assert_bool(list.shows_mark_below()).is_false()

func test_normal_fits_exactly_as_before() -> void:
	var list := _open(0, Vector2i(1280, 720))
	_hint(list, 136)
	assert_bool(list.scrolls).is_false()
	assert_vector(list.size).is_equal(BuildList.SIZE)
	assert_vector(list.position).is_equal(Vector2(112, 81))
	assert_object(list.clip.get_rect()).is_equal(Rect2(Vector2.ZERO, BuildList.SIZE))

func test_a_hint_that_moves_or_hides_reframes() -> void:
	var list := _open(2, Vector2i(1280, 720))
	var h := _hint(list, 164)
	assert_bool(list.scrolls).is_false()
	h.position.y = 108
	assert_bool(list.scrolls).is_true()
	assert_vector(list.size).is_equal(Vector2(150, 52))
	h.hide()
	assert_bool(list.scrolls).is_false()
	assert_vector(list.size).is_equal(BuildList.STACKED_SIZE)
	h.show()
	assert_bool(list.scrolls).is_true()

func test_size_change_refollows() -> void:
	var list := _open(2, Vector2i(1280, 720))
	_hint(list, 108)
	assert_bool(list.scrolls).is_true()
	_menu.move(1)
	_show(list)
	assert_int(list.offset).is_equal(23)
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, -1)
	assert_bool(list.stacked).is_false()
	assert_bool(list.scrolls).is_false()
	assert_int(list.offset).is_equal(0)
	assert_vector(list.size).is_equal(BuildList.SIZE)
	assert_int(_menu.highlighted).is_equal(1)
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	assert_bool(list.scrolls).is_true()
	assert_int(list.offset).is_equal(23)
	assert_bool(_visible(list, 1)).is_true()

func test_rows_are_clipped() -> void:
	var list := _open(0, Vector2i(1280, 720))
	assert_bool(list.clip.clip_contents).is_true()
	assert_int(list.clip.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_int(list.content.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_bool(list.clip.is_ancestor_of(list.title_label)).is_true()
	for i in BuildMenu.LINE_COUNT:
		assert_bool(list.clip.is_ancestor_of(list.rows[i])).is_true()
	assert_object(list.content.get_parent()).is_equal(list.clip)

func test_without_a_hint_the_screen_bottom_bounds_it() -> void:
	var list := _open(2, Vector2i(1280, 720), 2)
	assert_bool(list.stacked).is_true()
	assert_bool(list.scrolls).is_false()
	assert_vector(list.size).is_equal(Vector2(252, 101))
