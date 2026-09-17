extends SceneTree
## Draws the man's art from the Pixel Crawler pack: its Body_A frames laid out a facing per row.
## Run: godot --headless --path . --script res://tools/pack_art/make_man_art.gd

const PACK := "res://assets/pixel_crawler/Entities/Characters/Body_A/Animations"
const FRAME := 64
## Our sheet -> [pack animation name, frame count]. Every sheet is four 64 px rows in Walk.Facing
## order: DOWN, UP, LEFT, RIGHT.
const SHEETS := {
	"idle": ["Idle", 4],
	"walk": ["Walk", 6],
	"run": ["Run", 6],
	"collect": ["Collect", 8],
}
## Walk.Facing -> the pack facing its row is built from. LEFT is RIGHT mirrored, so it is built last.
const DOWN := 0
const UP := 1
const LEFT := 2
const RIGHT := 3
const SOURCE_FACING := {DOWN: "Down", UP: "Up", RIGHT: "Side"}

func _init() -> void:
	for name_: String in SHEETS:
		_save(_sheet(SHEETS[name_][0], SHEETS[name_][1]), "res://assets/man/%s.png" % name_)
	quit()

## One animation's four rows: the pack's Down, Up and Side frames, then Side mirrored for LEFT.
func _sheet(anim: String, frames: int) -> Image:
	var sheet := Image.create(FRAME * frames, FRAME * 4, false, Image.FORMAT_RGBA8)
	for row: int in [DOWN, UP, RIGHT]:
		var source := _pack(anim, SOURCE_FACING[row])
		for frame in frames:
			sheet.blit_rect(source, Rect2i(FRAME * frame, 0, FRAME, FRAME),
				Vector2i(FRAME * frame, FRAME * row))
	for frame in frames:
		sheet.blit_rect(_mirrored(sheet, frame, RIGHT), Rect2i(0, 0, FRAME, FRAME),
			Vector2i(FRAME * frame, FRAME * LEFT))
	return sheet

## One finished frame of `row`, flipped left to right.
func _mirrored(sheet: Image, frame: int, row: int) -> Image:
	var one := Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)
	one.blit_rect(sheet, Rect2i(FRAME * frame, FRAME * row, FRAME, FRAME), Vector2i.ZERO)
	one.flip_x()
	return one

func _pack(anim: String, facing: String) -> Image:
	var image := (load("%s/%s_Base/%s_%s-Sheet.png" % [PACK, anim, anim, facing]) as Texture2D).get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image

func _save(image: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := image.save_png(path)
	if err != OK:
		push_error("could not save %s: %s" % [path, error_string(err)])
