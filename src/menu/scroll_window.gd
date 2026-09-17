class_name ScrollWindow
extends RefCounted
## Keeps a list's highlighted item inside its visible band, and draws the ▲ / ▼ marks where rows are hidden.
## Node-free, so every scrolling list shares one rule. Values are in the list's own units,
## except strip_top, which is on screen.

const EDGE := 2.0            # on screen: the band's top, and the gap kept above the Select / Back strip
const MARK_ROW := 10.0       # list units: one row kept at the top and one at the bottom for the marks
const MARK_FONT_SIZE := 8
const EPSILON := 0.001

## The new offset (whole units the content is moved up) that shows the item [item_top, item_bottom].
## 0 when content <= band. Unchanged while the whole item is visible. If the item is taller than the band,
## its top. Otherwise moved the least distance that shows all of it. Always clamped to 0 .. ceili(content - band).
static func follow(content: float, band_h: float, item_top: float, item_bottom: float, offset: int) -> int:
	if content <= band_h:
		return 0
	var o := offset
	if item_bottom - item_top > band_h:
		o = floori(item_top)
	elif item_top < o:
		o = floori(item_top)
	elif item_bottom > o + band_h:
		o = ceili(item_bottom - band_h)
	return clampi(o, 0, ceili(content - band_h))

## True while content is hidden above.
static func hidden_above(offset: int) -> bool:
	return offset > 0

## True while content is hidden below.
static func hidden_below(offset: int, content: float, band_h: float) -> bool:
	return offset + band_h < content

## The visible band (top, bottom) in the local units of the node whose canvas transform is given:
## from on-screen y EDGE to on-screen y strip_top - EDGE, rounded inwards to whole units.
static func band(canvas_transform: Transform2D, strip_top: float) -> Vector2:
	var inv := canvas_transform.affine_inverse()
	return Vector2(ceilf((inv * Vector2(0, EDGE)).y - EPSILON),
			floorf((inv * Vector2(0, strip_top - EDGE)).y + EPSILON))

## The baseline origin that centres one mark glyph on centre.
static func mark_origin(font: Font, centre: Vector2, up: bool) -> Vector2:
	var glyph := "▲" if up else "▼"
	var w := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_FONT_SIZE).x
	return Vector2(roundf(centre.x - w / 2.0),
			roundf(centre.y - font.get_height(MARK_FONT_SIZE) / 2.0 + font.get_ascent(MARK_FONT_SIZE)))

## Draws ▲ (up) or ▼ centred on centre, in canvas's units, in ControlsPage.QUIET.
## Call only while canvas draws: drawing outside a draw notification errors.
## canvas is a Control, not any CanvasItem, because the mark takes the theme's default font.
## A list drawn on a bare CanvasItem needs a font passed in instead.
static func draw_mark(canvas: Control, centre: Vector2, up: bool) -> void:
	var font: Font = canvas.get_theme_default_font()
	canvas.draw_string(font, mark_origin(font, centre, up), "▲" if up else "▼",
			HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_FONT_SIZE, ControlsPage.QUIET)
