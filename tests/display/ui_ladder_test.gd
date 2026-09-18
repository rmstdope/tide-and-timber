extends GdUnitTestSuite

# Over a 640x360 picture in the default 1280x720 window, the three UI size steps are half,
# three-quarters and exactly the on-screen size the game had at 320x180 (tr-1o0.1).

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.size = Vector2i(1280, 720)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode

func test_the_three_steps_are_half_three_quarters_and_todays_size() -> void:
	var root := get_tree().root
	assert_int(OverlayScale.whole_scale(root)).is_equal(2)
	var prefs := DisplayPrefs.new()
	var want := {DisplayPrefs.Size.NORMAL: 1.0, DisplayPrefs.Size.LARGE: 1.5, DisplayPrefs.Size.LARGEST: 2.0}
	for size: DisplayPrefs.Size in want:
		prefs.ui_size = size
		assert_float(UiScale.current(prefs, root)).override_failure_message(str(size)).is_equal(want[size])
