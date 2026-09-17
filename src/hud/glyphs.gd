class_name Glyphs
extends RefCounted
## A tiny 3x5 pixel alphabet for slot counts and hint pictures, crisp at any font.

const SHEET := preload("res://assets/hud/glyphs.png")   # 4 * ORDER.length() x 5, white on transparent
# glyph i sits at x = 4 * i; new glyphs are appended so existing ones keep their place
const ORDER := "0123456789EABDLSWXYsc✕○△CFGHIJKMNOPQRTUVZabdefghijklmnopqrtuvwxyz-=[]\\;',./`+*□↑↓←→—!:"
const W := 3
const H := 5
const GAP := 1

static func width(text: String) -> int:
	return text.length() * W + maxi(text.length() - 1, 0) * GAP

## Draws `text` with its top-left at `at`; characters not in ORDER are skipped.
static func draw(canvas: CanvasItem, text: String, at: Vector2, colour: Color) -> void:
	var x := at.x
	for c in text:
		var i := ORDER.find(c)
		if i >= 0:
			canvas.draw_texture_rect_region(SHEET, Rect2(x, at.y, W, H), Rect2(4 * i, 0, W, H), colour)
		x += W + GAP
