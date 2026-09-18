class_name JournalIcon
extends Control
## The 12x12 journal picture: the day was kept. Crossed out when it was not.

@export var crossed := false

func _init() -> void:
	custom_minimum_size = Vector2(12, 12)
	size = Vector2(12, 12)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 12, 12), HudColours.JOURNAL_COVER)
	draw_rect(Rect2(0, 0, 2, 12), HudColours.JOURNAL_SPINE)
	draw_rect(Rect2(3, 1, 8, 10), HudColours.JOURNAL_PAGE)
	for r in [Rect2(4, 3, 6, 1), Rect2(4, 5, 6, 1), Rect2(4, 7, 4, 1)]:
		draw_rect(r, HudColours.JOURNAL_WRITING)
	if crossed:
		for run in PixelRuns.line(Vector2(0, 0), Vector2(12, 12), 2.0) + PixelRuns.line(Vector2(12, 0), Vector2(0, 12), 2.0):
			draw_rect(run, HudColours.JOURNAL_MISSED)
