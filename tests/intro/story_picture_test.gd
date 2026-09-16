extends GdUnitTestSuite
## The storybook pictures, ported rect for rect from the mockup's painter.

const FULL := Rect2(0, 0, 320, 180)

func _with_color(shapes: Array[Dictionary], color: Color) -> Array[Dictionary]:
	return shapes.filter(func(shape: Dictionary) -> bool: return shape.color == color)

func test_black_beat_is_one_black_rect() -> void:
	var shapes := StoryPicture.shapes(3)
	assert_int(shapes.size()).is_equal(1)
	assert_that(shapes[0].rect).is_equal(FULL)
	assert_that(shapes[0].color).is_equal(StoryPicture.BLACK)

func test_pictures_start_with_the_storm_sky() -> void:
	for i in 3:
		var first: Dictionary = StoryPicture.shapes(i)[0]
		assert_that(first.rect).is_equal(FULL)
		assert_that(first.color).is_equal(StoryPicture.SKY)

func test_raindrop_counts_match_the_mockup() -> void:
	var expected := [40, 120, 140]
	for i in 3:
		assert_int(_with_color(StoryPicture.shapes(i), StoryPicture.RAIN).size()).is_equal(expected[i])

func test_raindrops_follow_the_mockup_sequence() -> void:
	var drops := _with_color(StoryPicture.shapes(0), StoryPicture.RAIN)
	assert_that(drops[0].rect).is_equal(Rect2(109, 39, 1, 5))
	assert_that(drops[1].rect).is_equal(Rect2(308, 69, 1, 5))

func test_second_picture_has_lightning_and_a_heeling_ship() -> void:
	var shapes := StoryPicture.shapes(1)
	var bolt := _with_color(shapes, StoryPicture.LIGHTNING)
	assert_int(bolt.size()).is_equal(3)
	assert_that(bolt[0].rect).is_equal(Rect2(230, 40, 3, 20))
	var wood := _with_color(shapes, StoryPicture.WOOD)
	assert_array(wood).is_not_empty()
	for shape in wood:
		assert_float(shape.rotation_degrees).is_equal(-14.0)
		assert_that(shape.pivot).is_equal(Vector2(150, 94))

func test_third_picture_is_broken_and_ends_in_a_flash() -> void:
	var shapes := StoryPicture.shapes(2)
	assert_that(shapes[-1].rect).is_equal(FULL)
	assert_that(shapes[-1].color).is_equal(StoryPicture.FLASH)
	var sail := _with_color(shapes, StoryPicture.SAIL)
	assert_int(sail.size()).is_equal(1)
	assert_that(sail[0].rect).is_equal(Rect2(161, 48, 16, 8))
	assert_float(sail[0].rotation_degrees).is_equal(35.0)
	assert_that(sail[0].pivot).is_equal(Vector2(160, 90))

func test_first_picture_ship_is_upright() -> void:
	for shape in StoryPicture.shapes(0):
		assert_float(shape.rotation_degrees).is_equal(0.0)
