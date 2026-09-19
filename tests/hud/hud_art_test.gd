extends GdUnitTestSuite
## The knobbed frame and the set-in slot are the Retro Inventory pack's pieces recoloured to
## HudColours by tools/pack_art/make_hud_art.gd, and the committed art is exactly what it makes.

const MakeHudArt := preload("res://tools/pack_art/make_hud_art.gd")

func _committed(path: String) -> Image:
	var image := (load(path) as Texture2D).get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image

func _hud_colours() -> Dictionary:
	var out := {}
	for value: Variant in (load("res://src/hud/hud_colours.gd") as GDScript).get_script_constant_map().values():
		if value is Color:
			out[(value as Color).to_html(false)] = true
	return out

func test_frame_and_slot_use_only_hud_colours() -> void:
	var colours := _hud_colours()
	for path: String in [MakeHudArt.FRAME_PATH, MakeHudArt.SLOT_PATH]:
		var image := _committed(path)
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x, y)
				assert_bool(c.a == 0.0 or c.a == 1.0).override_failure_message(
					"%s (%d, %d) is partly transparent" % [path, x, y]).is_true()
				if c.a == 1.0:
					assert_bool(colours.has(c.to_html(false))).override_failure_message(
						"%s (%d, %d) is %s, not a HudColours colour" % [path, x, y, c.to_html(false)]).is_true()

func test_committed_art_is_what_the_tool_makes() -> void:
	var pairs := [[MakeHudArt.FRAME_PATH, MakeHudArt.frame_image()], [MakeHudArt.SLOT_PATH, MakeHudArt.slot_image()]]
	for pair: Array in pairs:
		var committed := _committed(pair[0])
		var made: Image = pair[1]
		assert_object(made).is_not_null()
		assert_vector(committed.get_size()).is_equal(made.get_size())
		for y in made.get_height():
			for x in made.get_width():
				var a := committed.get_pixel(x, y)
				var b := made.get_pixel(x, y)
				assert_float(a.a).override_failure_message("%s (%d, %d) alpha" % [pair[0], x, y]).is_equal(b.a)
				if b.a > 0.0:
					assert_str(a.to_html(false)).override_failure_message(
						"%s (%d, %d)" % [pair[0], x, y]).is_equal(b.to_html(false))

func test_sizes() -> void:
	assert_vector(_committed(MakeHudArt.FRAME_PATH).get_size()).is_equal(Vector2i(32, 32))
	assert_vector(_committed(MakeHudArt.SLOT_PATH).get_size()).is_equal(Vector2i(22, 22))

func test_slot_is_set_in() -> void:
	var slot := _committed(MakeHudArt.SLOT_PATH)
	for p: Vector2i in [Vector2i(4, 3), Vector2i(17, 3), Vector2i(3, 4)]:
		assert_str(slot.get_pixelv(p).to_html(false)).is_equal(HudColours.WOOD_LIGHT.to_html(false))
	assert_str(slot.get_pixel(11, 11).to_html(false)).is_equal(HudColours.SLOT_FACE.to_html(false))
	assert_str(slot.get_pixel(3, 0).to_html(false)).is_equal(HudColours.INK.to_html(false))
	assert_float(slot.get_pixel(0, 0).a).is_equal(0.0)

func test_frame_is_the_pack_frame_on_wood() -> void:
	var frame := _committed(MakeHudArt.FRAME_PATH)
	assert_str(frame.get_pixel(16, 16).to_html(false)).is_equal(HudColours.WOOD.to_html(false))
	assert_str(frame.get_pixel(6, 6).to_html(false)).is_equal(HudColours.WOOD.to_html(false))
	assert_str(frame.get_pixel(16, 5).to_html(false)).is_equal(HudColours.WOOD_LIGHT.to_html(false))
	assert_str(frame.get_pixel(5, 16).to_html(false)).is_equal(HudColours.SLOT_FACE.to_html(false))
	assert_str(frame.get_pixel(0, 0).to_html(false)).is_equal(HudColours.INK.to_html(false))
	assert_float(frame.get_pixel(4, 0).a).is_equal(0.0)

func test_recolour_refuses_a_colour_it_does_not_know() -> void:
	var unknown := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	unknown.fill(Color("#123456"))
	assert_object(MakeHudArt.recolour(unknown)).is_null()
	var half := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	half.fill(Color(0, 0, 0, 0.5))
	assert_object(MakeHudArt.recolour(half)).is_null()

func test_frame_style_tiles_the_frame_art() -> void:
	var style := load("res://src/hud/frame.tres") as StyleBoxTexture
	assert_object(style).is_not_null()
	assert_str(style.texture.resource_path).is_equal(MakeHudArt.FRAME_PATH)
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		assert_float(style.get_texture_margin(side)).is_equal(6.0)
	assert_int(style.axis_stretch_horizontal).is_equal(StyleBoxTexture.AXIS_STRETCH_MODE_TILE)
	assert_int(style.axis_stretch_vertical).is_equal(StyleBoxTexture.AXIS_STRETCH_MODE_TILE)
	assert_bool(style.draw_center).is_true()
