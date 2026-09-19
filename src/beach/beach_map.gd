class_name BeachMap
extends RefCounted
## The beach layout read from a beach scene's nodes: the kinds painted on %Ground and the
## cells of the props instanced under %Decor and %World. Built once, never changed after.

var _size: Vector2i
var _kinds: PackedByteArray   # row-major over _size
var _cells := {}               # scene path -> read-only Array[Vector2i]
static var _none: Array[Vector2i] = _read_only([])

## Reads `beach` (a Beach scene root, in the tree or not): %Ground's cells and every
## instanced child of %Decor and %World whose scene is one of BeachLayout.PROP_SCENES.
static func from_scene(beach: Node) -> BeachMap:
	var map := BeachMap.new()
	var ground := beach.get_node("%Ground") as TileMapLayer
	map._size = ground.get_used_rect().end
	map._kinds.resize(map._size.x * map._size.y)
	for y in map._size.y:
		for x in map._size.x:
			var data := ground.get_cell_tile_data(Vector2i(x, y))
			map._kinds[y * map._size.x + x] = BeachLayout.Kind.DEEP if data == null else int(data.get_custom_data("kind"))
	var found := {}
	for parent_name: String in ["Decor", "World"]:
		for child in beach.get_node("%" + parent_name).get_children():
			if child.scene_file_path in BeachLayout.PROP_SCENES:
				if not found.has(child.scene_file_path):
					found[child.scene_file_path] = [] as Array[Vector2i]
				(found[child.scene_file_path] as Array[Vector2i]).append(BeachLayout.cell_of_base((child as Node2D).position))
	for path: String in found:
		map._cells[path] = _read_only(found[path])
	return map

## The painted map's size in cells: %Ground.get_used_rect().end (the map starts at (0, 0)).
func size() -> Vector2i:
	return _size

## The kind painted at `cell`, from the tile's "kind" custom data;
## BeachLayout.Kind.DEEP for a cell outside size() or with no tile.
func kind_at(cell: Vector2i) -> int:
	if not Rect2i(Vector2i.ZERO, _size).has_point(cell):
		return BeachLayout.Kind.DEEP
	return _kinds[cell.y * _size.x + cell.x]

## The cells of the props instanced from `scene_path`, in scene-tree order (%Decor's children
## first, then %World's), each BeachLayout.cell_of_base(position). Read-only; empty if none.
func cells_of(scene_path: String) -> Array[Vector2i]:
	return _cells.get(scene_path, _none)

static func _read_only(cells: Array[Vector2i]) -> Array[Vector2i]:
	cells.make_read_only()
	return cells
