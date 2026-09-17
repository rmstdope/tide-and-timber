extends GdUnitTestSuite

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

# The root resizes the way the project's stretch mode makes it: canvas_items, which also emits
# size_changed at once. Both are put back so no other suite sees them.
func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode

func test_factor_rounds_to_whole_screen_pixels() -> void:
	assert_float(OverlayScale.factor(1.0, 1)).is_equal(1.0)
	assert_float(OverlayScale.factor(1.5, 1)).is_equal(2.0)
	assert_float(OverlayScale.factor(2.0, 1)).is_equal(2.0)
	assert_float(OverlayScale.factor(1.5, 2)).is_equal(1.5)
	assert_float(OverlayScale.factor(1.5, 3)).is_equal_approx(5.0 / 3.0, 0.0001)
	assert_float(OverlayScale.factor(1.5, 4)).is_equal(1.5)
	assert_float(OverlayScale.factor(2.0, 3)).is_equal(2.0)
	assert_float(OverlayScale.factor(1.5, 0)).is_equal(2.0)

func test_factor_times_k_is_whole() -> void:
	for k in range(1, 9):
		for m: float in [OverlayScale.NORMAL, OverlayScale.LARGE, OverlayScale.LARGEST]:
			var p: float = OverlayScale.factor(m, k) * k
			assert_float(p).is_equal_approx(roundf(p), 0.0001)

func test_whole_scale_follows_the_window() -> void:
	var root := get_tree().root
	root.size = Vector2i(640, 360)
	assert_int(OverlayScale.whole_scale(root)).is_equal(2)
	root.size = Vector2i(1920, 1080)
	assert_int(OverlayScale.whole_scale(root)).is_equal(6)
	root.size = Vector2i(700, 400)
	assert_int(OverlayScale.whole_scale(root)).is_equal(2)
	root.size = Vector2i(64, 64)
	assert_int(OverlayScale.whole_scale(root)).is_equal(1)

func test_layer_transform_keeps_the_anchor_still() -> void:
	for a: Vector2 in [OverlayScale.ANCHOR_TOP_LEFT, OverlayScale.ANCHOR_BOTTOM_CENTRE, OverlayScale.ANCHOR_CENTRE]:
		var moved: Vector2 = OverlayScale.layer_transform(1.5, a) * a
		assert_vector(moved).is_equal_approx(a, Vector2(0.0001, 0.0001))
	assert_vector(OverlayScale.layer_transform(1.5, OverlayScale.ANCHOR_CENTRE).origin).is_equal(Vector2(-80, -45))
	assert_vector(OverlayScale.layer_transform(2.0, OverlayScale.ANCHOR_BOTTOM_CENTRE).origin).is_equal(Vector2(-160, -180))
	assert_bool(OverlayScale.layer_transform(1.0, OverlayScale.ANCHOR_CENTRE) == Transform2D.IDENTITY).is_true()

func test_applies_to_parent_layer_and_follows_resize() -> void:
	var root := get_tree().root
	root.size = Vector2i(640, 360)
	var layer := CanvasLayer.new()
	var scaler: OverlayScale = OverlayScale.new()
	scaler.anchor = OverlayScale.ANCHOR_CENTRE
	layer.add_child(scaler)
	add_child(layer)
	auto_free(layer)
	assert_bool(layer.transform == Transform2D.IDENTITY).is_true()
	scaler.multiplier = OverlayScale.LARGE
	assert_bool(layer.transform.is_equal_approx(OverlayScale.layer_transform(1.5, OverlayScale.ANCHOR_CENTRE))).is_true()
	root.size = Vector2i(320, 180)
	assert_bool(layer.transform.is_equal_approx(OverlayScale.layer_transform(2.0, OverlayScale.ANCHOR_CENTRE))).is_true()
	root.size = Vector2i(960, 540)
	assert_float(layer.transform.get_scale().x).is_equal_approx(5.0 / 3.0, 0.0001)

func test_does_nothing_without_a_layer_parent() -> void:
	var plain := Node.new()
	var s1: OverlayScale = OverlayScale.new()
	plain.add_child(s1)
	add_child(plain)
	auto_free(plain)
	s1.multiplier = OverlayScale.LARGEST
	var n2 := Node2D.new()
	var s2: OverlayScale = OverlayScale.new()
	n2.add_child(s2)
	add_child(n2)
	auto_free(n2)
	s2.multiplier = OverlayScale.LARGEST
	assert_vector(n2.scale).is_equal(Vector2.ONE)
