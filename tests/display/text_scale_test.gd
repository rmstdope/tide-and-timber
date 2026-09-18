extends GdUnitTestSuite
## The words' scale: UI size times Text size, and the width a line takes once its words have grown.

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

func _step(s: DisplayPrefs.Setting, n: int) -> void:
	Display.prefs.step(s, n)

func test_total_multiplies_ui_and_text() -> void:
	var root := get_tree().root
	assert_float(TextScale.total(Display.prefs, root)).is_equal(1.0)
	_step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	assert_float(TextScale.total(Display.prefs, root)).is_equal(1.5)
	_step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	assert_float(TextScale.total(Display.prefs, root)).is_equal(2.0)
	Display.use_prefs(DisplayPrefs.new())
	_step(DisplayPrefs.Setting.UI_SIZE, 1)
	_step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	assert_float(TextScale.total(Display.prefs, root)).is_equal(2.5)
	_step(DisplayPrefs.Setting.UI_SIZE, 1)
	_step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	assert_float(TextScale.total(Display.prefs, root)).is_equal(4.0)

func test_relative_is_one_at_text_normal() -> void:
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(640, 360)]:
		for n in 3:
			Display.use_prefs(DisplayPrefs.new())
			get_tree().root.size = size
			_step(DisplayPrefs.Setting.UI_SIZE, n)
			assert_float(TextScale.relative(Display.prefs, get_tree().root)).is_equal(1.0)

func test_relative_divides_out_ui() -> void:
	var root := get_tree().root
	_step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	assert_float(TextScale.relative(Display.prefs, root)).is_equal(1.5)
	_step(DisplayPrefs.Setting.UI_SIZE, 1)
	assert_float(TextScale.relative(Display.prefs, root)).is_equal_approx(5.0 / 3.0, 0.0001)
	_step(DisplayPrefs.Setting.UI_SIZE, 1)
	_step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	assert_float(TextScale.relative(Display.prefs, root)).is_equal(2.0)
	Display.use_prefs(DisplayPrefs.new())
	root.size = Vector2i(640, 360)
	_step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	assert_float(TextScale.relative(Display.prefs, root)).is_equal(2.0)

func test_fit_width_widens_then_narrows() -> void:
	var room := Screen.WIDTH - 2.0 * SpokenLine.SCREEN_MARGIN   # the widest a line may be, unscaled
	assert_float(TextScale.fit_width(296, 0, 1.0)).is_equal(296.0)
	assert_float(TextScale.fit_width(296, room, 1.0)).is_equal(room)
	assert_float(TextScale.fit_width(296, Screen.WIDTH + 124, 1.0)).is_equal(room)
	assert_float(TextScale.fit_width(296, Screen.WIDTH / 2.0 + 48, 2.0)).is_equal(floorf(room / 2.0))
	assert_float(TextScale.fit_width(Screen.WIDTH, Screen.WIDTH, 1.0)).is_equal(Screen.WIDTH)
	assert_float(TextScale.fit_width(296, 440, 1.5)).is_equal(floorf(room / 1.5))   # 440 * 1.5 > WIDTH

func test_fit_width_equals_width_at_when_words_fit() -> void:
	for s: float in [1.0, 1.5, 2.0, 5.0 / 3.0]:
		assert_float(TextScale.fit_width(296, 100, s)).is_equal(SpokenLine.width_at(296, s))

func test_extra_is_whole_units() -> void:
	assert_float(TextScale.extra(9, 1.0)).is_equal_approx(0.0, 0.01)
	assert_float(TextScale.extra(9, 1.5)).is_equal_approx(5.0, 0.01)
	assert_float(TextScale.extra(9, 2.0)).is_equal_approx(9.0, 0.01)
	assert_float(TextScale.extra(9, 5.0 / 3.0)).is_equal_approx(6.0, 0.01)
	assert_float(TextScale.extra(8, 1.5)).is_equal_approx(4.0, 0.01)
	assert_float(TextScale.extra(8, 2.0)).is_equal_approx(8.0, 0.01)
	assert_float(TextScale.extra(8, 5.0 / 3.0)).is_equal_approx(6.0, 0.01)
