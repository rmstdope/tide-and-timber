class_name MenuStrip
extends Control
## A menu's Select / Back strip in the bottom-left corner, in the pictures of the device used last.

const LEFT := 4.0      # the version number's inset from the right edge, mirrored
const BOTTOM := 176.0  # level with the bottom of the title's version number

var view: HintView

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	view = HintView.new()
	view.word_colour = KeyHint.TEXT
	view.hint = DeviceHints.Hint.SELECT
	add_child(view)
	InputDevice.changed.connect(_layout)
	_layout()

## Which line to show: DeviceHints.Hint.SELECT or SELECT_BACK. Lays out at once.
func show_hint(h: DeviceHints.Hint) -> void:
	view.hint = h
	_layout()

## The line in the agreed notation, e.g. "[Enter] Select".
func text() -> String:
	return view.text()

func _layout() -> void:
	var w := view.line_width() + 8
	size = Vector2(w, KeyHint.HEIGHT)
	position = Vector2(LEFT, BOTTOM - KeyHint.HEIGHT)
	view.position = Vector2.ZERO
	view.size = size
	queue_redraw()
	view.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), KeyHint.BAND)
