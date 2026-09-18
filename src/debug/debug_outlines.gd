class_name DebugOutlines
extends Node2D
## Red outlines of solid things and blue circles of use areas, in world coordinates.

const SOLID := Color("#ff3b3b")
const USE := Color("#3bd1ff")
const USE_SEGMENTS := 32

var beach: Beach

func _process(_delta: float) -> void:
	visible = DebugSwitches.collision_areas or DebugSwitches.use_areas
	if visible:
		queue_redraw()

func _draw() -> void:
	if DebugSwitches.collision_areas:
		var edges := DebugShow.tile_edges(DebugShow.cells_in(view()),
				func(c: Vector2i) -> bool: return BeachLayout.is_solid(BeachLayout.kind_at(c)))
		if not edges.is_empty():
			draw_multiline(edges, SOLID, 1.0)
		for r in DebugShow.solid_rects(beach.get_node("%World")):
			draw_rect(r.grow(-0.5), SOLID, false, 1.0)
	if DebugSwitches.use_areas:
		for spot in DebugShow.use_spots(get_tree()):
			draw_arc(spot, Reach.DISTANCE, 0.0, TAU, USE_SEGMENTS, USE, 1.0)

## The global px rectangle the beach camera shows.
func view() -> Rect2:
	var camera := beach.get_node("%Camera") as Node2D
	return Rect2(camera.global_position - Screen.CENTRE, Screen.SIZE)
