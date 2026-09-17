class_name BoxLayout
extends RefCounted
## Where a box's panel, lines and two buttons go at a UI scale. Side by side is the box's Normal layout
## unchanged. When side by side is wider than the screen, the box narrows to fit, its lines wrap and
## the buttons go one above the other, the left on top. Holds no nodes; place() writes a layout to them.

const SCREEN_WIDTH := 320.0
const SCREEN_CENTRE := Vector2(160, 90)
const SCREEN_MARGIN := 4.0          # kept clear on each side of a stacked box, in 320x180 units

var stacked := false
var panel := Rect2()                # the panel, in its parent's 320x180 units
var lines: Array[Rect2] = []        # each line of words, inside the panel, top to bottom
var left := Rect2()                 # the left (stacked: top) button, inside the panel
var right := Rect2()                # the right (stacked: bottom) button, inside the panel

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
