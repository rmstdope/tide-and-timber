extends GdUnitTestSuite

const TILES := preload("res://src/beach/beach_tiles.tres")

func test_tile_set_shape() -> void:
	var tile_set := TILES
	assert_vector(Vector2(tile_set.tile_size)).is_equal(Vector2(16, 16))
	assert_int(tile_set.get_physics_layers_count()).is_equal(1)
	assert_int(tile_set.get_physics_layer_collision_layer(0)).is_equal(1)
	assert_int(tile_set.get_physics_layer_collision_mask(0)).is_equal(1)
	var source := tile_set.get_source(0)
	assert_object(source).is_instanceof(TileSetAtlasSource)
	assert_str((source as TileSetAtlasSource).texture.resource_path).is_equal("res://assets/beach/tiles.png")
	assert_int((source as TileSetAtlasSource).get_tiles_count()).is_equal(7)

func test_only_solid_kinds_collide() -> void:
	var source := TILES.get_source(0) as TileSetAtlasSource
	for kind: int in BeachLayout.Kind.values():
		var data := source.get_tile_data(Vector2i(kind, 0), 0)
		var solid := BeachLayout.is_solid(kind)
		assert_int(data.get_collision_polygons_count(0)).override_failure_message(BeachLayout.Kind.keys()[kind]) \
			.is_equal(1 if solid else 0)
		if solid:
			var points := data.get_collision_polygon_points(0, 0)
			assert_int(points.size()).is_equal(4)
			for p in points:
				assert_float(absf(p.x)).is_equal(8.0)
				assert_float(absf(p.y)).is_equal(8.0)

func test_every_tile_carries_its_kind() -> void:
	assert_int(TILES.get_custom_data_layers_count()).is_equal(1)
	assert_str(TILES.get_custom_data_layer_name(0)).is_equal("kind")
	assert_int(TILES.get_custom_data_layer_type(0)).is_equal(TYPE_INT)
	var source := TILES.get_source(0) as TileSetAtlasSource
	for kind: int in BeachLayout.Kind.values():
		assert_int(source.get_tile_data(Vector2i(kind, 0), 0).get_custom_data("kind")).is_equal(kind)

func test_waves_tile_set_animates_nine_frames_together() -> void:
	var waves := load("res://src/beach/beach_waves.tres") as TileSet
	assert_object(waves).is_not_null()
	if waves == null:
		return
	assert_vector(Vector2(waves.tile_size)).is_equal(Vector2(16, 16))
	assert_int(waves.get_physics_layers_count()).is_equal(0)
	var source := waves.get_source(0) as TileSetAtlasSource
	assert_str(source.texture.resource_path).is_equal("res://assets/beach/waves.png")
	assert_int(source.get_tiles_count()).is_equal(1)
	assert_int(source.get_tile_animation_frames_count(Vector2i.ZERO)).is_equal(9)
	for frame in 9:
		assert_bool(is_equal_approx(source.get_tile_animation_frame_duration(Vector2i.ZERO, frame), 0.16)).is_true()
	assert_int(source.get_tile_animation_columns(Vector2i.ZERO)).is_equal(0)
	assert_int(source.get_tile_animation_mode(Vector2i.ZERO)).is_equal(TileSetAtlasSource.TILE_ANIMATION_MODE_DEFAULT)
	assert_float(source.get_tile_animation_speed(Vector2i.ZERO)).is_equal(1.0)
