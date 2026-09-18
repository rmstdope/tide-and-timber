class_name MorningCardView
extends Control
## The wooden card in the middle of the screen: one centred line per string.

const WIDTH := 160
const LINE_HEIGHT := 12
const PAD_TOP := 6
const PAD_BOTTOM := 6
const PAD_SIDE := 8                 # the slack the card has always kept each side of its words
const BORDER := HudColours.WOOD_DARK
const FILL := HudColours.WOOD
const TEXT := HudColours.PALE
const HEADING := HudColours.CREAM

var labels: Array[Label] = []

## The card's height for that many drawn lines, at relative text scale rel.
static func height_for(line_count: int, rel := 1.0) -> int:
	return PAD_TOP + line_count * (LINE_HEIGHT + int(TextScale.extra(LINE_HEIGHT, rel))) + PAD_BOTTOM

func _ready() -> void:
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE
	Display.changed.connect(relayout)
	get_tree().root.size_changed.connect(relayout)

func show_lines(lines: Array[String]) -> void:
	for l in labels:
		l.queue_free()
	labels.clear()
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i]
		l.add_theme_font_size_override(&"font_size", 8)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = MOUSE_FILTER_IGNORE
		l.add_theme_color_override(&"font_color", HEADING if i == 1 and lines.size() > 2 else TEXT)
		add_child(l)
		labels.append(l)
	relayout()

## Sizes and places the card and its words for the current UI size and Text size: the card widens to its
## grown words, up to nearly the screen, then its lines wrap and it grows taller.
func relayout() -> void:
	var ui := 1.0
	var rel := 1.0
	if is_inside_tree():
		ui = UiScale.current(Display.prefs, get_tree().root)
		rel = TextScale.relative(Display.prefs, get_tree().root)
	var words := 0.0
	var unwrapped: Array[float] = []
	for l in labels:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.scale = Vector2.ONE
		l.update_minimum_size()
		unwrapped.append(ceilf(l.get_minimum_size().x * rel))
		words = maxf(words, unwrapped[-1])
	var w := TextScale.fit_width(WIDTH, words + 2.0 * PAD_SIDE, ui)
	var inner := w - 2.0 * PAD_SIDE
	var row := LINE_HEIGHT + TextScale.extra(LINE_HEIGHT, rel)
	var drawn := 0
	for i in labels.size():
		var l := labels[i]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if inner < unwrapped[i] else TextServer.AUTOWRAP_OFF
		l.scale = Vector2.ONE * rel
		l.position = Vector2(PAD_SIDE, PAD_TOP + drawn * row)
		l.size = Vector2(inner / rel, 8)
		l.update_minimum_size()
		l.size = Vector2(inner / rel, 8)
		drawn += maxi(1, l.get_line_count())
	size = Vector2(w, height_for(drawn, rel))
	position = Vector2(roundi((320 - w) / 2.0), roundi((180 - size.y) / 2.0))
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BORDER)
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), FILL)
