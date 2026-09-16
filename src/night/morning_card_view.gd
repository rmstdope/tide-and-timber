class_name MorningCardView
extends Control
## The wooden card in the middle of the screen: one centred line per string.

const WIDTH := 160
const LINE_HEIGHT := 12
const PAD_TOP := 6
const PAD_BOTTOM := 6
const BORDER := Color("#5c3a22")
const FILL := Color("#8a5a34")
const TEXT := Color("#fff6e0")
const HEADING := Color("#e8d7c0")

var labels: Array[Label] = []

static func height_for(line_count: int) -> int:
	return PAD_TOP + line_count * LINE_HEIGHT + PAD_BOTTOM

func _ready() -> void:
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE

func show_lines(lines: Array[String]) -> void:
	for l in labels:
		l.queue_free()
	labels.clear()
	size = Vector2(WIDTH, height_for(lines.size()))
	position = Vector2(roundi((320 - WIDTH) / 2.0), roundi((180 - size.y) / 2.0))
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i]
		l.position = Vector2(0, PAD_TOP + i * LINE_HEIGHT)
		l.size = Vector2(WIDTH, 8)
		l.add_theme_font_size_override(&"font_size", 8)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = MOUSE_FILTER_IGNORE
		l.add_theme_color_override(&"font_color", HEADING if i == 1 and lines.size() > 2 else TEXT)
		add_child(l)
		labels.append(l)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BORDER)
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), FILL)
