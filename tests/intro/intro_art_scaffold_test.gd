extends GdUnitTestSuite

# The story pictures are still drawn for 320x180, so until tr-1o0.2 repaints them the picture is
# drawn at twice its pixels (tr-1o0.1).

func test_the_story_picture_fills_the_picture_at_twice_its_pixels() -> void:
	var intro: Control = auto_free((load("res://src/intro/intro.tscn") as PackedScene).instantiate())
	var picture := intro.get_node("%Picture") as Control
	assert_vector(picture.scale).is_equal(Vector2(2, 2))
	assert_vector(picture.size * picture.scale).is_equal(Screen.SIZE)
