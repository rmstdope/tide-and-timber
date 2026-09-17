class_name PackPalette
extends RefCounted
## The game's palette: every colour of a fully opaque pixel in the pack sheets the game imports.

const SHEETS: Array[String] = [
	"res://assets/pixel_crawler/Environment/Tilesets/Floors_Tiles.png",
	"res://assets/pixel_crawler/Environment/Tilesets/Water_tiles.png",
	"res://assets/pixel_crawler/Environment/Props/Static/Vegetation.png",
	"res://assets/pixel_crawler/Environment/Props/Static/Rocks.png",
]

static var _colours: Dictionary = {}

## Lower-case 6-digit hex (Color.to_html(false)) -> true, for every pixel with a == 1.0 in SHEETS.
static func colours() -> Dictionary:
	if _colours.is_empty():
		for path in SHEETS:
			var image := (load(path) as Texture2D).get_image()
			for y in image.get_height():
				for x in image.get_width():
					var c := image.get_pixel(x, y)
					if c.a == 1.0:
						_colours[c.to_html(false)] = true
	return _colours

## Whether `colour`, alpha ignored, is one of colours().
static func has(colour: Color) -> bool:
	return colours().has(colour.to_html(false))
