class_name WaveWash
extends Node2D
## Pale foam running up the wet sand of the walkable beach and back, in whole pixels.

const FOAM_ROW := 15                    # BeachLayout's foam row; the wash runs up the wet sand above it
const FIRST_COLUMN := 16                # the walkable beach's columns, so it never runs over the headlands
const LAST_COLUMN := 167
const PERIOD_SECONDS := 4.0
const REACH := 10                       # px up the wet sand at the top of a wave
const WATER := Color("#bfe9ef")         # the FOAM tile's base colour
const EDGE := Color("#ffffff")

var elapsed := 0.0

static func reach_at(t: float) -> int:
	return roundi(REACH * (0.5 - 0.5 * cos(TAU * t / PERIOD_SECONDS)))

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var h := reach_at(elapsed)
	if h == 0:
		return
	var top := FOAM_ROW * BeachLayout.TILE - h
	var x := FIRST_COLUMN * BeachLayout.TILE
	var w := (LAST_COLUMN - FIRST_COLUMN + 1) * BeachLayout.TILE
	draw_rect(Rect2(x, top, w, h), WATER)
	draw_rect(Rect2(x, top, w, 1), EDGE)
