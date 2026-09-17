class_name PixelRuns
extends RefCounted
## Shapes turned into whole-art-pixel rects, so they stay chunky when the window draws finer than
## the 320x180 base. Each result is one Rect2(x, y, length, 1) per horizontal run of pixels,
## rows top to bottom, runs left to right.

## The art pixels whose centres (x + 0.5, y + 0.5) lie inside the polygon
## (Geometry2D.is_point_in_polygon), scanning rows floori(min y)..ceili(max y) - 1 and columns
## floori(min x)..ceili(max x) - 1 of the points' bounding box.
static func polygon(points: PackedVector2Array) -> Array[Rect2]:
	if points.is_empty():
		return []
	var lo := points[0]
	var hi := points[0]
	for p in points:
		lo = lo.min(p)
		hi = hi.max(p)
	return _runs(Rect2i(floori(lo.x), floori(lo.y), ceili(hi.x) - floori(lo.x), ceili(hi.y) - floori(lo.y)),
		func(c: Vector2) -> bool: return Geometry2D.is_point_in_polygon(c, points))

## `rect` turned by `degrees` about `pivot`, as draw_set_transform(pivot, deg_to_rad(degrees))
## with the rect drawn at rect.position - pivot does: polygon() of the four corners
## pivot + (corner - pivot).rotated(deg_to_rad(degrees)).
static func turned_rect(rect: Rect2, pivot: Vector2, degrees: float) -> Array[Rect2]:
	var turn := deg_to_rad(degrees)
	var corners := PackedVector2Array()
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		corners.append(pivot + (corner - pivot).rotated(turn))
	return polygon(corners)

## A straight stroke `width` wide from a to b with square-cut ends at a and b:
## polygon() of a + n, b + n, b - n, a - n, where n = (b - a).normalized().orthogonal() * width / 2.
static func line(a: Vector2, b: Vector2, width: float) -> Array[Rect2]:
	var n := (b - a).normalized().orthogonal() * width / 2.0
	return polygon(PackedVector2Array([a + n, b + n, b - n, a - n]))

## A ring `width` wide about `centre`, from angle `from_angle` to `to_angle` in radians, measured as
## draw_arc measures (0 along +x, growing clockwise on screen). A pixel is in when the distance from
## centre to its centre is within [radius - width / 2, radius + width / 2] and
## fposmod(atan2(dy, dx) - from_angle, TAU) <= to_angle - from_angle (every angle when that span >= TAU).
## Scans the square floori(centre - (radius + width / 2)) .. ceili(centre + (radius + width / 2)) - 1.
static func arc(centre: Vector2, radius: float, width: float, from_angle: float, to_angle: float) -> Array[Rect2]:
	var outer := radius + width / 2.0
	var inner := radius - width / 2.0
	var span := to_angle - from_angle
	var lo := Vector2i(floori(centre.x - outer), floori(centre.y - outer))
	var hi := Vector2i(ceili(centre.x + outer), ceili(centre.y + outer))
	return _runs(Rect2i(lo, hi - lo), func(c: Vector2) -> bool:
		var d := c - centre
		var dist := d.length()
		if dist < inner or dist > outer:
			return false
		return span >= TAU or fposmod(atan2(d.y, d.x) - from_angle, TAU) <= span)

## Scans `area` row by row, joining neighbouring pixels whose centre passes `inside` into runs.
static func _runs(area: Rect2i, inside: Callable) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for y in range(area.position.y, area.end.y):
		var start := 0
		var length := 0
		for x in range(area.position.x, area.end.x):
			if inside.call(Vector2(x + 0.5, y + 0.5)):
				if length == 0:
					start = x
				length += 1
			elif length > 0:
				out.append(Rect2(start, y, length, 1))
				length = 0
		if length > 0:
			out.append(Rect2(start, y, length, 1))
	return out
