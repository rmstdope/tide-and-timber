extends GdUnitTestSuite
## The five item icons read on the slot, and each carries its beach prop's own ramp.

const IDS := ["coconut", "driftwood", "empty_shell", "fresh_water", "shellfish"]

func _icon(id: String) -> Image:
	return (load("res://assets/items/%s.png" % id) as Texture2D).get_image()

func _colours(image: Image) -> Array[String]:
	var seen: Array[String] = []
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a == 1.0 and not seen.has(c.to_html(false)):
				seen.append(c.to_html(false))
	seen.sort()
	return seen

func test_every_icon_stands_out_on_the_slot() -> void:
	for id: String in IDS:
		var image := _icon(id)
		var darkest := Color.WHITE
		for hex: String in _colours(image):
			var c := Color(hex)
			if ColourSight.contrast(c, Color.WHITE) > ColourSight.contrast(darkest, Color.WHITE):
				darkest = c
		var apart := ColourSight.worst_distance(darkest, HudColours.SLOT_FACE)
		assert_float(apart).override_failure_message(
			"%s's darkest #%s is only %.1f from the slot face" % [id, darkest.to_html(false), apart]
		).is_greater_equal(20.0)

func test_the_full_shell_reads_as_water() -> void:
	assert_array(_colours(_icon("fresh_water"))).is_not_equal(_colours(_icon("empty_shell")))
	assert_float(ColourSight.worst_distance(Color("#4498d1"), Color("#4b2a1b"))).is_greater_equal(20.0)

func test_the_icons_are_the_pack_ramps() -> void:
	assert_array(_colours(_icon("coconut"))).is_equal(["281c0d", "4b2a1b", "6c4326", "865932"])
	assert_array(_colours(_icon("shellfish"))).is_equal(["281c0d", "a48477", "c6ab9f", "ffcdb4"])
