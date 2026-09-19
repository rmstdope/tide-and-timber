extends SceneTree
## Draws the island's art from the Pixel Crawler pack: the ground tiles copied from its sheets, and our
## own pieces repainted in its colours and shading.
## Run: godot --headless --path . --script res://tools/pack_art/make_island_art.gd

const FLOORS := "res://assets/pixel_crawler/Environment/Tilesets/Floors_Tiles.png"
const WATER := "res://assets/pixel_crawler/Environment/Tilesets/Water_tiles.png"
## Per BeachLayout.Kind, in order: [sheet, source top-left].
const GROUND := [
	[FLOORS, Vector2i(32, 176)],    # JUNGLE
	[FLOORS, Vector2i(96, 352)],    # SAND
	[FLOORS, Vector2i(96, 384)],    # WET_SAND
	[WATER, Vector2i(16, 192)],     # FOAM: plain shallows; the Waves layer carries the waterline
	[WATER, Vector2i(16, 192)],     # SHALLOWS
	[WATER, Vector2i(96, 192)],     # DEEP
	[FLOORS, Vector2i(96, 160)],    # CLIFF
]
const PALM_SOURCE := "res://assets/farming_101/beach/palm trees.png"
const PALM_SHADOW := "#78190e"   # the pack's shadow #060608, warmed; same alpha
const BARE_SHIFT := 320          # the bare palm group sits this far left of the brown-coconut group
const WAVES_SOURCE := "res://assets/farming_101/tileset/sliced waves animation/bottom_waves.png"
const WAVE_SAND := "#c7b08b"          # the pack wave's sand, which becomes WET_SAND's #e2a46c
const WAVE_SAND_WARM := "#e2a46c"
const WAVE_WATER := "#249fde"         # the pack wave's water, which becomes transparent over today's shallows
## Each piece: its grid, one string per row, "." transparent, and its legend of character -> colour.
const PIECES := {
	"res://assets/beach/palm.png": {
		"legend": {"o": "#281c0d", "t": "#6c4326", "m": "#865932", "l": "#9f6c3f", "d": "#35500e", "g": "#4f7a11", "h": "#659714"},
		"grid": [
			"................................",
			"................................",
			"......oooooooooooooooooooo......",
			"......ohhhhhhhhhhhhhhhhhdo......",
			"......ohggggggggggggggggdo......",
			"......ohggggggggggggggggdo......",
			"..oooohggggggggggggggggggdoooo..",
			"..ohhhgggggggggggggggggggghhdo..",
			"..ohggggggggggggggggggggggggdo..",
			"..ohggggggggggggggggggggggggdo..",
			"..ohggggggggggggggggggggggggdo..",
			"..ohggggggggggggggggggggggggdo..",
			"..ohggggggdddggggggdddggggggdo..",
			"..ohgggggdoooddddddooodgggggdo..",
			"oohgggggdo...olllto...ohgggggdoo",
			"ohggggggdo...olmmto...ohggggggdo",
			"oddddddddo...olmmto...oddddddddo",
			"oooooooooo...olmmto...oooooooooo",
			".............olmmto.............",
			".............olmmto.............",
			".............otttto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............otttto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............otttto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............otttto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............otttto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............otttto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............olmmto.............",
			".............otttto.............",
			".............olmmto.............",
			".............otttto.............",
			".............oooooo.............",
		],
	},
	"res://assets/beach/palm_coconuts.png": {
		"legend": {"o": "#281c0d", "d": "#4b2a1b", "m": "#6c4326", "h": "#865932"},
		"grid": [
			"oooo..oooo",
			"ohmo..ohmo",
			"omdo..omdo",
			"oooo..oooo",
		],
	},
	"res://assets/beach/coconut.png": {
		"legend": {"o": "#281c0d", "d": "#4b2a1b", "m": "#6c4326", "h": "#865932"},
		"grid": [
			".oooo.",
			"ohhmmo",
			"ohmmdo",
			"ommddo",
			"omdddo",
			".oooo.",
		],
	},
	"res://assets/beach/driftwood.png": {
		"legend": {"o": "#281c0d", "d": "#5e5245", "m": "#8b8279", "h": "#968780"},
		"grid": [
			"................................",
			"....oooooo......................",
			".ooohhhhhdooooooooooooooooooooo.",
			".ohhmmmmmmhhhhhhhhhhhhhhhhhhhdo.",
			".oddddddddddddddddddddddddddddo.",
			".oooooooooooooooooooooooooooooo.",
			"................................",
			"................................",
		],
	},
	"res://assets/beach/spring.png": {
		"legend": {"o": "#281c0d", "d": "#5e5245", "m": "#8b8279", "s": "#4185ca", "w": "#4498d1", "g": "#a3c8ee"},
		"grid": [
			"..oooooooooooooooooooooooooooo..",
			"..ommmmmmmmmmmmmmmmmmmmmmmmmdo..",
			"..ommmddddddddddddddddddddmmdo..",
			"..ommdssssssssssssssssssssmmdo..",
			"..ommdswggggggwwwwwwwwwwwwmmdo..",
			"..ommdswwwwwwwwwwwwwwwwwwwmmdo..",
			"..ommdswwwwwwwwwwwwwwwwwwwmmdo..",
			"..ommdswwwwwwwwwwwwwwwwwwwmmdo..",
			"..ommdswwwwwwwwwwwwwwwwwwwmmdo..",
			"..ommdswwwwwwwwwwwwwwwwwwwmmdo..",
			"..ommdswwwwwwwwwwwwwwwwwwwmmdo..",
			"..ommmmmmmmmmmmwmmmmmmmmmmmmdo..",
			"..odddddddddddmwmddddddddddddo..",
			"..oooooooooooodwdooooooooooooo..",
			"..............owo...............",
			"..............owo...............",
			"..............owo...............",
			"..............owo...............",
			"..............owo...............",
			"..............owo...............",
			"..............owo...............",
			"..............owo...............",
			"..............owo...............",
			"..............ooo...............",
		],
	},
	"res://assets/beach/shellfish.png": {
		"legend": {"o": "#281c0d", "d": "#a48477", "m": "#c6ab9f", "l": "#ffcdb4"},
		"grid": [
			".oooooooooo.",
			".olldlldldo.",
			".olmdmmdmdo.",
			".olmdmmdmdo.",
			".oddddddddo.",
			"..oooooooo..",
		],
	},
	"res://assets/beach/ripple.png": {
		"legend": {"x": "#d5def0"},
		"grid": [
			"..xxxxxxxx..",
			"xx........xx",
			"xx........xx",
			"..xxxxxxxx..",
		],
	},
	"res://assets/beach/puff.png": {
		"legend": {"x": "#fff6e4"},
		"grid": [
			".xx.",
			"xxxx",
			"xxxx",
			".xx.",
		],
	},
}

func _init() -> void:
	_save(_tiles(), "res://assets/beach/tiles.png")
	for path: String in PIECES:
		_save(_piece(PIECES[path]), path)
	var palm_src := (load(PALM_SOURCE) as Texture2D).get_image()
	palm_src.convert(Image.FORMAT_RGBA8)
	_save(palms(palm_src), "res://assets/beach/palms.png")
	_save(palm_crowns(palm_src), "res://assets/beach/palm_crowns.png")
	var wave_src := (load(WAVES_SOURCE) as Texture2D).get_image()
	wave_src.convert(Image.FORMAT_RGBA8)
	_save(waves(wave_src), "res://assets/beach/waves.png")
	quit()

## `source` with WAVE_SAND recoloured WAVE_SAND_WARM (opaque) and WAVE_WATER made fully transparent.
## Every other pixel is unchanged.
static func waves(source: Image) -> Image:
	var image := source.duplicate() as Image
	for y in image.get_height():
		for x in image.get_width():
			var html := image.get_pixel(x, y).to_html(false)
			if html == WAVE_SAND.substr(1):
				image.set_pixel(x, y, Color(WAVE_SAND_WARM))
			elif html == WAVE_WATER.substr(1):
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	return image

## The pack's palm sheet with every semi-transparent pixel (the shadows) recoloured PALM_SHADOW at its own alpha.
static func palms(source: Image) -> Image:
	var image := source.duplicate() as Image
	for y in image.get_height():
		for x in image.get_width():
			var a := image.get_pixel(x, y).a8
			if a > 0 and a < 255:
				var warm := Color(PALM_SHADOW)
				warm.a8 = a
				image.set_pixel(x, y, warm)
	return image

## Same size as `source`: at x >= BARE_SHIFT, the source pixel wherever it differs from the one BARE_SHIFT to
## its left; transparent everywhere else. Two pixels that are both alpha 0 never differ.
static func palm_crowns(source: Image) -> Image:
	var image := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in range(BARE_SHIFT, source.get_width()):
			var here := source.get_pixel(x, y)
			var bare := source.get_pixel(x - BARE_SHIFT, y)
			if not (here.a8 == 0 and bare.a8 == 0) and here != bare:
				image.set_pixel(x, y, here)
	return image

func _tiles() -> Image:
	var tiles := Image.create(16 * GROUND.size(), 16, false, Image.FORMAT_RGBA8)
	for kind in GROUND.size():
		var sheet := (load(GROUND[kind][0]) as Texture2D).get_image()
		sheet.convert(Image.FORMAT_RGBA8)
		tiles.blit_rect(sheet, Rect2i(GROUND[kind][1], Vector2i(16, 16)), Vector2i(16 * kind, 0))
	return tiles

## Draws a piece from its grid: every pixel fully opaque in its legend colour, or fully transparent.
func _piece(piece: Dictionary) -> Image:
	var grid: Array = piece["grid"]
	var image := Image.create((grid[0] as String).length(), grid.size(), false, Image.FORMAT_RGBA8)
	for y in grid.size():
		for x in (grid[y] as String).length():
			if grid[y][x] != ".":
				image.set_pixel(x, y, Color(piece["legend"][grid[y][x]]))
	return image

func _save(image: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := image.save_png(path)
	if err != OK:
		push_error("could not save %s: %s" % [path, error_string(err)])
