extends GdUnitTestSuite

func _unique(root: Node, node: Node, node_name: String) -> Node:
	node.name = node_name
	root.add_child(node)
	node.owner = root
	node.unique_name_in_owner = true
	return node

func test_lines_give_size_rows_then_props() -> void:
	var root := Node2D.new()
	var ground := _unique(root, TileMapLayer.new(), "Ground") as TileMapLayer
	ground.tile_set = load("res://src/beach/beach_tiles.tres") as TileSet
	ground.set_cell(Vector2i(0, 0), 0, Vector2i(1, 0))
	ground.set_cell(Vector2i(1, 0), 0, Vector2i(5, 0))
	ground.set_cell(Vector2i(1, 1), 0, Vector2i(6, 0))
	var decor := _unique(root, Node2D.new(), "Decor")
	var world := _unique(root, Node2D.new(), "World")
	var wood := (load("res://src/beach/props/driftwood.tscn") as PackedScene).instantiate() as Node2D
	wood.position = Vector2(24, 16)
	decor.add_child(wood)
	var palm := (load("res://src/beach/props/palm.tscn") as PackedScene).instantiate() as Node2D
	palm.position = Vector2(8, 32)
	world.add_child(palm)
	assert_array(Array(BeachLayoutDump.lines(root))).is_equal([
		"size 2x2", "row 0 15", "row 1 .6",
		"prop Decor res://src/beach/props/driftwood.tscn 24.00,16.00",
		"prop World res://src/beach/props/palm.tscn 8.00,32.00"])
	root.free()
