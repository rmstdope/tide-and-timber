class_name KeyHint
extends Control
## The key hint band along the bottom while building, showing the device's pictures.
## Lifts above the item bar at larger sizes when it would cover it.

const TOP := 136.0
const HEIGHT := 12.0
const BAND := Color(0, 0, 0, 0.55)
const TEXT := HudColours.PALE

var view: HintView

func _ready() -> void:
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE
	view = HintView.new()
	view.word_colour = TEXT
	add_child(view)
	InputDevice.changed.connect(_layout)
	Display.changed.connect(_layout_later)
	get_tree().root.size_changed.connect(_layout_later)

## Shows the band for BUILD_LIST or PLACING, centred on the 320 px picture.
func show_hint(h: DeviceHints.Hint) -> void:
	view.hint = h
	_layout()
	show()

func text() -> String:
	return view.text()

func _layout() -> void:
	var w := view.line_width() + 8
	var h := HEIGHT + view.grown_by()
	size = Vector2(w, h)
	position.x = roundi((320 - w) / 2.0)
	HintLift.place(self, TOP + HEIGHT - h, HEIGHT)
	view.position = Vector2.ZERO
	view.size = size
	queue_redraw()
	view.queue_redraw()

# Deferred: the hint's and the bar's UiScale nodes set their layers from the same signals.
func _layout_later() -> void:
	_layout.call_deferred()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BAND)
