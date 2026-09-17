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
	[WATER, Vector2i(16, 192)],     # FOAM, then its surf line
	[WATER, Vector2i(16, 192)],     # SHALLOWS
	[WATER, Vector2i(96, 192)],     # DEEP
	[FLOORS, Vector2i(96, 160)],    # CLIFF
]
const SURF_EDGE := "#a3c8ee"
const SURF := "#7baadb"
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
	quit()

func _tiles() -> Image:
	var tiles := Image.create(16 * GROUND.size(), 16, false, Image.FORMAT_RGBA8)
	for kind in GROUND.size():
		var sheet := (load(GROUND[kind][0]) as Texture2D).get_image()
		sheet.convert(Image.FORMAT_RGBA8)
		tiles.blit_rect(sheet, Rect2i(GROUND[kind][1], Vector2i(16, 16)), Vector2i(16 * kind, 0))
	var foam := 16 * BeachLayout.Kind.FOAM
	tiles.fill_rect(Rect2i(foam, 0, 16, 1), Color(SURF_EDGE))
	tiles.fill_rect(Rect2i(foam, 1, 16, 2), Color(SURF))
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
