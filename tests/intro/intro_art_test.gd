extends GdUnitTestSuite

# The story pictures are painted at 640x360, at the island's pixel density: no scaffold scale.

func test_the_story_picture_is_drawn_at_one_times_the_picture() -> void:
	var intro: Control = auto_free((load("res://src/intro/intro.tscn") as PackedScene).instantiate())
	var picture := intro.get_node("%Picture") as Control
	assert_vector(picture.scale).is_equal(Vector2.ONE)
	assert_vector(picture.size).is_equal(Screen.SIZE)
