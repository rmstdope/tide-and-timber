class_name MenuStrip
extends Control
## A menu's Select / Back strip in the bottom-left corner, in the pictures of the device used last.
## Grows with UI size; its bottom-left stays at (LEFT, BOTTOM) on screen however its host is scaled.
## At larger sizes it lifts above the item bar when it would cover it.

const LEFT := 4.0      # the version number's inset from the right edge, mirrored
const BOTTOM := 176.0  # level with the bottom of the title's version number

var view: HintView

## The strip's on-screen transform at UI scale s: scale s, bottom-left corner at (LEFT, BOTTOM),
## for a band `height` tall in its own units.
static func screen_transform(s: float, height: float = KeyHint.HEIGHT) -> Transform2D:
	return Transform2D(0.0, Vector2(s, s), 0.0, Vector2(LEFT, BOTTOM - height * s))

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
	_layout_later()   # a bar made later in the same scene joins its group in its own _ready

## Which line to show: DeviceHints.Hint.SELECT or SELECT_BACK. Lays out at once.
func show_hint(h: DeviceHints.Hint) -> void:
	view.hint = h
	_layout()

## The line in the agreed notation, e.g. "[Enter] Select".
func text() -> String:
	return view.text()

func _layout() -> void:
	if not is_inside_tree():
		return
	var w := view.line_width() + 8
	size = Vector2(w, KeyHint.HEIGHT + view.grown_by())
	var s := UiScale.current(Display.prefs, get_tree().root) if is_inside_tree() else 1.0
	var want := screen_transform(s, size.y)
	var host := get_parent() as CanvasItem
	var local := want if host == null or not is_inside_tree() \
			else host.get_global_transform_with_canvas().affine_inverse() * want
	position = local.origin
	scale = local.get_scale()
	HintLift.place(self, position.y, KeyHint.HEIGHT)
	view.position = Vector2.ZERO
	view.size = size
	queue_redraw()
	view.queue_redraw()

## The strip's top edge on screen, after any lift: the lower bound of a scrolling list's visible band.
func screen_top() -> float:
	return HintLift.screen_rect(self).position.y

## Lays out again at frame end, reading the host's scale then; a host that scales itself calls it too.
func relayout() -> void:
	_layout.call_deferred()

func _layout_later() -> void:
	relayout()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), KeyHint.BAND)
