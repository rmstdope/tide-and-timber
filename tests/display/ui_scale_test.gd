extends GdUnitTestSuite

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func test_multiplier_for_each_size() -> void:
	assert_float(UiScale.multiplier_for(DisplayPrefs.Size.NORMAL)).is_equal(1.0)
	assert_float(UiScale.multiplier_for(DisplayPrefs.Size.LARGE)).is_equal(1.5)
	assert_float(UiScale.multiplier_for(DisplayPrefs.Size.LARGEST)).is_equal(2.0)

func test_current_rounds_with_the_window() -> void:
	var root := get_tree().root
	var p := DisplayPrefs.new()
	root.size = Vector2i(1280, 720)
	assert_float(UiScale.current(p, root)).is_equal(1.0)
	p.step(DisplayPrefs.Setting.UI_SIZE, 1)
	assert_float(UiScale.current(p, root)).is_equal(1.5)
	root.size = Vector2i(640, 360)
	assert_float(UiScale.current(p, root)).is_equal(2.0)
	root.size = Vector2i(1920, 1080)
	assert_float(UiScale.current(p, root)).is_equal_approx(5.0 / 3.0, 0.0001)
	root.size = Vector2i(1280, 720)
	p.step(DisplayPrefs.Setting.UI_SIZE, 1)
	assert_float(UiScale.current(p, root)).is_equal(2.0)

func _layer() -> CanvasLayer:
	var layer := CanvasLayer.new()
	var scaler: UiScale = UiScale.new()
	scaler.anchor = Vector2(160, 180)
	layer.add_child(scaler)
	add_child(layer)
	auto_free(layer)
	return layer

func test_follows_display_changed() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	var layer := _layer()
	assert_bool(layer.transform == Transform2D.IDENTITY).is_true()
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	assert_bool(layer.transform.is_equal_approx(OverlayScale.layer_transform(1.5, Vector2(160, 180)))).is_true()
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	assert_bool(layer.transform.is_equal_approx(OverlayScale.layer_transform(2.0, Vector2(160, 180)))).is_true()
	Display.use_prefs(DisplayPrefs.new())
	assert_bool(layer.transform == Transform2D.IDENTITY).is_true()

func test_follows_the_window() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	var layer := _layer()
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	get_tree().root.size = Vector2i(640, 360)
	assert_float(layer.transform.get_scale().x).is_equal(2.0)
