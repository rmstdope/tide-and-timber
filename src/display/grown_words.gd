class_name GrownWords
extends Control
## Holds one Label, its child `Words`, and grows those words by Text size where a container lays them out.
## A container resets a scale set on its own child, so the container lays this node out and the Label inside
## keeps its scale. Its minimum size is its Normal cell grown by TextScale.relative.
## Past max_width the words wrap and it grows taller.

@export var normal_size := Vector2.ZERO   # the cell at Text size Normal, words included (e.g. 64x12 for a value)

## The widest this node may be, in its parent's units; the host's layout sets it. INF: never wraps. Setting it refits.
var max_width := INF:
	set(value):
		max_width = value
		refit()

var rel := 1.0          # the words' scale now; derived by refit()
var wrapped := false    # the words are on more than one line; derived by refit()
var _min := Vector2.ZERO

## The Label's text. Setting it refits.
var text: String:
	get:
		return words().text
	set(value):
		words().text = value
		refit()

## The Label inside.
func words() -> Label:
	return get_node("Words") as Label

## How many lines `t` takes at `width`, as an autowrap-smart Label draws it.
static func line_count(t: String, width: float, font: Font, font_size: int) -> int:
	var p := TextParagraph.new()
	p.add_string(t, font, font_size)
	p.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	p.width = width
	return p.get_line_count()

func _get_minimum_size() -> Vector2:
	return _min

func _ready() -> void:
	resized.connect(_place_words)
	Display.changed.connect(refit)
	get_tree().root.size_changed.connect(refit)
	refit()

## Re-measures the words at the current Text size and max_width, sets the minimum size, and places the Label.
func refit() -> void:
	if not is_node_ready():
		return
	rel = TextScale.relative(Display.prefs, get_tree().root) if is_inside_tree() else 1.0
	var w := words()
	w.autowrap_mode = TextServer.AUTOWRAP_OFF
	w.scale = Vector2.ONE
	w.size = Vector2.ZERO
	var m := w.get_minimum_size()
	var width := ceilf(maxf(normal_size.x, m.x) * rel)
	var words_h := m.y
	wrapped = width > max_width
	if wrapped:
		width = max_width
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var n := line_count(w.text, width / rel, w.get_theme_font("font"), w.get_theme_font_size("font_size"))
		words_h = n * m.y + (n - 1) * w.get_theme_constant("line_spacing")
	_min = Vector2(width, maxf(normal_size.y - m.y, 0.0) + ceilf(words_h * rel))
	update_minimum_size()
	_place_words()

func _place_words() -> void:
	var w := words()
	w.position = Vector2.ZERO
	w.scale = Vector2.ONE * rel
	w.size = size / rel
