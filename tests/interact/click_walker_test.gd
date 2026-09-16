extends GdUnitTestSuite

func test_pick_topmost() -> void:
	var rects: Array[Rect2] = [Rect2(0, 0, 10, 10), Rect2(5, 5, 10, 10)]
	var depths: Array[float] = [1.0, 2.0]
	assert_int(ClickWalker.pick(Vector2(7, 7), rects, depths)).is_equal(1)
	assert_int(ClickWalker.pick(Vector2(1, 1), rects, depths)).is_equal(0)
	assert_int(ClickWalker.pick(Vector2(30, 30), rects, depths)).is_equal(-1)
	var equal: Array[float] = [2.0, 2.0]
	assert_int(ClickWalker.pick(Vector2(7, 7), rects, equal)).is_equal(1)

func test_pick_empty() -> void:
	var rects: Array[Rect2] = []
	var depths: Array[float] = []
	assert_int(ClickWalker.pick(Vector2.ZERO, rects, depths)).is_equal(-1)
