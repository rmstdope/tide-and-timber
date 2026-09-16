extends GdUnitTestSuite

const SCENE := "res://src/beach/beach.tscn"

var runner: GdUnitSceneRunner
var beach: Node
var player: Player
var camera: LooseCamera

func before_test() -> void:
	runner = scene_runner(SCENE)
	beach = runner.scene()
	player = beach.get_node("%Player") as Player
	camera = beach.get_node("%Camera") as LooseCamera

func _place(cell: Vector2i) -> void:
	player.global_position = BeachLayout.cell_centre(cell)
	camera.snap_to_target()

func _animation() -> StringName:
	return (player.get_node("%Sprite") as AnimatedSprite2D).animation

func _count(parent: Node, suffix: String) -> int:
	return parent.get_children().filter(func(n: Node) -> bool: return n.scene_file_path.ends_with(suffix)).size()

func test_wakes_in_the_middle_facing_down_still() -> void:
	assert_vector(player.global_position).is_equal(Vector2(1480, 184))
	assert_int(player.facing).is_equal(Walk.Facing.DOWN)
	assert_that(_animation()).is_equal(&"still_down")
	assert_vector(camera.global_position).is_equal(Vector2(1480, 184))

func test_ground_matches_layout() -> void:
	var ground := beach.get_node("%Ground") as TileMapLayer
	for y in BeachLayout.MAP_SIZE.y:
		for x in BeachLayout.MAP_SIZE.x:
			var cell := Vector2i(x, y)
			if ground.get_cell_atlas_coords(cell) != Vector2i(BeachLayout.kind_at(cell), 0):
				fail("ground at %s is %s" % [cell, ground.get_cell_atlas_coords(cell)])
				return

func test_props_are_placed() -> void:
	var world := beach.get_node("%World")
	assert_int(_count(world, "palm.tscn")).is_equal(BeachLayout.PALMS.size())
	assert_int(_count(world, "rock.tscn")).is_equal(BeachLayout.ROCKS.size())
	assert_int(_count(world, "boulder.tscn")).is_equal(BeachLayout.BOULDERS.size())
	assert_int(_count(beach.get_node("%Decor"), "driftwood.tscn")).is_equal(BeachLayout.DRIFTWOOD.size())
	var base := BeachLayout.cell_base(BeachLayout.PALMS[0])
	assert_bool(world.get_children().any(func(n: Node) -> bool:
		return n.scene_file_path.ends_with("palm.tscn") and (n as Node2D).position == base)).is_true()

func test_tall_things_sort_with_him() -> void:
	var world := beach.get_node("%World") as Node2D
	assert_bool(world.y_sort_enabled).is_true()
	assert_object(player.get_parent()).is_same(world)
	for n in world.get_children():
		if n.scene_file_path.ends_with("palm.tscn"):
			assert_float((n.get_node("Sprite") as Sprite2D).offset.y).is_equal(-24.0)
		elif n.scene_file_path.ends_with("boulder.tscn"):
			assert_float((n.get_node("Sprite") as Sprite2D).offset.y).is_equal(-16.0)

func test_no_words() -> void:
	assert_array(beach.find_children("*", "Label", true, false)).is_empty()
	assert_array(beach.find_children("*", "RichTextLabel", true, false)).is_empty()
