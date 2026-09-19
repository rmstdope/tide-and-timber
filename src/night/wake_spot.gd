class_name WakeSpot
extends RefCounted
## Where he wakes after a collapse: beside the lean-to, else where he first woke.

## The first open cell of: front-left, front-right, left side, right side of the lean-to; else first_woke.
static func beside_lean_to(anchor: Vector2i, first_woke: Vector2i) -> Vector2i:
	for offset: Vector2i in [Vector2i(-1, 1), Vector2i(1, 1), Vector2i(-2, 0), Vector2i(2, 0)]:
		if is_open(anchor + offset):
			return anchor + offset
	return first_woke

static func is_open(cell: Vector2i) -> bool:
	return BuildSite.is_ground_ok(cell) and not BuildSite.prop_cells().has(cell) \
		and not BeachLayout.springs().has(cell)
