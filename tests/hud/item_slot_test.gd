extends GdUnitTestSuite
## An item count grows with Text size about the slot's bottom-right corner; the slot never grows.

const Setting := DisplayPrefs.Setting

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func test_count_rect_keeps_the_bottom_right_corner() -> void:
	for rel in [1.0, 1.5, 2.0, 5.0 / 3.0]:
		for text in ["3", "120"]:
			assert_vector(ItemSlot.count_rect(text, rel).end) \
				.is_equal_approx(Vector2(15, 15), Vector2(0.01, 0.01))

func test_count_rect_at_normal_is_todays_spot() -> void:
	assert_vector(ItemSlot.count_rect("3", 1.0).position).is_equal_approx(Vector2(12, 10), Vector2(0.01, 0.01))
	assert_vector(ItemSlot.count_rect("3", 1.0).size).is_equal_approx(Vector2(3, 5), Vector2(0.01, 0.01))
	assert_vector(ItemSlot.count_rect("120", 1.0).position).is_equal_approx(Vector2(4, 10), Vector2(0.01, 0.01))
	assert_vector(ItemSlot.count_rect("120", 1.0).size).is_equal_approx(Vector2(11, 5), Vector2(0.01, 0.01))

func test_grown_count_may_overhang_left_and_top() -> void:
	assert_vector(ItemSlot.count_rect("120", 2.0).position).is_equal_approx(Vector2(-7, 5), Vector2(0.01, 0.01))
	assert_vector(ItemSlot.count_rect("120", 2.0).size).is_equal_approx(Vector2(22, 10), Vector2(0.01, 0.01))

func test_slot_follows_text_size() -> void:
	var slot := auto_free(ItemSlot.new()) as ItemSlot
	add_child(slot)
	assert_float(slot.text_scale()).is_equal_approx(1.0, 0.01)
	Display.prefs.step(Setting.TEXT_SIZE, 2)
	assert_float(slot.text_scale()).is_equal_approx(2.0, 0.01)
	Display.prefs.step(Setting.UI_SIZE, 2)
	assert_float(slot.text_scale()).is_equal_approx(2.0, 0.01)
	Display.use_prefs(DisplayPrefs.new())
	assert_float(slot.text_scale()).is_equal_approx(1.0, 0.01)
	assert_vector(slot.size).is_equal_approx(Vector2(16, 16), Vector2(0.01, 0.01))
