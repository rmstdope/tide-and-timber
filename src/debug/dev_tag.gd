class_name DevTag
extends Control
## The red DEV tag in the pause board's top-right corner, debug builds only.

const FILL := Color("#b8462e")
const TEXT := Color("#fff6e0")
const WORD := "DEV"

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FILL)
	Glyphs.draw(self, WORD, Vector2(roundi((size.x - Glyphs.width(WORD)) / 2.0), 1), TEXT)
