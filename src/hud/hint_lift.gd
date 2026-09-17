class_name HintLift
extends RefCounted
## Moves a bottom hint straight up, on screen, so a grown hint never covers the item bar's plank.

const GAP := 2.0   # units between the lifted hint's bottom and the plank's top, on screen

## The on-screen lift (0 or negative, in 320x180 units) for a hint whose unlifted on-screen rect is `hint`.
## 0 when `bar` has no area (no bar drawn), when the hint has not grown past `normal_height`, or when the
## two rects do not overlap (borders excluded). Otherwise the amount that puts its bottom GAP above the bar.
static func lift(hint: Rect2, normal_height: float, bar: Rect2) -> float:
	if not bar.has_area() or hint.size.y <= normal_height + 0.01 or not hint.intersects(bar):
		return 0.0
	return (bar.position.y - GAP) - hint.end.y

## The item bar's plank (never its name plank) on screen, when a bar is visible in the tree; Rect2() otherwise.
static func bar_rect(tree: SceneTree) -> Rect2:
	var bar := tree.get_first_node_in_group(ItemBar.GROUP) as Control
	if bar == null or not bar.is_visible_in_tree():
		return Rect2()
	return bar.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, ItemBar.PLANK_SIZE)

## A Control's own rect on screen, including every CanvasLayer and Control scale above it.
static func screen_rect(c: Control) -> Rect2:
	return c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)

## Puts c at local y `top`, then moves it up by lift(), in its parent's units. x is never touched.
## Returns the on-screen lift. Out of the tree it only sets position.y = top.
static func place(c: Control, top: float, normal_height: float) -> float:
	c.position.y = top
	if not c.is_inside_tree():
		return 0.0
	var t := c.get_global_transform_with_canvas()
	var dy := lift(t * Rect2(Vector2.ZERO, c.size), normal_height, bar_rect(c.get_tree()))
	c.position.y = top + dy / (t.get_scale().y / c.scale.y)
	return dy
