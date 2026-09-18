extends GdUnitTestSuite
## Every colour of the in-play interface is a pack colour, and the ramps still read.

func _map() -> Dictionary:
	return (load("res://src/hud/hud_colours.gd") as GDScript).get_script_constant_map()

func test_every_colour_is_a_pack_colour() -> void:
	var map := _map()
	assert_bool(map.is_empty()).is_false()
	var bad := ""
	for name: StringName in map:
		var value: Variant = map[name]
		if bad != "":
			continue
		if typeof(value) != TYPE_COLOR:
			bad = "%s is not a Color" % name
			continue
		var colour: Color = value
		if colour.a != 1.0:
			bad = "%s is not opaque" % name
		elif not PackPalette.has(colour):
			bad = "%s is #%s, not a pack colour" % [name, colour.to_html(false)]
	assert_str(bad).is_empty()

func test_the_named_values() -> void:
	var want := {
		&"WOOD_DARK": "58351e", &"WOOD": "865932", &"WOOD_LIGHT": "b68c48",
		&"SLOT_FACE": "fee0a1", &"SLOT_EDGE": "fff6e4", &"INK": "301d0e",
		&"PALE": "fff6e4", &"CREAM": "fee0a1", &"DIM": "c6ab9f",
		&"RING": "bbb1ad", &"CAP_SHADOW": "927e65", &"ARC": "fee0a1",
		&"SUN": "f6cc2b", &"MOON": "eff8ff",
		&"JOURNAL_COVER": "004d83", &"JOURNAL_SPINE": "002d4d", &"JOURNAL_PAGE": "fff6e4",
		&"JOURNAL_WRITING": "80776b", &"JOURNAL_MISSED": "a70c21",
		&"BAD": "a70c21", &"CROSS": "fff6e4", &"WARN": "f78b54",
	}
	var map := _map()
	assert_int(map.size()).is_equal(want.size())
	for name: StringName in want:
		assert_bool(map.has(name)).override_failure_message("no %s" % name).is_true()
		var colour: Color = map[name]
		assert_str(colour.to_html(false)).override_failure_message("%s" % name).is_equal(want[name])

func test_the_wood_ramp_is_ordered() -> void:
	assert_float(ColourSight.contrast(HudColours.WOOD, HudColours.WOOD_DARK)).is_greater_equal(1.6)
	assert_float(ColourSight.contrast(HudColours.WOOD_LIGHT, HudColours.WOOD)).is_greater_equal(1.6)
	var white := Color.WHITE
	assert_float(ColourSight.contrast(HudColours.WOOD_DARK, white)).is_greater(
		ColourSight.contrast(HudColours.WOOD, white))
	assert_float(ColourSight.contrast(HudColours.WOOD, white)).is_greater(
		ColourSight.contrast(HudColours.WOOD_LIGHT, white))

func test_words_read_where_they_are_drawn() -> void:
	assert_float(ColourSight.contrast(HudColours.PALE, HudColours.WOOD)).is_greater_equal(4.5)
	assert_float(ColourSight.contrast(HudColours.CREAM, HudColours.WOOD)).is_greater_equal(4.5)
	assert_float(ColourSight.contrast(HudColours.INK, HudColours.SLOT_FACE)).is_greater_equal(4.5)
	assert_float(ColourSight.contrast(HudColours.DIM, HudColours.WOOD)).is_greater_equal(2.0)
	assert_float(ColourSight.contrast(HudColours.DIM, Color.WHITE)).is_greater(
		ColourSight.contrast(HudColours.PALE, Color.WHITE))
