class_name HintLine
extends RefCounted
## Draws DeviceHints items: pixel pictures and words, one row 9 px tall.

const HEIGHT := 9
const FONT_SIZE := 8
const GAP_PICTURE_PICTURE := 1
const GAP_PICTURE_WORD := 3
const GAP_WORD_PICTURE := 12
const RING := Color("#d8d0c0")
const CAP_SHADOW := Color("#a8977a")
const DISC: Array[Rect2] = [Rect2(2, 0, 5, 1), Rect2(1, 1, 7, 1), Rect2(0, 2, 9, 5), Rect2(1, 7, 7, 1),
	Rect2(2, 8, 5, 1)]
const INNER_DISC: Array[Rect2] = [Rect2(2, 1, 5, 1), Rect2(1, 2, 7, 5), Rect2(2, 7, 5, 1)]

static func picture_width(p: DeviceHints.Picture) -> int:
	if p.shape == DeviceHints.Shape.KEY:
		return Glyphs.width(p.label) + 6
	return HEIGHT

static func width(items: Array, font: Font) -> int:
	var total := 0
	for i in items.size():
		if i > 0:
			total += _gap(items[i - 1], items[i])
		total += _item_width(items[i], font)
	return total

static func draw_picture(canvas: CanvasItem, p: DeviceHints.Picture, at: Vector2) -> void:
	match p.shape:
		DeviceHints.Shape.KEY:
			var w := picture_width(p)
			canvas.draw_rect(Rect2(at.x, at.y, w, HEIGHT), p.face)
			canvas.draw_rect(Rect2(at.x, at.y + 8, w, 1), CAP_SHADOW)
		DeviceHints.Shape.ROUND:
			_rects(canvas, DISC, at, p.face)
		DeviceHints.Shape.STICK:
			_rects(canvas, DISC, at, RING)
			_rects(canvas, INNER_DISC, at, p.face)
	Glyphs.draw(canvas, p.label, at + Vector2(3, 2), p.ink)

## Draws the row with its top-left at `at`; words in word_colour with their baseline at at.y + 8.
static func draw(canvas: CanvasItem, items: Array, at: Vector2, font: Font, word_colour: Color) -> void:
	var x := at.x
	for i in items.size():
		if i > 0:
			x += _gap(items[i - 1], items[i])
		var item: Variant = items[i]
		if item is DeviceHints.Picture:
			draw_picture(canvas, item, Vector2(x, at.y))
		else:
			canvas.draw_string(font, Vector2(x, at.y + 8), str(item), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE,
				word_colour)
		x += _item_width(item, font)

static func _item_width(item: Variant, font: Font) -> int:
	if item is DeviceHints.Picture:
		return picture_width(item)
	return ceili(font.get_string_size(str(item), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)

static func _gap(before: Variant, after: Variant) -> int:
	var picture_before: bool = before is DeviceHints.Picture
	var picture_after: bool = after is DeviceHints.Picture
	if picture_before and picture_after:
		return GAP_PICTURE_PICTURE
	if picture_before:
		return GAP_PICTURE_WORD
	if picture_after:
		return GAP_WORD_PICTURE
	return 0

static func _rects(canvas: CanvasItem, rects: Array[Rect2], at: Vector2, colour: Color) -> void:
	for r in rects:
		canvas.draw_rect(Rect2(r.position + at, r.size), colour)
