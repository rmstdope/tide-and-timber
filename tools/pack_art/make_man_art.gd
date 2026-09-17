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

## The fall is its own sheet: 8 frames of Death_<facing>, the same four rows. It is built apart from
## SHEETS because from frame 3 on he leaves the upright body box, so the shared band table - which
## dresses a standing figure by head and body zone - says nothing useful about him.
const DEATH_FRAMES := 8

## The pack's own four body tones, light to dark. Never written out: his skin stays the pack's.
const SKIN: Array[String] = ["fac895", "d9a066", "a26543", "763d2b"]
## What he is dressed in, each light to dark against SKIN. Every one is a colour PackPalette already
## holds, so the pack's palette stays the game's.
const SHIRT: Array[String] = ["dfe3ed", "ced8ed", "b4c4e4", "adbcdb"]
const TROUSERS: Array[String] = ["4c8cce", "3b7ec2", "004d83", "0e325d"]
const HAIR: Array[String] = ["663b27", "4b2a1b", "301d0e", "160f09"]
## Stubble is SKIN one step darker: a shadow on his jaw that brings in no new colour.
const STUBBLE: Array[String] = ["d9a066", "a26543", "763d2b", "763d2b"]

## His head is the same rigid 14 rows in every frame the pack draws, so a frame's head zone is the
## 14 rows from the top of him and its body zone is everything below. A band sits in one of them:
## a head band shifts with him, a body band stretches with the body zone, which is what lets one
## table dress a standing frame and a deep crouch alike.
enum Zone { HEAD, BODY }
const HEAD_ROWS := 14
## Where Idle_<facing> frame 0 puts him, the coordinates every band below is written in.
const REFERENCE_TOP := 18
const REFERENCE_BODY := 32
const REFERENCE_BODY_ROWS := 16
## Rows of him left bare at the bottom whatever the band table says, so his feet never wear trousers.
const BARE_FEET_ROWS := 2

## Per source facing, the rectangles of him that are painted, in Idle frame 0 coordinates:
## [rect, ramp, zone, torn]. `torn` paints only every second column of the rect's bottom row, which
## is what makes the shirt's hem ragged. The rects stop short of his shoulders, his swinging arms
## and his feet, which stay the pack's own skin: that is what sleeveless, rolled and barefoot mean.
const BANDS := {
	"Down": [
		[Rect2i(26, 18, 12, 7), HAIR, Zone.HEAD, false],        # crown down to his brows
		[Rect2i(26, 29, 12, 2), STUBBLE, Zone.HEAD, false],     # the jaw below his eyes
		[Rect2i(29, 32, 6, 7), SHIRT, Zone.BODY, true],         # torso only: the arms fall outside
		[Rect2i(28, 39, 8, 5), TROUSERS, Zone.BODY, false],     # hips to the knee: rolled
	],
	"Up": [
		[Rect2i(26, 18, 12, 13), HAIR, Zone.HEAD, false],       # the whole back of his head
		[Rect2i(29, 32, 6, 7), SHIRT, Zone.BODY, true],
		[Rect2i(28, 39, 8, 5), TROUSERS, Zone.BODY, false],
	],
	"Side": [
		[Rect2i(25, 18, 13, 8), HAIR, Zone.HEAD, false],        # crown and fringe
		[Rect2i(25, 26, 5, 3), HAIR, Zone.HEAD, false],         # and down the back of his head
		[Rect2i(30, 27, 8, 4), STUBBLE, Zone.HEAD, false],      # cheek and jaw, clear of the eye
		[Rect2i(28, 32, 8, 3), SHIRT, Zone.BODY, false],        # the shoulders' width
		[Rect2i(29, 35, 7, 4), SHIRT, Zone.BODY, true],         # narrower below, so the arm stays bare
		[Rect2i(28, 39, 11, 5), TROUSERS, Zone.BODY, false],    # both legs, the far one included
	],
}

func _init() -> void:
	for name_: String in SHEETS:
		_save(_sheet(SHEETS[name_][0], SHEETS[name_][1]), "res://assets/man/%s.png" % name_)
	_save(_death_sheet(), "res://assets/man/death.png")
	quit()

## The fall's four rows: the pack's Death Down, Up and Side frames, then Side mirrored for LEFT.
func _death_sheet() -> Image:
	var sheet := Image.create(FRAME * DEATH_FRAMES, FRAME * 4, false, Image.FORMAT_RGBA8)
	for row: int in [DOWN, UP, RIGHT]:
		var facing: String = SOURCE_FACING[row]
		var source := _pack("Death", facing)
		for frame in DEATH_FRAMES:
			sheet.blit_rect(source, Rect2i(FRAME * frame, 0, FRAME, FRAME),
				Vector2i(FRAME * frame, FRAME * row))
	for frame in DEATH_FRAMES:
		sheet.blit_rect(_mirrored(sheet, frame, RIGHT), Rect2i(0, 0, FRAME, FRAME),
			Vector2i(FRAME * frame, FRAME * LEFT))
	return sheet

## One animation's four rows: the pack's Down, Up and Side frames, then Side mirrored for LEFT.
func _sheet(anim: String, frames: int) -> Image:
	var sheet := Image.create(FRAME * frames, FRAME * 4, false, Image.FORMAT_RGBA8)
	for row: int in [DOWN, UP, RIGHT]:
		var facing: String = SOURCE_FACING[row]
		var source := _pack(anim, facing)
		for frame in frames:
			var at := Vector2i(FRAME * frame, FRAME * row)
			sheet.blit_rect(source, Rect2i(FRAME * frame, 0, FRAME, FRAME), at)
			_dress(sheet, at, BANDS[facing])
	for frame in frames:
		sheet.blit_rect(_mirrored(sheet, frame, RIGHT), Rect2i(0, 0, FRAME, FRAME),
			Vector2i(FRAME * frame, FRAME * LEFT))
	return sheet

## Paints one 64x64 frame at `at`: every pixel of a band that is one of the pack's skin tones becomes
## the same step of that band's ramp. The black outline, his eyes and every transparent pixel are left
## exactly as the pack drew them, so his silhouette and shading stay the pack's throughout.
func _dress(sheet: Image, at: Vector2i, bands: Array) -> void:
	var box := _figure(sheet, at)
	var top := box.position.y
	var bottom := box.end.y - 1
	var body := top + HEAD_ROWS                 # the first row below his head
	var body_rows := bottom - body + 1
	for band: Array in bands:
		var rect: Rect2i = band[0]
		var ramp: Array[String] = band[1]
		var head_band: bool = band[2] == Zone.HEAD
		var first := rect.position.y
		var last := rect.end.y - 1
		if head_band:
			first += top - REFERENCE_TOP
			last += top - REFERENCE_TOP
		else:
			first = body + _scaled(first, body_rows)
			last = body + _scaled(last, body_rows)
		if ramp == TROUSERS:
			last = mini(last, bottom - BARE_FEET_ROWS)
		for y in range(first, last + 1):
			if y < 0 or y >= FRAME:
				continue
			for x in range(rect.position.x, rect.end.x):
				if band[3] and y == last and (x - rect.position.x) % 2 != 0:
					continue
				var step := SKIN.find(sheet.get_pixel(at.x + x, at.y + y).to_html(false))
				if step >= 0:
					sheet.set_pixel(at.x + x, at.y + y, Color(ramp[step]))

## A reference body-zone row, as a row of a body zone `rows` tall.
func _scaled(y: int, rows: int) -> int:
	return roundi(float(y - REFERENCE_BODY) * rows / REFERENCE_BODY_ROWS)

## The bounding box of the opaque pixels of the 64x64 frame at `at`, in frame coordinates.
func _figure(sheet: Image, at: Vector2i) -> Rect2i:
	var top := FRAME
	var bottom := -1
	for y in FRAME:
		for x in FRAME:
			if sheet.get_pixel(at.x + x, at.y + y).a > 0.0:
				top = mini(top, y)
				bottom = maxi(bottom, y)
				break
	return Rect2i(0, top, FRAME, bottom - top + 1)

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
