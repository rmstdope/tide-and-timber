extends GdUnitTestSuite

func _cells(runs: Array[Rect2]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r in runs:
		for i in int(r.size.x):
			out.append(Vector2i(int(r.position.x) + i, int(r.position.y)))
	return out

func _pts(a: Array) -> PackedVector2Array:
	return PackedVector2Array(a)

func test_polygon_axis_aligned_rect_is_one_run_per_row() -> void:
	var runs := PixelRuns.polygon(_pts([Vector2(0, 0), Vector2(4, 0), Vector2(4, 2), Vector2(0, 2)]))
	assert_array(runs).is_equal([Rect2(0, 0, 4, 1), Rect2(0, 1, 4, 1)])

func test_polygon_title_wreck_rows() -> void:
	var runs := PixelRuns.polygon(_pts([Vector2(240, 94), Vector2(285, 94), Vector2(280, 107), Vector2(235, 107)]))
	assert_int(runs.size()).is_equal(13)
	assert_that(runs[0]).is_equal(Rect2(240, 94, 45, 1))
	assert_that(runs[12]).is_equal(Rect2(235, 106, 45, 1))

func test_turned_rect_unturned_matches_polygon() -> void:
	assert_array(PixelRuns.turned_rect(Rect2(0, 0, 4, 2), Vector2.ZERO, 0.0)) \
		.is_equal([Rect2(0, 0, 4, 1), Rect2(0, 1, 4, 1)])

func test_turned_rect_quarter_turn_is_clockwise() -> void:
	assert_array(PixelRuns.turned_rect(Rect2(0, 0, 4, 2), Vector2.ZERO, 90.0)) \
		.is_equal([Rect2(-2, 0, 2, 1), Rect2(-2, 1, 2, 1), Rect2(-2, 2, 2, 1), Rect2(-2, 3, 2, 1)])

func test_turned_rect_story_ship_is_nonempty_and_near_its_pivot() -> void:
	var turned := 0
	for shape in StoryPicture.shapes(2):
		if shape.rotation_degrees == 0.0:
			continue
		turned += 1
		var runs := PixelRuns.turned_rect(shape.rect, shape.pivot, shape.rotation_degrees)
		assert_bool(runs.is_empty()).is_false()
		for c in _cells(runs):
			assert_bool(Vector2(c).distance_to(shape.pivot) <= 60.0).is_true()
	assert_int(turned).is_greater(0)

func test_line_diagonal_band() -> void:
	var cells := _cells(PixelRuns.line(Vector2(0, 0), Vector2(12, 12), 2.0))
	for c in [Vector2i(0, 0), Vector2i(5, 5), Vector2i(5, 6), Vector2i(6, 5), Vector2i(11, 11)]:
		assert_array(cells).contains([c])
	assert_array(cells).not_contains([Vector2i(5, 7), Vector2i(12, 12), Vector2i(0, 11)])

func test_arc_full_ring() -> void:
	var cells := _cells(PixelRuns.arc(Vector2(5, 5), 4.0, 2.0, 0.0, TAU))
	assert_array(cells).contains([Vector2i(4, 0), Vector2i(5, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(9, 5), Vector2i(0, 5)])
	assert_array(cells).not_contains([Vector2i(0, 0), Vector2i(3, 3), Vector2i(5, 5), Vector2i(9, 9)])
	for c in cells:
		assert_bool(Rect2i(0, 0, 10, 10).has_point(c)).is_true()

func test_arc_quarter_from_the_top_runs_clockwise() -> void:
	var cells := _cells(PixelRuns.arc(Vector2(5, 5), 4.0, 2.0, -PI / 2, 0.0))
	assert_array(cells).contains([Vector2i(5, 0), Vector2i(9, 4)])
	assert_array(cells).not_contains([Vector2i(4, 0), Vector2i(9, 5), Vector2i(0, 5)])

func test_arc_empty_span_is_nearly_empty() -> void:
	var cells := _cells(PixelRuns.arc(Vector2(5, 5), 4.0, 2.0, -PI / 2, -PI / 2))
	assert_int(cells.size()).is_less_equal(1)
