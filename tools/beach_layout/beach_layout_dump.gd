class_name BeachLayoutDump
extends RefCounted
## A beach's authored layout as plain text, for reading a layout change in review
## (a TileMapLayer's tile_map_data is not readable in a diff). Development only.

const PLAYER := "res://src/player/player.tscn"

## `size <w>x<h>`, then `row <y> <digits>` (each cell's atlas x, `.` when empty), then
## `prop <Decor|World> <scene> <x>,<y>` for every instanced child of %Decor then %World but the man.
static func lines(beach: Node) -> PackedStringArray:
	var out := PackedStringArray()
	var ground := beach.get_node("%Ground") as TileMapLayer
	var size := ground.get_used_rect().end
	out.append("size %dx%d" % [size.x, size.y])
	for y in size.y:
		var row := ""
		for x in size.x:
			var cell := Vector2i(x, y)
			row += "." if ground.get_cell_source_id(cell) == -1 else str(ground.get_cell_atlas_coords(cell).x)
		out.append("row %d %s" % [y, row])
	for parent_name: String in ["Decor", "World"]:
		for child in beach.get_node("%" + parent_name).get_children():
			if child.scene_file_path.is_empty() or child.scene_file_path == PLAYER:
				continue
			var at := (child as Node2D).position
			out.append("prop %s %s %.2f,%.2f" % [parent_name, child.scene_file_path, at.x, at.y])
	return out
