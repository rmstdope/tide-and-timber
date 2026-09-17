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

func _init() -> void:
	_save(_tiles(), "res://assets/beach/tiles.png")
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

func _save(image: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := image.save_png(path)
	if err != OK:
		push_error("could not save %s: %s" % [path, error_string(err)])
