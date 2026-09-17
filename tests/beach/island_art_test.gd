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
