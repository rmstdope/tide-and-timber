class_name SkipRing
extends Control
## The hold-to-skip ring: a track circle with a fill arc clockwise from the top.

const TRACK := Color("#6b7396")
const FILL := Color("#ffd58a")
const CENTER := Vector2(5, 5)
const RADIUS := 4.0
const WIDTH := 2.0

var progress := 0.0:                    # 0..1; setting it calls queue_redraw()
	set(value):
		progress = value
		queue_redraw()

func _draw() -> void:
	draw_arc(CENTER, RADIUS, 0.0, TAU, 24, TRACK, WIDTH, false)
	if progress > 0.0:
		draw_arc(CENTER, RADIUS, -PI / 2, -PI / 2 + TAU * progress, 24, FILL, WIDTH, false)
