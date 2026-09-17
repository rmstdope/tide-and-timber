class_name MenuStrip
extends Control
## A menu's Select / Back strip in the bottom-left corner, in the pictures of the device used last.
## Grows with UI size; its bottom-left stays at (LEFT, BOTTOM) on screen however its host is scaled.

const LEFT := 4.0      # the version number's inset from the right edge, mirrored
const BOTTOM := 176.0  # level with the bottom of the title's version number

var view: HintView

## The strip's on-screen transform at UI scale s: scale s, bottom-left corner at (LEFT, BOTTOM).
static func screen_transform(s: float) -> Transform2D:
	return Transform2D(0.0, Vector2(s, s), 0.0, Vector2(LEFT, BOTTOM - KeyHint.HEIGHT * s))

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	view = HintView.new()
	view.word_colour = KeyHint.TEXT
	view.hint = DeviceHints.Hint.SELECT
	add_child(view)
	InputDevice.changed.connect(_layout)
	Display.changed.connect(_layout_later)
	get_tree().root.size_changed.connect(_layout_later)
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
	var s := UiScale.current(Display.prefs, get_tree().root) if is_inside_tree() else 1.0
	var want := screen_transform(s)
	var host := get_parent() as CanvasItem
	var local := want if host == null or not is_inside_tree() \
			else host.get_global_transform_with_canvas().affine_inverse() * want
	position = local.origin
	scale = local.get_scale()
	view.position = Vector2.ZERO
	view.size = size
	queue_redraw()
	view.queue_redraw()

## Deferred: the host's scale is set by other handlers of the same signals, so read it at frame end.
func _layout_later() -> void:
	_layout.call_deferred()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), KeyHint.BAND)
