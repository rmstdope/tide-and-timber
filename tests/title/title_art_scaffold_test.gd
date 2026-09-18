extends GdUnitTestSuite

# The title's art is still drawn for 320x180, so until tr-1o0.2 repaints it the art root alone is
# drawn at twice its pixels; the words are not (tr-1o0.1).

func _title() -> Control:
	return auto_free((load("res://src/title/title_screen.tscn") as PackedScene).instantiate())

func test_the_title_art_fills_the_picture_at_twice_its_pixels() -> void:
	var art := _title().get_node("Art") as Control
	assert_vector(art.scale).is_equal(Vector2(2, 2))
	assert_vector(art.size * art.scale).is_equal(Screen.SIZE)

func test_the_words_are_not_scaffolded() -> void:
	var title := _title()
	var art := title.get_node("Art")
	for path: String in ["%MenuClip", "Title", "Tagline"]:
		var n := title.get_node(path) as Control
		assert_vector(n.scale).override_failure_message(path).is_equal(Vector2.ONE)
		assert_bool(art.is_ancestor_of(n)).override_failure_message(path).is_false()
