@tool
class_name PixelPolygon
extends Node2D
## A filled polygon drawn in whole art pixels; stands in for Polygon2D.

@export var polygon := PackedVector2Array():
	set(value):
		polygon = value
		queue_redraw()
@export var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()

func _draw() -> void:
	for run in PixelRuns.polygon(polygon):
		draw_rect(run, color)
