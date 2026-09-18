extends GdUnitTestSuite

func test_title_wreck_is_a_pixel_polygon_with_the_same_points() -> void:
	var title: Node = auto_free(load("res://src/title/title_screen.tscn").instantiate())
	var wreck := title.get_node("Art/Wreck")
	assert_bool(wreck is PixelPolygon).is_true()
	if not wreck is PixelPolygon:
		return
	assert_that((wreck as PixelPolygon).polygon).is_equal(PackedVector2Array([Vector2(500, 193), Vector2(545, 193), Vector2(540, 206), Vector2(495, 206)]))
	assert_that((wreck as PixelPolygon).color).is_equal(Color(0.352941, 0.227451, 0.141176, 1))

func test_setters_keep_their_values() -> void:
	var shape: PixelPolygon = auto_free(PixelPolygon.new())
	add_child(shape)
	shape.polygon = PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(4, 2)])
	shape.color = Color.RED
	await get_tree().process_frame
	assert_that(shape.polygon).is_equal(PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(4, 2)]))
	assert_that(shape.color).is_equal(Color.RED)
