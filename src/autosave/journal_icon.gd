class_name JournalIcon
extends Control
## The 12x12 journal picture: the day was kept. Crossed out when it was not.

@export var crossed := false

func _init() -> void:
	custom_minimum_size = Vector2(12, 12)
	size = Vector2(12, 12)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 12, 12), Color("#3d5a80"))
	draw_rect(Rect2(0, 0, 2, 12), Color("#2a3f5c"))
	draw_rect(Rect2(3, 1, 8, 10), Color("#fff6e0"))
	for r in [Rect2(4, 3, 6, 1), Rect2(4, 5, 6, 1), Rect2(4, 7, 4, 1)]:
		draw_rect(r, Color("#8a7a6a"))
	if crossed:
		for run in PixelRuns.line(Vector2(0, 0), Vector2(12, 12), 2.0) + PixelRuns.line(Vector2(12, 0), Vector2(0, 12), 2.0):
			draw_rect(run, Color("#c0392b"))
