extends GdUnitTestSuite

const FLOORS := "res://assets/pixel_crawler/Environment/Tilesets/Floors_Tiles.png"
const WATER := "res://assets/pixel_crawler/Environment/Tilesets/Water_tiles.png"
const ROCKS := "res://assets/pixel_crawler/Environment/Props/Static/Rocks.png"
const VEGETATION := "res://assets/pixel_crawler/Environment/Props/Static/Vegetation.png"
const TILES := "res://assets/beach/tiles.png"
const WAVES := "res://assets/beach/waves.png"
const WAVES_SOURCE := "res://assets/farming_101/tileset/sliced waves animation/bottom_waves.png"
## Kind -> [sheet, source top-left].
const GROUND := {
	BeachLayout.Kind.JUNGLE: [FLOORS, Vector2i(32, 176)],
	BeachLayout.Kind.SAND: [FLOORS, Vector2i(96, 352)],
	BeachLayout.Kind.WET_SAND: [FLOORS, Vector2i(96, 384)],
	BeachLayout.Kind.FOAM: [WATER, Vector2i(16, 192)],
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

## Two pixels are the same when both are fully transparent or their colours match exactly.
static func _same(a: Color, b: Color) -> bool:
	return (a.a8 == 0 and b.a8 == 0) or a.to_html() == b.to_html()

static func _drawing(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image

func test_waves_are_the_pack_waves_warmed() -> void:
	var waves := _rgba(WAVES)
	var source := _rgba(WAVES_SOURCE)
	assert_vector(Vector2(waves.get_size())).is_equal(Vector2(144, 16))
	var diff := ""
	for y in 16:
		for x in 144:
			var src := source.get_pixel(x, y)
			var want := src
			if src.to_html(false) == "c7b08b":
				want = Color("#e2a46c")
			elif src.to_html(false) == "249fde":
				want = Color(0, 0, 0, 0)
			if diff == "" and not _same(waves.get_pixel(x, y), want):
				diff = "waves differ first at (%d, %d)" % [x, y]
	assert_str(diff).is_empty()

func test_waves_match_the_drawing() -> void:
	var waves := _rgba(WAVES)
	var drawn := _drawing("res://docs/ui/vendor-art-swap/waves_warm.png")
	assert_vector(Vector2(drawn.get_size())).is_equal(Vector2(waves.get_size()))
	var diff := ""
	for y in drawn.get_height():
		for x in drawn.get_width():
			if diff == "" and not _same(waves.get_pixel(x, y), drawn.get_pixel(x, y)):
				diff = "waves differ from the drawing first at (%d, %d)" % [x, y]
	assert_str(diff).is_empty()

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

const PALM_SOURCE := "res://assets/farming_101/beach/palm trees.png"
const PALMS := "res://assets/beach/palms.png"
const PALM_CROWNS := "res://assets/beach/palm_crowns.png"

func _rgba(path: String) -> Image:
	var image := _image(path)
	image.convert(Image.FORMAT_RGBA8)
	return image

## Two pixels are alike when both are fully transparent, or when they are equal.
func _alike(a: Color, b: Color) -> bool:
	return (a.a8 == 0 and b.a8 == 0) or a == b

func test_palm_sheet_is_the_pack_sheet_with_warm_shadows() -> void:
	assert_bool(ResourceLoader.exists(PALMS)).override_failure_message("%s missing" % PALMS).is_true()
	if not ResourceLoader.exists(PALMS):
		return
	var src := _rgba(PALM_SOURCE)
	var palms := _rgba(PALMS)
	assert_vector(Vector2(palms.get_size())).is_equal(Vector2(src.get_size()))
	var diff := ""
	for y in src.get_height():
		for x in src.get_width():
			if diff != "":
				break
			var s := src.get_pixel(x, y)
			var p := palms.get_pixel(x, y)
			if s.a8 > 0 and s.a8 < 255:
				var want := Color("#78190e")
				want.a8 = s.a8
				if p.to_html() != want.to_html():
					diff = "shadow differs first at (%d, %d): %s" % [x, y, p.to_html()]
			elif not _alike(s, p):
				diff = "differs first at (%d, %d)" % [x, y]
	assert_str(diff).is_empty()

func test_crown_sheet_holds_only_the_coconuts() -> void:
	assert_bool(ResourceLoader.exists(PALM_CROWNS)).override_failure_message("%s missing" % PALM_CROWNS).is_true()
	if not ResourceLoader.exists(PALM_CROWNS):
		return
	var src := _rgba(PALM_SOURCE)
	var crowns := _rgba(PALM_CROWNS)
	assert_vector(Vector2(crowns.get_size())).is_equal(Vector2(src.get_size()))
	var diff := ""
	for y in src.get_height():
		for x in src.get_width():
			if diff != "":
				break
			var c := crowns.get_pixel(x, y)
			var want := Color(0, 0, 0, 0)
			if x >= 320 and not _alike(src.get_pixel(x, y), src.get_pixel(x - 320, y)):
				want = src.get_pixel(x, y)
			if not _alike(c, want):
				diff = "differs first at (%d, %d)" % [x, y]
	assert_str(diff).is_empty()

func test_crown_over_bare_is_the_drawn_palm() -> void:
	if not ResourceLoader.exists(PALMS) or not ResourceLoader.exists(PALM_CROWNS):
		fail("palm sheets missing")
		return
	var palms := _rgba(PALMS)
	var crowns := _rgba(PALM_CROWNS)
	var diff := ""
	for rect: Rect2i in BeachArt.PALM_SHAPES:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var c := crowns.get_pixel(x, y)
				var drawn := c if c.a8 > 0 else palms.get_pixel(x - BeachArt.BARE_SHIFT, y)
				if diff == "" and not _alike(drawn, palms.get_pixel(x, y)):
					diff = "%s differs first at (%d, %d)" % [rect, x, y]
	assert_str(diff).is_empty()

func test_warm_shadow_on_dry_sand_is_c4805c() -> void:
	assert_str(Color("#edb786").blend(Color("#78190e", 89.0 / 255.0)).to_html(false)).is_equal("c4805c")

const COCONUTS := "res://assets/farming_101/beach/coconuts.png"
const SHELLS := "res://assets/farming_101/beach/seashells.png"

func test_coconut_and_shell_are_pack_crops() -> void:
	_assert_crop("res://src/beach/props/coconut.tscn", COCONUTS, Rect2(3, 19, 10, 10), Vector2(-5, -10))
	_assert_crop("res://src/beach/props/shellfish.tscn", SHELLS, Rect2(2, 2, 11, 12), Vector2(-5, -13))
	for path in ["res://src/beach/props/coconut.tscn", "res://src/beach/props/shellfish.tscn"]:
		var prop := auto_free((load(path) as PackedScene).instantiate()) as Node
		assert_bool((prop.get_node("Sprite") as Sprite2D).centered).is_false()
