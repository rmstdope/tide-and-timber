class_name BeachTileSet
extends RefCounted
## Builds the beach TileSet from tiles.png: one tile per BeachLayout.Kind, solid kinds collide.

static func build(atlas: Texture2D) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(BeachLayout.TILE, BeachLayout.TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	var source := TileSetAtlasSource.new()
	source.texture = atlas
	source.texture_region_size = Vector2i(BeachLayout.TILE, BeachLayout.TILE)
	tile_set.add_source(source, 0)
	for kind: int in BeachLayout.Kind.values():
		source.create_tile(Vector2i(kind, 0))
		if BeachLayout.is_solid(kind):
			var data := source.get_tile_data(Vector2i(kind, 0), 0)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	return tile_set
