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
