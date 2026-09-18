extends SceneTree
## Draws the five item icons in the Pixel Crawler pack's colours and shading: each one's ramp is the
## beach prop it stands for, so a coconut in the bar is the coconut on the ground.
## Run: godot --headless --path . --script res://tools/pack_art/make_item_art.gd

## Each icon: its grid, one string per row, "." transparent, and its legend of character -> colour.
## Every grid is ten rows of ten characters — ItemSlot blits a 10x10 icon at (3, 2) inside a 16x16
## slot, and the stack count sits at y 10.
const PIECES := {
	"res://assets/items/driftwood.png": {
		"legend": {"o": "#281c0d", "d": "#5e5245", "m": "#8b8279", "h": "#968780"},
		"grid": [
			"..........",
			"....oo....",
			"...ohmo...",
			"...ohmo...",
			"oooohmoooo",
			"ohhhhhhhdo",
			"ommmmmmmdo",
			"oddddddddo",
			"oooooooooo",
			"..........",
		],
	},
	"res://assets/items/coconut.png": {
		"legend": {"o": "#281c0d", "d": "#4b2a1b", "m": "#6c4326", "h": "#865932"},
		"grid": [
			"..........",
			"...oooo...",
			"..ohhhmo..",
			".ohhmmmdo.",
			".ohmmmmdo.",
			".ommmmddo.",
			".ommdddddo",
			"..odddo...",
			"...ooo....",
			"..........",
		],
	},
	"res://assets/items/shellfish.png": {
		"legend": {"o": "#281c0d", "d": "#a48477", "m": "#c6ab9f", "l": "#ffcdb4"},
		"grid": [
			"..........",
			"..oooooo..",
			".ollldllo.",
			"olldlldllo",
			"olmdmmdmlo",
			"olmdmmdmlo",
			"oddddddddo",
			".oooooooo.",
			"..........",
			"..........",
		],
	},
	"res://assets/items/empty_shell.png": {
		"legend": {"o": "#281c0d", "d": "#a48477", "m": "#c6ab9f", "l": "#ffcdb4", "k": "#4b2a1b"},
		"grid": [
			"..........",
			"..oooooo..",
			".okkkkkko.",
			"olkkkkkklo",
			"olmkkkkmlo",
			"olmmmmmmlo",
			".ommmmmmo.",
			"..oddddo..",
			"...oooo...",
			"..........",
		],
	},
	"res://assets/items/fresh_water.png": {
		"legend": {"o": "#281c0d", "d": "#a48477", "m": "#c6ab9f", "l": "#ffcdb4",
			"s": "#4185ca", "w": "#4498d1", "g": "#a3c8ee"},
		"grid": [
			"..........",
			"..oooooo..",
			".ogwwwwgo.",
			"olwwwwwwlo",
			"olmswwsmlo",
			"olmmmmmmlo",
			".ommmmmmo.",
			"..oddddo..",
			"...oooo...",
			"..........",
		],
	},
}

func _init() -> void:
	for path: String in PIECES:
		_save(_piece(PIECES[path]), path)
	quit()

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
