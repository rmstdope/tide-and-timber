class_name BeachLayout
extends RefCounted
## The beach map as the rest of the game asks about it, free of nodes: read once per run from the
## ground and props authored in beach.tscn (BeachMap), plus the rules about kinds and cells.

enum Kind { JUNGLE, SAND, WET_SAND, FOAM, SHALLOWS, DEEP, CLIFF }   # also the x of each tile in tiles.png
const TILE := 16
const EDGE_TILE := 7                # tiles.png x of the first of the three ragged-edge tiles, after the Kind tiles
const TILE_COUNT := 10              # tiles in tiles.png: the seven Kind tiles, then the three edge tiles
const EDGE_ROW := 8                 # the last jungle row
const EDGE_FIRST_COLUMN := 12       # the ragged edge runs over the beach and its cliffs; the jungle carries on
const EDGE_LAST_COLUMN := 171       # down the headlands beyond, so those keep the plain jungle tile
const SCENE := "res://src/beach/beach.tscn"
const PALM := "res://src/beach/props/palm.tscn"
const ROCK := "res://src/beach/props/rock.tscn"
const BOULDER := "res://src/beach/props/boulder.tscn"
const DRIFTWOOD := "res://src/beach/props/driftwood.tscn"
const SHELLFISH := "res://src/beach/props/shellfish.tscn"
const SPRING := "res://src/beach/props/spring.tscn"
const BUSH := "res://src/beach/props/bush.tscn"
const TUFT := "res://src/beach/props/tuft.tscn"
## Every prop scene a beach layout places, flat ones (under %Decor) first.
const PROP_SCENES: Array[String] = [BUSH, TUFT, PALM, ROCK, BOULDER, SPRING, DRIFTWOOD, SHELLFISH]
const SPAWN_CELL := Vector2i(92, 11)

static var _cached: BeachMap

static func map_size() -> Vector2i:
	return _map().size()

static func palms() -> Array[Vector2i]:
	return _map().cells_of(PALM)

static func rocks() -> Array[Vector2i]:
	return _map().cells_of(ROCK)

static func boulders() -> Array[Vector2i]:
	return _map().cells_of(BOULDER)

static func driftwood() -> Array[Vector2i]:
	return _map().cells_of(DRIFTWOOD)

static func shellfish() -> Array[Vector2i]:
	return _map().cells_of(SHELLFISH)

static func springs() -> Array[Vector2i]:
	return _map().cells_of(SPRING)

static func bushes() -> Array[Vector2i]:
	return _map().cells_of(BUSH)

static func tufts() -> Array[Vector2i]:
	return _map().cells_of(TUFT)

## The cell whose cell_base is `base`: the inverse of cell_base, for any base inside the cell.
static func cell_of_base(base: Vector2) -> Vector2i:
	return Vector2i(floori(base.x / TILE), ceili(base.y / TILE) - 1)

## The kind painted at `cell` in beach.tscn; DEEP off the map or where nothing is painted.
static func kind_at(cell: Vector2i) -> Kind:
	return _map().kind_at(cell) as Kind

## The tiles.png atlas coords beach.tscn paints at `cell`: on EDGE_ROW between the edge columns, edge
## tile EDGE_TILE + cell.x % 3 (which reads as JUNGLE); everywhere else Vector2i(kind_at(cell), 0).
static func tile_at(cell: Vector2i) -> Vector2i:
	if cell.y == EDGE_ROW and cell.x >= EDGE_FIRST_COLUMN and cell.x <= EDGE_LAST_COLUMN:
		return Vector2i(EDGE_TILE + cell.x % 3, 0)
	return Vector2i(kind_at(cell), 0)

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

## The whole painted map in px, its origin at (0, 0): the rectangle the view may never leave.
static func world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(map_size() * TILE))

## The authored layout, read from beach.tscn on first use and kept for the run: an editor change
## reaches the game at its next launch. load, not preload: beach.tscn names beach.gd, which names us.
static func _map() -> BeachMap:
	if _cached == null:
		var beach := (load(SCENE) as PackedScene).instantiate()
		_cached = BeachMap.from_scene(beach)
		beach.free()
	return _cached
