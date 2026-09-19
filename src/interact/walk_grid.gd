class_name WalkGrid
extends RefCounted
## Where the man's feet can stand, on an 8 px grid over the map, and routes across it. Free of nodes.

const CELL := 8
const FEET := Rect2(-5, -6, 10, 6)   # his feet box relative to his origin (player.tscn: 10x6 at (0,-3))
const NEAR := 8.0                    # a route ending this close to the click counts as reaching it
const NONE := Vector2i(-1, -1)

class Route:
	var waypoints := PackedVector2Array()   # in walking order; the last is where he stops
	var short := false                      # true: he cannot get to where he was sent

var astar := AStarGrid2D.new()
var _solid_tile: Callable                   # func(tile: Vector2i) -> bool
var _base := PackedByteArray()              # 1 where a solid tile blocks the point; row-major over the region
var _obstacles: Array[Rect2] = []

func _init(map_tiles: Vector2i, solid_tile: Callable) -> void:
	_solid_tile = solid_tile
	astar.region = Rect2i(Vector2i.ZERO, map_tiles * BeachLayout.TILE / CELL)
	astar.cell_size = Vector2(CELL, CELL)
	astar.offset = Vector2(CELL / 2.0, CELL / 2.0)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.update()
	var size := astar.region.size
	_base.resize(size.x * size.y)
	for y in size.y:
		for x in size.x:
			_base[y * size.x + x] = 1 if _tile_blocks(centre(Vector2i(x, y))) else 0
	refresh([])

## Blocks the points his feet cannot stand on, given solid tiles and these obstacle boxes.
func refresh(obstacles: Array[Rect2]) -> void:
	_obstacles = obstacles.duplicate()
	var size := astar.region.size
	for y in size.y:
		for x in size.x:
			astar.set_point_solid(Vector2i(x, y), _base[y * size.x + x] == 1)
	for rect in _obstacles:
		var lo := Vector2i(((rect.position - Vector2(5, 0)) / CELL).floor()) - Vector2i.ONE
		var hi := Vector2i(((rect.end + Vector2(5, 6)) / CELL).floor()) + Vector2i.ONE
		lo = lo.clamp(Vector2i.ZERO, size - Vector2i.ONE)
		hi = hi.clamp(Vector2i.ZERO, size - Vector2i.ONE)
		for y in range(lo.y, hi.y + 1):
			for x in range(lo.x, hi.x + 1):
				var p := Vector2i(x, y)
				# Touching blocks a point: feet flush on a base can't slide round its corner (a nudged crab's does).
				if _box_meets(centre(p), rect, true):
					astar.set_point_solid(p, true)

func centre(p: Vector2i) -> Vector2:
	return Vector2(p * CELL) + Vector2(CELL / 2.0, CELL / 2.0)

func point_at(at: Vector2) -> Vector2i:
	return Vector2i((at / CELL).floor()).clamp(Vector2i.ZERO, astar.region.size - Vector2i.ONE)

func is_free(p: Vector2i) -> bool:
	return astar.is_in_boundsv(p) and not astar.is_point_solid(p)

## Whether his feet fit at exactly this position.
func is_clear(at: Vector2) -> bool:
	if _tile_blocks(at):
		return false
	for rect in _obstacles:
		if _box_meets(at, rect):
			return false
	return true

## The free point nearest `at` within two points of it, or NONE.
func start_point(at: Vector2) -> Vector2i:
	var c := point_at(at)
	var best := NONE
	var best_d := INF
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var p := c + Vector2i(dx, dy)
			if not is_free(p):
				continue
			var d := centre(p).distance_to(at)
			if d < best_d:
				best_d = d
				best = p
	return best

## A route from `from` to `to`, or as near to it as he can get.
func route_to_point(from: Vector2, to: Vector2) -> Route:
	var route := Route.new()
	var s := start_point(from)
	if s == NONE:
		route.short = from.distance_to(to) > NEAR
		return route
	var g := point_at(to)
	var raw := astar.get_point_path(s, g, true)
	if raw.is_empty():
		raw = PackedVector2Array([centre(s)])
	var full := is_free(g) and raw[-1] == centre(g)
	route.waypoints = _trim(raw)
	if full and is_clear(to):
		route.waypoints[-1] = to
	route.short = not full and route.waypoints[-1].distance_to(to) > NEAR
	return route

## The shortest route to a free point within `reach` of `spot`; short when there is none.
func route_into_reach(from: Vector2, spot: Vector2, reach: float) -> Route:
	var s := start_point(from)
	if s == NONE:
		var none := route_to_point(from, spot)
		none.short = true
		return none
	var lo := point_at(spot - Vector2(reach, reach))
	var hi := point_at(spot + Vector2(reach, reach))
	var best := PackedVector2Array()
	var best_len := INF
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			var p := Vector2i(x, y)
			if not is_free(p) or centre(p).distance_to(spot) > reach:
				continue
			var path := astar.get_point_path(s, p, false)
			if path.is_empty():
				continue
			var length := from.distance_to(path[0])
			for i in range(1, path.size()):
				length += path[i - 1].distance_to(path[i])
			if length < best_len:
				best_len = length
				best = path
	if best.is_empty():
		var fallback := route_to_point(from, spot)
		fallback.short = true
		return fallback
	var route := Route.new()
	route.waypoints = _trim(best)
	return route

func _trim(raw: PackedVector2Array) -> PackedVector2Array:
	return raw.slice(1) if raw.size() >= 2 else raw

func _tile_blocks(at: Vector2) -> bool:
	var box := Rect2(at + FEET.position, FEET.size)
	var lo := Vector2i((box.position / BeachLayout.TILE).floor())
	var hi := Vector2i(((box.end - Vector2(0.001, 0.001)) / BeachLayout.TILE).floor())
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			if _solid_tile.call(Vector2i(x, y)):
				return true
	return false

func _box_meets(at: Vector2, rect: Rect2, touching := false) -> bool:
	return Rect2(at + FEET.position, FEET.size).intersects(rect, touching)
