extends GdUnitTestSuite

func test_palette_is_the_imported_sheets_colours() -> void:
	var colours := PackPalette.colours()
	assert_int(colours.size()).is_equal(181)
	for hex: String in ["281c0d", "edb786", "4498d1"]:
		assert_bool(colours.has(hex)).override_failure_message(hex).is_true()

func test_has_ignores_alpha() -> void:
	assert_bool(PackPalette.has(Color("#281c0d", 0.5))).is_true()
	assert_bool(PackPalette.has(Color("#7a4a2a"))).is_false()

func test_sheets_are_the_vendored_files() -> void:
	var sizes := [Vector2i(400, 416), Vector2i(400, 400), Vector2i(400, 432), Vector2i(208, 304)]
	assert_int(PackPalette.SHEETS.size()).is_equal(sizes.size())
	for i in PackPalette.SHEETS.size():
		var texture := load(PackPalette.SHEETS[i]) as Texture2D
		assert_object(texture).override_failure_message(PackPalette.SHEETS[i]).is_not_null()
		if texture:
			assert_vector(Vector2(texture.get_size())).is_equal(Vector2(sizes[i]))
