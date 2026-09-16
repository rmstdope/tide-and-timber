class_name CampFire
extends Node2D
## The built fire. Not solid. Lit when built; tr-b4o.6.2 puts it out.

var cell := Vector2i.ZERO
var lit := true

func _draw() -> void:
	CampArt.draw_fire(self, lit, false)
