class_name KeyHint
extends Control
## The key hint band along the bottom while building.

const TOP := 136.0
const HEIGHT := 12.0
const BAND := Color(0, 0, 0, 0.55)
const TEXT := Color("#fff6e0")
const LIST_TEXT := "E or click: Build   Esc: Close"
const PLACING_TEXT := "E or click: Place   Esc: Back"

var label: Label

func _ready() -> void:
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE
	label = Label.new()
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", 8)
	label.add_theme_color_override(&"font_color", TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

func show_text(text: String) -> void:
	label.text = text
	var w := text.length() * 8 + 8
	size = Vector2(w, HEIGHT)
	position = Vector2(roundi((320 - w) / 2.0), TOP)
	label.position = Vector2.ZERO
	label.size = size
	show()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BAND)
