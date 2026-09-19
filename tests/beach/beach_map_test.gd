extends GdUnitTestSuite

const K := BeachLayout.Kind

func _beach() -> Node:
	return (load(BeachLayout.SCENE) as PackedScene).instantiate()

func test_reads_kinds_and_props_from_a_scene() -> void:
	var beach := _beach()
	var map := BeachMap.from_scene(beach)
	beach.free()
	assert_vector(Vector2(map.size())).is_equal(Vector2(184, 26))
	assert_int(map.kind_at(Vector2i(92, 14))).is_equal(K.WET_SAND)
	assert_int(map.kind_at(Vector2i(-1, 5))).is_equal(K.DEEP)
	assert_int(map.kind_at(Vector2i(184, 5))).is_equal(K.DEEP)
	assert_array(map.cells_of(BeachLayout.SPRING)).is_equal([Vector2i(96, 9)])

func test_a_moved_prop_moves_its_cell() -> void:
	var beach := _beach()
	var before := BeachMap.from_scene(beach).cells_of(BeachLayout.DRIFTWOOD)
	for child in beach.get_node("%Decor").get_children():
		if child.scene_file_path == BeachLayout.DRIFTWOOD:
			(child as Node2D).position += Vector2(16, 0)
			break
	var after := BeachMap.from_scene(beach).cells_of(BeachLayout.DRIFTWOOD)
	beach.free()
	assert_vector(Vector2(after[0])).is_equal(Vector2(before[0] + Vector2i(1, 0)))
	assert_array(after.slice(1)).is_equal(before.slice(1))

func test_an_erased_cell_reads_deep() -> void:
	var beach := _beach()
	(beach.get_node("%Ground") as TileMapLayer).erase_cell(Vector2i(92, 11))
	var map := BeachMap.from_scene(beach)
	beach.free()
	assert_int(map.kind_at(Vector2i(92, 11))).is_equal(K.DEEP)
	assert_int(map.kind_at(Vector2i(92, 12))).is_equal(K.SAND)

func test_cell_lists_are_read_only() -> void:
	var beach := _beach()
	var map := BeachMap.from_scene(beach)
	beach.free()
	for path: String in BeachLayout.PROP_SCENES:
		assert_bool(map.cells_of(path).is_read_only()).is_true()
	assert_bool(map.cells_of("res://nothing.tscn").is_read_only()).is_true()
	assert_array(map.cells_of("res://nothing.tscn")).is_empty()
