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
	for run in PixelRuns.arc(CENTER, RADIUS, WIDTH, 0.0, TAU):
		draw_rect(run, TRACK)
	if progress > 0.0:
		for run in PixelRuns.arc(CENTER, RADIUS, WIDTH, -PI / 2, -PI / 2 + TAU * progress):
			draw_rect(run, FILL)
