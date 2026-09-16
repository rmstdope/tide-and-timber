class_name CampArt
extends RefCounted
## Placeholder drawings of the lean-to and fire, relative to their origin (bottom-centre of the base).

const WOOD_DARK := Color("#5c3a22")
const WOOD := Color("#8a5a34")
const WOOD_LIGHT := Color("#b98452")
const FLAME := Color("#ff9a2a")
const FLAME_CORE := Color("#ffe06a")
const RED := Color("#e0503a")
const ASH_DARK := Color("#6a625c")
const ASH := Color("#8a827a")

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

static func _rect(canvas: CanvasItem, rect: Rect2, colour: Color, red: bool) -> void:
	canvas.draw_rect(rect, RED if red else colour)
