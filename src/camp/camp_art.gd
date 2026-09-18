class_name CampArt
extends RefCounted
## Placeholder drawings of the lean-to and fire, relative to their origin (bottom-centre of the base).

const WOOD_DARK := HudColours.WOOD_DARK
const WOOD := HudColours.WOOD
const WOOD_LIGHT := HudColours.WOOD_LIGHT
const FLAME := Color("#ff9a2a")
const FLAME_CORE := Color("#ffe06a")
const RED := HudColours.BAD
const ASH_DARK := Color("#6a625c")
const ASH := Color("#8a827a")
const PALE := HudColours.CROSS

## The square box of the ✕ on each drawing, relative to its origin. Odd sides, so the ✕ has one middle pixel.
const LEAN_TO_CROSS := Rect2i(-5, -25, 11, 11)   # middle (0, -20): the middle of the lean-to
const FIRE_CROSS := Rect2i(-3, -8, 7, 7)         # middle (0, -5): the middle of the unlit fire

static func draw_lean_to(canvas: CanvasItem, red: bool) -> void:
	_rect(canvas, Rect2(-22, -5, 44, 4), WOOD_DARK, red)
	for i in 5:
		_rect(canvas, Rect2(-22 + 8 * i, -9 - 6 * i, 12, 6), WOOD, red)
		_rect(canvas, Rect2(-20 + 8 * i, -9 - 6 * i, 6, 2), WOOD_LIGHT, red)
	_rect(canvas, Rect2(15, -40, 3, 36), WOOD_DARK, red)

static func draw_fire(canvas: CanvasItem, lit: bool, red: bool) -> void:
	_rect(canvas, Rect2(-7, -5, 14, 3), WOOD_DARK, red)
	_rect(canvas, Rect2(-5, -7, 10, 3), WOOD, red)
	if lit:
		_rect(canvas, Rect2(-4, -11, 8, 4), FLAME, red)
		_rect(canvas, Rect2(-2, -15, 4, 4), FLAME, red)
		_rect(canvas, Rect2(-2, -10, 4, 3), FLAME_CORE, red)
		_rect(canvas, Rect2(-1, -13, 2, 3), FLAME_CORE, red)

## The small pile of ash a burnt-out fire leaves, relative to the fire's origin.
static func draw_ash(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(-7, -5, 14, 3), ASH_DARK)
	canvas.draw_rect(Rect2(-4, -7, 8, 2), ASH)

## The pixels of a one-pixel-wide ✕ filling box corner to corner, each pixel once.
static func cross_cells(box: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var n := box.size.x
	for i in n:
		cells.append(box.position + Vector2i(i, i))
		if i != n - 1 - i:
			cells.append(box.position + Vector2i(n - 1 - i, i))
	return cells

## Draws the ✕ in PALE, one 1x1 rect per cell, so the ghost's alpha stays even along it.
static func draw_cross(canvas: CanvasItem, box: Rect2i) -> void:
	for c in cross_cells(box):
		canvas.draw_rect(Rect2(c.x, c.y, 1, 1), PALE)

static func _rect(canvas: CanvasItem, rect: Rect2, colour: Color, red: bool) -> void:
	canvas.draw_rect(rect, RED if red else colour)
