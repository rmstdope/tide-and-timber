extends GdUnitTestSuite

func _keys(cells: Array[Vector2i]) -> int:
	var d := {}
	for c in cells:
		d[c] = true
	return d.size()

func test_lean_to_cross_touches_each_pixel_once() -> void:
	var cells := CampArt.cross_cells(CampArt.LEAN_TO_CROSS)
	assert_int(cells.size()).is_equal(21)
	assert_int(_keys(cells)).is_equal(21)

func test_fire_cross_touches_each_pixel_once() -> void:
	var cells := CampArt.cross_cells(CampArt.FIRE_CROSS)
	assert_int(cells.size()).is_equal(13)
	assert_int(_keys(cells)).is_equal(13)

func test_cross_reaches_all_four_corners_and_the_middle() -> void:
	var cells := CampArt.cross_cells(CampArt.LEAN_TO_CROSS)
	for p in [Vector2i(-5, -25), Vector2i(5, -25), Vector2i(-5, -15), Vector2i(5, -15), Vector2i(0, -20)]:
		assert_bool(cells.has(p)).is_true()

func test_cross_stays_inside_its_box() -> void:
	for box in [CampArt.LEAN_TO_CROSS, CampArt.FIRE_CROSS]:
		for c in CampArt.cross_cells(box):
			assert_bool((box as Rect2i).has_point(c)).is_true()

func test_boxes_are_square_with_odd_sides() -> void:
	for box in [CampArt.LEAN_TO_CROSS, CampArt.FIRE_CROSS]:
		assert_int(box.size.x).is_equal(box.size.y)
		assert_int(box.size.x % 2).is_equal(1)

func test_crosses_sit_in_the_middle_of_their_drawings() -> void:
	assert_that(CampArt.LEAN_TO_CROSS.position + CampArt.LEAN_TO_CROSS.size / 2).is_equal(Vector2i(0, -20))
	assert_that(CampArt.FIRE_CROSS.position + CampArt.FIRE_CROSS.size / 2).is_equal(Vector2i(0, -5))
