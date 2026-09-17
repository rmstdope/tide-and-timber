extends GdUnitTestSuite
## He stays visible at night: his best colour against each ground he walks, both under the night tint.

const MIN_CONTRAST := 2.0

static func _linear(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)

static func _luminance(c: Color) -> float:
	return 0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b)

static func _tinted(c: Color, tint: Color) -> Color:
	return Color(c.r * tint.r, c.g * tint.g, c.b * tint.b)

func _ground_colour(tiles: Image, kind: int) -> Color:
	var counts := {}
	for y in 16:
		for x in 16:
			var hex := tiles.get_pixel(kind * 16 + x, y).to_html(false)
			counts[hex] = counts.get(hex, 0) + 1
	var best := ""
	for hex: String in counts:
		if best == "" or counts[hex] > counts[best]:
			best = hex
	return Color(best)

func test_he_stands_out_at_night_on_sand_and_grass() -> void:
	var night := Daylight.color_at(0.0)
	var tiles := (load("res://assets/beach/tiles.png") as Texture2D).get_image()
	var man := (load("res://assets/man/man.png") as Texture2D).get_image()
	var his := {}
	for y in man.get_height():
		for x in man.get_width():
			var c := man.get_pixel(x, y)
			if c.a == 1.0:
				his[c.to_html(false)] = true
	for kind: int in [BeachLayout.Kind.SAND, BeachLayout.Kind.WET_SAND, BeachLayout.Kind.JUNGLE]:
		var ground := _luminance(_tinted(_ground_colour(tiles, kind), night))
		var best := 0.0
		for hex: String in his:
			var l := _luminance(_tinted(Color(hex), night))
			best = maxf(best, (maxf(l, ground) + 0.05) / (minf(l, ground) + 0.05))
		assert_float(best).override_failure_message("%s: best contrast %.2f" % [BeachLayout.Kind.keys()[kind], best]) \
			.is_greater_equal(MIN_CONTRAST)
