class_name KeyHint
extends Control
## The key hint band along the bottom while building, showing the device's pictures.

const TOP := 136.0
const HEIGHT := 12.0
const BAND := Color(0, 0, 0, 0.55)
const TEXT := Color("#fff6e0")

var view: HintView

func _ready() -> void:
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE
	view = HintView.new()
	view.word_colour = TEXT
	add_child(view)
	InputDevice.changed.connect(_layout)

## Shows the band for BUILD_LIST or PLACING, centred on the 320 px picture.
func show_hint(h: DeviceHints.Hint) -> void:
	view.hint = h
	_layout()
	show()

func text() -> String:
	return view.text()

func _layout() -> void:
	var w := view.line_width() + 8
	size = Vector2(w, HEIGHT)
	position = Vector2(roundi((320 - w) / 2.0), TOP)
	view.position = Vector2.ZERO
	view.size = size
	queue_redraw()
	view.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BAND)
