class_name LeanTo
extends StaticBody2D
## The built lean-to: solid, drawn by CampArt.

var cells: Array[Vector2i] = []          # its 6 cells; set before add_child

func anchor() -> Vector2i:
	return BuildSite.anchor_of(cells)

func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 32)
	var base := CollisionShape2D.new()
	base.name = "Base"
	base.shape = shape
	base.position = Vector2(0, -16)
	add_child(base)

func _draw() -> void:
	CampArt.draw_lean_to(self, false)
