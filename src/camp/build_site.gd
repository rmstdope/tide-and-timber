class_name BuildSite
extends RefCounted
## Where a lean-to or fire would go, and whether it may. Cells are on the 16 px grid.

const FEET_SIZE := Vector2(10, 6)       # the Player's Feet box (player.tscn: 10x6 at (0,-3))

static func cell_of(at: Vector2) -> Vector2i:
	return Vector2i((at / BeachLayout.TILE).floor())

## Row by row, top-left first. The lean-to is 3x2 on whichever side he faces; the fire one cell.
static func cells_for(thing: BuildMenu.Thing, feet_cell: Vector2i, facing: Walk.Facing) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if thing == BuildMenu.Thing.FIRE:
		cells.append(feet_cell + Vector2i(Walk.facing_vector(facing)))
		return cells
	var left: int
	var top: int
	match facing:
		Walk.Facing.DOWN:
			left = feet_cell.x - 1
			top = feet_cell.y + 1
		Walk.Facing.UP:
			left = feet_cell.x - 1
			top = feet_cell.y - 2
		Walk.Facing.LEFT:
			left = feet_cell.x - 3
			top = feet_cell.y - 1
		_:
			left = feet_cell.x + 1
			top = feet_cell.y - 1
	for y in 2:
		for x in 3:
			cells.append(Vector2i(left + x, top + y))
	return cells

## The bottom-middle cell; for one cell, that cell.
static func anchor_of(cells: Array[Vector2i]) -> Vector2i:
	if cells.size() == 1:
		return cells[0]
	var lo := cells[0]
	var hi := cells[0]
	for c in cells:
		lo = lo.min(c)
		hi = hi.max(c)
	return Vector2i(lo.x + 1, hi.y)

static func origin_for(thing: BuildMenu.Thing, cells: Array[Vector2i]) -> Vector2:
	if thing == BuildMenu.Thing.FIRE:
		return BeachLayout.cell_base(cells[0])
	return BeachLayout.cell_base(anchor_of(cells))

static func fire_spot(lean_to_anchor: Vector2i) -> Vector2i:
	return lean_to_anchor + Vector2i(0, 1)

static func feet_rect(feet: Vector2) -> Rect2:
	return Rect2(feet + Vector2(-5, -6), FEET_SIZE)

static func footprint_rect(cells: Array[Vector2i]) -> Rect2:
	var lo := cells[0]
	var hi := cells[0]
	for c in cells:
		lo = lo.min(c)
		hi = hi.max(c)
	return Rect2(Vector2(lo * BeachLayout.TILE), Vector2((hi - lo + Vector2i.ONE) * BeachLayout.TILE))

## Vector2i -> true for every palm and rock cell, and every cell a boulder or the spring's base covers.
static func prop_cells() -> Dictionary:
	var cells := {}
	for c in BeachLayout.palms():
		cells[c] = true
	for c in BeachLayout.rocks():
		cells[c] = true
	for spring in BeachLayout.springs():    # its 28x10 base spans the cells either side
		for x in range(spring.x - 1, spring.x + 2):
			cells[Vector2i(x, spring.y)] = true
	for b in BeachLayout.boulders():
		for y in range(b.y - 1, b.y + 1):
			for x in range(b.x - 1, b.x + 2):
				cells[Vector2i(x, y)] = true
	return cells

static func is_ground_ok(cell: Vector2i) -> bool:
	var kind := BeachLayout.kind_at(cell)
	return kind == BeachLayout.Kind.SAND or kind == BeachLayout.Kind.WET_SAND

static func can_place(thing: BuildMenu.Thing, cells: Array[Vector2i], taken: Dictionary,
		feet: Rect2, has_lean_to: bool, lean_to_anchor: Vector2i) -> bool:
	if thing == BuildMenu.Thing.FIRE and (not has_lean_to or cells[0] != fire_spot(lean_to_anchor)):
		return false
	if footprint_rect(cells).intersects(feet):
		return false
	for c in cells:
		if not is_ground_ok(c) or taken.has(c):
			return false
	return true
