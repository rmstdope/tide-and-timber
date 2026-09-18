class_name BuildGhost
extends Node2D
## The see-through outline while placing.

const ALPHA := 0.55

var thing: BuildMenu.Thing = BuildMenu.Thing.LEAN_TO
var ok := true

func _ready() -> void:
	hide()
	z_index = 10
	modulate.a = ALPHA

func show_at(p_thing: BuildMenu.Thing, origin: Vector2, p_ok: bool) -> void:
	thing = p_thing
	ok = p_ok
	position = origin
	show()
	queue_redraw()

## True when the outline carries the ✕: any spot he cannot build on, whatever Colour cues says.
func shows_cross() -> bool:
	return not ok

func _draw() -> void:
	if thing == BuildMenu.Thing.LEAN_TO:
		CampArt.draw_lean_to(self, not ok)
	else:
		CampArt.draw_fire(self, false, not ok)
	if shows_cross():
		CampArt.draw_cross(self, CampArt.LEAN_TO_CROSS if thing == BuildMenu.Thing.LEAN_TO else CampArt.FIRE_CROSS)
