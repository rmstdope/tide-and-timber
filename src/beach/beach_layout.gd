class_name BeachLayout
extends RefCounted
## The beach map as rules and constants, free of nodes.

enum Kind { JUNGLE, SAND, WET_SAND, FOAM, SHALLOWS, DEEP, CLIFF }   # also the x of each tile in tiles.png
const TILE := 16
const MAP_SIZE := Vector2i(184, 26)
const SPAWN_CELL := Vector2i(92, 11)
const PALMS: Array[Vector2i] = [Vector2i(20, 9), Vector2i(33, 9), Vector2i(47, 9), Vector2i(58, 9), Vector2i(71, 9), Vector2i(84, 9), Vector2i(101, 9), Vector2i(113, 9), Vector2i(126, 9), Vector2i(139, 9), Vector2i(150, 9), Vector2i(163, 9)]
const ROCKS: Array[Vector2i] = [Vector2i(26, 12), Vector2i(40, 13), Vector2i(55, 11), Vector2i(66, 14), Vector2i(78, 12), Vector2i(99, 13), Vector2i(108, 11), Vector2i(121, 14), Vector2i(134, 12), Vector2i(147, 13), Vector2i(158, 11)]
const BOULDERS: Array[Vector2i] = [Vector2i(17, 10), Vector2i(17, 15), Vector2i(62, 10), Vector2i(118, 10), Vector2i(166, 10), Vector2i(166, 15)]
const DRIFTWOOD: Array[Vector2i] = [Vector2i(30, 13), Vector2i(69, 12), Vector2i(88, 13), Vector2i(130, 13), Vector2i(155, 12),
	Vector2i(19, 12), Vector2i(23, 12), Vector2i(37, 13), Vector2i(44, 13), Vector2i(50, 12), Vector2i(53, 13), Vector2i(61, 13),
	Vector2i(64, 13), Vector2i(74, 12), Vector2i(80, 13), Vector2i(107, 13), Vector2i(111, 13), Vector2i(116, 12), Vector2i(124, 13),
	Vector2i(137, 13), Vector2i(142, 12), Vector2i(152, 13), Vector2i(161, 12), Vector2i(164, 12)]
const SHELLFISH: Array[Vector2i] = [Vector2i(24, 14), Vector2i(51, 14), Vector2i(75, 14), Vector2i(96, 14), Vector2i(116, 14), Vector2i(143, 14), Vector2i(160, 14)]
const SPRINGS: Array[Vector2i] = [Vector2i(96, 9)]

static func kind_at(cell: Vector2i) -> Kind:
	if cell.y <= 8:
		return Kind.JUNGLE
	if cell.y >= 18:
		return Kind.DEEP
	if cell.x <= 11 or cell.x >= 172:
		return Kind.JUNGLE if cell.y <= 14 else Kind.DEEP
	if cell.x <= 15 or cell.x >= 168:
		return Kind.CLIFF
	if cell.y <= 13:
		return Kind.SAND
	if cell.y == 14:
		return Kind.WET_SAND
	if cell.y == 15:
		return Kind.FOAM
	return Kind.SHALLOWS

static func is_solid(kind: Kind) -> bool:
	return kind == Kind.JUNGLE or kind == Kind.DEEP or kind == Kind.CLIFF

static func is_wadeable(kind: Kind) -> bool:
	return kind == Kind.SHALLOWS

static func cell_at(at: Vector2) -> Vector2i:
	return Vector2i((at / TILE).floor())

static func cell_centre(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE) + Vector2(8, 8)

static func cell_base(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + 8, (cell.y + 1) * TILE)
