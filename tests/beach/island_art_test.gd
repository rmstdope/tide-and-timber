extends GdUnitTestSuite

const FLOORS := "res://assets/pixel_crawler/Environment/Tilesets/Floors_Tiles.png"
const WATER := "res://assets/pixel_crawler/Environment/Tilesets/Water_tiles.png"
const ROCKS := "res://assets/pixel_crawler/Environment/Props/Static/Rocks.png"
const VEGETATION := "res://assets/pixel_crawler/Environment/Props/Static/Vegetation.png"
const TILES := "res://assets/beach/tiles.png"
## Kind -> [sheet, source top-left]; FOAM is checked on its own.
const GROUND := {
	BeachLayout.Kind.JUNGLE: [FLOORS, Vector2i(32, 176)],
	BeachLayout.Kind.SAND: [FLOORS, Vector2i(96, 352)],
	BeachLayout.Kind.WET_SAND: [FLOORS, Vector2i(96, 384)],
	BeachLayout.Kind.SHALLOWS: [WATER, Vector2i(16, 192)],
	BeachLayout.Kind.DEEP: [WATER, Vector2i(96, 192)],
	BeachLayout.Kind.CLIFF: [FLOORS, Vector2i(96, 160)],
}

func _image(path: String) -> Image:
	return (load(path) as Texture2D).get_image()

func test_ground_tiles_are_the_pack_tiles() -> void:
	var tiles := _image(TILES)
	for kind: int in GROUND:
		var sheet := _image(GROUND[kind][0])
		var src: Vector2i = GROUND[kind][1]
		var diff := ""
		for y in 16:
			for x in 16:
				if diff == "" and tiles.get_pixel(kind * 16 + x, y) != sheet.get_pixel(src.x + x, src.y + y):
					diff = "%s differs first at (%d, %d)" % [BeachLayout.Kind.keys()[kind], x, y]
		assert_str(diff).is_empty()

func test_foam_tile_is_shallows_with_a_surf_line() -> void:
	var tiles := _image(TILES)
	var water := _image(WATER)
	var x0 := BeachLayout.Kind.FOAM * 16
	for x in 16:
		assert_str(tiles.get_pixel(x0 + x, 0).to_html(false)).is_equal("a3c8ee")
		for y in [1, 2]:
			assert_str(tiles.get_pixel(x0 + x, y).to_html(false)).is_equal("7baadb")
		for y in range(3, 16):
			assert_bool(tiles.get_pixel(x0 + x, y) == water.get_pixel(16 + x, 192 + y)) \
				.override_failure_message("FOAM (%d, %d)" % [x, y]).is_true()

func test_wave_wash_uses_the_foam_colours() -> void:
	assert_bool(WaveWash.WATER == Color("#7baadb")).is_true()
	assert_bool(WaveWash.EDGE == Color("#a3c8ee")).is_true()
	assert_bool(PackPalette.has(WaveWash.WATER)).is_true()
	assert_bool(PackPalette.has(WaveWash.EDGE)).is_true()

func _assert_crop(scene_path: String, sheet: String, region: Rect2, offset: Vector2) -> void:
	var prop := auto_free((load(scene_path) as PackedScene).instantiate()) as Node
	var sprite := prop.get_node("Sprite") as Sprite2D
	var atlas := sprite.texture as AtlasTexture
	assert_object(atlas).override_failure_message("%s is not an AtlasTexture" % scene_path).is_not_null()
	if atlas:
		assert_str(atlas.atlas.resource_path).is_equal(sheet)
		assert_bool(atlas.region == region).override_failure_message("%s region %s" % [scene_path, atlas.region]).is_true()
	assert_vector(sprite.offset).is_equal(offset)

func test_rock_and_boulder_are_pack_crops() -> void:
	_assert_crop("res://src/beach/props/rock.tscn", ROCKS, Rect2(160, 16, 16, 16), Vector2(0, -8))
	_assert_crop("res://src/beach/props/boulder.tscn", ROCKS, Rect2(128, 16, 32, 32), Vector2(0, -16))

func test_vegetation_is_pack_crops() -> void:
	_assert_crop("res://src/beach/props/bush.tscn", VEGETATION, Rect2(0, 0, 32, 32), Vector2(0, -16))
	_assert_crop("res://src/beach/props/tuft.tscn", VEGETATION, Rect2(64, 144, 16, 16), Vector2(0, -8))

const REPAINTED := [
	"res://assets/beach/palm.png", "res://assets/beach/palm_coconuts.png", "res://assets/beach/coconut.png",
	"res://assets/beach/driftwood.png", "res://assets/beach/spring.png", "res://assets/beach/shellfish.png",
	"res://assets/beach/ripple.png", "res://assets/beach/puff.png",
	"res://assets/items/coconut.png", "res://assets/items/driftwood.png",
	"res://assets/items/empty_shell.png", "res://assets/items/fresh_water.png",
	"res://assets/items/shellfish.png",
]
const OUTLINED := [
	"res://assets/beach/palm.png", "res://assets/beach/palm_coconuts.png", "res://assets/beach/coconut.png",
	"res://assets/beach/driftwood.png", "res://assets/beach/spring.png", "res://assets/beach/shellfish.png",
	"res://assets/items/coconut.png", "res://assets/items/driftwood.png",
	"res://assets/items/empty_shell.png", "res://assets/items/fresh_water.png",
	"res://assets/items/shellfish.png",
]

func test_repainted_pieces_use_only_pack_colours() -> void:
	for path: String in REPAINTED + [TILES]:
		var image := _image(path)
		var bad := ""
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x, y)
				if bad == "" and ((c.a != 0.0 and c.a != 1.0) or (c.a == 1.0 and not PackPalette.has(c))):
					bad = "%s (%d, %d) is #%s" % [path, x, y, c.to_html()]
		assert_str(bad).is_empty()

static func _luma(c: Color) -> float:
	var lin := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * lin.call(c.r) + 0.7152 * lin.call(c.g) + 0.0722 * lin.call(c.b)

func test_outlined_pieces_are_shaded_like_the_pack() -> void:
	for path: String in OUTLINED:
		var image := _image(path)
		var w := image.get_width()
		var h := image.get_height()
		var colours := {}
		var edge: Array[Color] = []
		for y in h:
			for x in w:
				var c := image.get_pixel(x, y)
				if c.a != 1.0:
					continue
				colours[c.to_html(false)] = c
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n := Vector2i(x, y) + d
					if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or image.get_pixelv(n).a != 1.0:
						edge.append(c)
						break
		assert_int(colours.size()).override_failure_message(path).is_greater_equal(3)
		var by_luma: Array = colours.keys()
		by_luma.sort_custom(func(a: String, b: String) -> bool: return _luma(Color(a)) < _luma(Color(b)))
		var darkest := by_luma.slice(0, 2)
		var dark_edge := edge.filter(func(c: Color) -> bool: return darkest.has(c.to_html(false))).size()
		assert_bool(dark_edge * 4 >= edge.size() * 3) \
			.override_failure_message("%s: %d of %d edge pixels dark" % [path, dark_edge, edge.size()]).is_true()
