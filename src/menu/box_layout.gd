class_name BoxLayout
extends RefCounted
## Where a box's panel, lines and two buttons go at a UI scale. Side by side is the box's Normal layout
## unchanged. When side by side is wider than the screen, the box narrows to fit, its lines wrap and
## the buttons go one above the other, the left on top. Holds no nodes; place() writes a layout to them.
## framed() fits a laid-out box to the room above its strip; pushed() says what a push does to its
## highlight and scroll.

const SCREEN_WIDTH := 320.0
const SCREEN_CENTRE := Vector2(160, 90)
const SCREEN_MARGIN := 4.0          # kept clear on each side of a stacked box, in 320x180 units
const LINE_STEP := 11.0             # one line of size-8 words, with the labels' line spacing: one push or wheel notch

enum Side { LEFT, RIGHT }                                  # which button is highlighted; LEFT is the top one when stacked
enum Push { UP, DOWN, LEFT, RIGHT, WHEEL_UP, WHEEL_DOWN }

var stacked := false
var panel := Rect2()                # the panel, in its parent's 320x180 units
var lines: Array[Rect2] = []        # each line of words, inside the panel, top to bottom
var left := Rect2()                 # the left (stacked: top) button, inside the panel
var right := Rect2()                # the right (stacked: bottom) button, inside the panel
var right_shown := true             # false after one_button()
var scrolls := false                # set by framed(): the unframed panel is taller than the band
var offset := 0                     # set by framed(): whole units the content is moved up; always 0 unless scrolls
var clip := Rect2()                 # set by framed(): the Clip node inside the panel
var content := Rect2()              # set by framed(): the Content node inside the Clip; its size is the unframed panel's

## WHEEL_UP or WHEEL_DOWN for a wheel press, else -1. Kept here with the enum: a wheel notch is
## one push on a framed box, and every box that scrolls reads it the same way.
static func wheel_push(event: InputEvent) -> int:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return -1
	if click.button_index == MOUSE_BUTTON_WHEEL_UP:
		return Push.WHEEL_UP
	if click.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		return Push.WHEEL_DOWN
	return -1

## The Normal layout, read from the nodes' rects as the scene has them. Call it once, before any place().
static func of(panel_node: Control, line_nodes: Array[Control], left_node: Control, right_node: Control) -> BoxLayout:
	var n := BoxLayout.new()
	n.panel = _rect(panel_node)
	for line in line_nodes:
		n.lines.append(_rect(line))
	n.left = _rect(left_node)
	n.right = _rect(right_node)
	return n

## Width of a stacked box at scale s: the widest even width that fits SCREEN_WIDTH / s less both margins,
## never wider than normal_width.
static func stacked_width(normal_width: float, s: float) -> float:
	return minf(normal_width, 2.0 * floorf((SCREEN_WIDTH / s - 2.0 * SCREEN_MARGIN) / 2.0))

## Height needed by labels[i] at a given width: sets its width, returns get_minimum_size().y.
## For at()'s needed_height.
static func label_heights(labels: Array[Label]) -> Callable:
	return func(index: int, width: float) -> float:
		var label := labels[index]
		label.size = Vector2(width, label.size.y)
		return label.get_minimum_size().y

## On a Normal layout: whether the buttons, at their actual sizes, are wider than the screen side by side.
func stacks_at(s: float, left_size: Vector2, right_size: Vector2) -> bool:
	var side := left.position.x
	var gap := right.position.x - left.end.x
	return (side + left_size.x + gap + right_size.x + side) * s > SCREEN_WIDTH

## On a Normal layout: the layout at scale s. Not stacking: a copy of this layout (stacked false).
## needed_height is (index: int, width: float) -> float.
func at(s: float, left_size: Vector2, right_size: Vector2, needed_height: Callable) -> BoxLayout:
	var l := BoxLayout.new()
	if not stacks_at(s, left_size, right_size):
		l.panel = panel
		l.lines = lines.duplicate()
		l.left = left
		l.right = right
		return l
	l.stacked = true
	var w := stacked_width(panel.size.x, s)
	for i in lines.size():
		var line := Rect2()
		line.position.x = lines[i].position.x
		line.size.x = w - lines[i].position.x - (panel.size.x - lines[i].end.x)
		if i == 0:
			line.position.y = lines[0].position.y
		else:
			line.position.y = l.lines[i - 1].end.y + (lines[i].position.y - lines[i - 1].end.y)
		line.size.y = maxf(lines[i].size.y, needed_height.call(i, line.size.x))
		l.lines.append(line)
	l.left = Rect2(Vector2(roundf((w - left_size.x) / 2.0), l.lines[-1].end.y + (left.position.y - lines[-1].end.y)), left_size)
	l.right = Rect2(Vector2(roundf((w - right_size.x) / 2.0), l.left.end.y + (right.position.x - left.end.x)), right_size)
	var h := l.right.end.y + (panel.size.y - left.end.y)
	l.panel = Rect2(Vector2(roundf(SCREEN_CENTRE.x - w / 2.0), roundf(SCREEN_CENTRE.y - h / 2.0)), Vector2(w, h))
	return l

## This layout with only the left button shown: the left button centred across the panel, and, when
## stacked, the panel only as tall as one button needs, re-centred on SCREEN_CENTRE. `right` is left
## as it was; the caller hides that button. Returns a new BoxLayout; this one is unchanged.
func one_button() -> BoxLayout:
	var l := BoxLayout.new()
	l.stacked = stacked
	l.panel = panel
	l.lines = lines.duplicate()
	l.left = left
	l.right = right
	l.right_shown = false
	l.left.position.x = roundf((panel.size.x - left.size.x) / 2.0)
	if stacked:
		l.panel.size.y -= right.end.y - left.end.y
		l.panel.position.y = roundf(SCREEN_CENTRE.y - l.panel.size.y / 2.0)
	return l

## Where the scrolled content starts inside the unframed panel: the first line's top.
func content_top() -> float:
	return lines[0].position.y

## From the first line's top to the bottom of the lowest button shown.
func content_height() -> float:
	var bottom := maxf(left.end.y, right.end.y) if right_shown else left.end.y
	return bottom - content_top()

## This laid-out box (from at(), or one_button()) framed to the band [band_top, band_bottom], in the panel's
## parent's units, with offset_now clamped. Returns a new BoxLayout: lines, left and right unchanged
## (they stay in Content's units, which are the unframed panel's), stacked and right_shown copied.
func framed(band_top: float, band_bottom: float, offset_now: int) -> BoxLayout:
	var rest := panel
	var band_h := band_bottom - band_top
	var f := BoxLayout.new()
	f.stacked = stacked
	f.right_shown = right_shown
	f.lines = lines.duplicate()
	f.left = left
	f.right = right
	if rest.size.y <= band_h:
		f.scrolls = false
		f.offset = 0
		f.panel = Rect2(Vector2(rest.position.x, clampf(rest.position.y, band_top, band_bottom - rest.size.y)), rest.size)
		f.clip = Rect2(Vector2.ZERO, rest.size)
		f.content = Rect2(Vector2.ZERO, rest.size)
		return f
	f.scrolls = true
	var view_h := maxf(1.0, band_h - 2.0 * ScrollWindow.MARK_ROW)
	f.panel = Rect2(Vector2(rest.position.x, band_top), Vector2(rest.size.x, band_h))
	f.clip = Rect2(Vector2(0, ScrollWindow.MARK_ROW), Vector2(rest.size.x, view_h))
	f.offset = clampi(offset_now, 0, maxi(0, ceili(content_height() - view_h)))
	f.content = Rect2(Vector2(0, -(content_top() + f.offset)), rest.size)
	return f

## True while the ▲ mark is drawn. Call on a framed layout.
func shows_mark_above() -> bool:
	return scrolls and ScrollWindow.hidden_above(offset)

## True while the ▼ mark is drawn. Call on a framed layout.
func shows_mark_below() -> bool:
	return scrolls and ScrollWindow.hidden_below(offset, content_height(), clip.size.y)

## What one push does on this framed layout while `highlighted` is highlighted.
## Returns Vector2i(the Side highlighted after, the offset after).
func pushed(push: Push, highlighted: BoxLayout.Side) -> Vector2i:
	var picked := Side.RIGHT if right_shown else Side.LEFT
	if not scrolls:
		match push:
			Push.UP:
				return Vector2i(Side.LEFT if _has_above(highlighted) else highlighted, 0)
			Push.DOWN:
				return Vector2i(Side.RIGHT if _has_below(highlighted) else highlighted, 0)
			Push.LEFT:
				return Vector2i(Side.LEFT, 0)
			Push.RIGHT:
				return Vector2i(picked, 0)
		return Vector2i(highlighted, 0)
	match push:
		Push.UP:
			if _has_above(highlighted):
				if _in_view(highlighted):
					return Vector2i(Side.LEFT, _show(Side.LEFT))
				return Vector2i(highlighted, _toward(highlighted))
			return Vector2i(highlighted, maxi(offset - int(LINE_STEP), 0))
		Push.DOWN:
			if not _in_view(highlighted):
				return Vector2i(highlighted, _toward(highlighted))
			if _has_below(highlighted):
				return Vector2i(Side.RIGHT, _show(Side.RIGHT))
			return Vector2i(highlighted, offset)
		Push.LEFT:
			return Vector2i(Side.LEFT, _show(Side.LEFT))
		Push.RIGHT:
			return Vector2i(picked, _show(picked))
		Push.WHEEL_UP:
			return Vector2i(highlighted, maxi(offset - int(LINE_STEP), 0))
	return Vector2i(highlighted, mini(offset + int(LINE_STEP), _max_offset()))

## Writes a framed layout's panel, clip and content to the nodes. Marks covers the whole panel and is redrawn.
func place_frame(panel_node: Control, clip_node: Control, content_node: Control, marks_node: Control) -> void:
	_put(panel_node, panel)
	_put(clip_node, clip)
	_put(content_node, content)
	_put(marks_node, Rect2(Vector2.ZERO, panel.size))
	marks_node.queue_redraw()

## That button's own rect as (top, bottom) in content units.
func _span(side: BoxLayout.Side) -> Vector2:
	var r := left if side == Side.LEFT else right
	return Vector2(r.position.y - content_top(), r.end.y - content_top())

func _in_view(side: BoxLayout.Side) -> bool:
	var span := _span(side)
	return span.x >= offset and span.y <= offset + clip.size.y

func _max_offset() -> int:
	return maxi(0, ceili(content_height() - clip.size.y))

func _has_below(side: BoxLayout.Side) -> bool:
	return stacked and right_shown and side == Side.LEFT

func _has_above(side: BoxLayout.Side) -> bool:
	return stacked and right_shown and side == Side.RIGHT

## One line towards a button not wholly in view, never past it.
func _toward(side: BoxLayout.Side) -> int:
	var span := _span(side)
	var o := 0
	# Hidden above wins: a button taller than the view is hidden on both sides at once, and scrolling
	# down would walk away from its top, which is the end the reader needs.
	if span.x < offset:
		o = maxi(offset - int(LINE_STEP), floori(span.x))
	else:
		o = mini(offset + int(LINE_STEP), ceili(span.y - clip.size.y))
	return clampi(o, 0, _max_offset())

## The offset that shows side wholly, as if it were highlighted.
func _show(side: BoxLayout.Side) -> int:
	var span := _span(side)
	return ScrollWindow.follow(content_height(), clip.size.y, span.x, span.y, offset)

## Writes panel, lines, left and right to the nodes, as position and size.
func place(panel_node: Control, line_nodes: Array[Control], left_node: Control, right_node: Control) -> void:
	_put(panel_node, panel)
	for i in line_nodes.size():
		_put(line_nodes[i], lines[i])
	_put(left_node, left)
	_put(right_node, right)

static func _rect(node: Control) -> Rect2:
	return Rect2(node.position, node.size)

static func _put(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	# Width first, then refresh the cached minimum: a wrapped label's minimum height follows its width,
	# and a Control is never set smaller than the minimum it last cached.
	node.size = Vector2(rect.size.x, node.size.y)
	node.update_minimum_size()
	node.size = rect.size
