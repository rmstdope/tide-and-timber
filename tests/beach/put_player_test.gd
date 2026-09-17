extends GdUnitTestSuite
## Beach.put_player: the man put on a cell at once, standing still, with the view on him.

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var camera: LooseCamera

func before_test() -> void:
	runner = scene_runner("res://src/beach/beach.tscn")
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	camera = beach.get_node("%Camera") as LooseCamera

func after_test() -> void:
	get_tree().paused = false

func test_put_player_moves_him_faces_and_snaps_the_camera() -> void:
	beach.put_player(Vector2i(40, 12), Walk.Facing.LEFT)
	assert_vector(player.global_position).is_equal(BeachLayout.cell_centre(Vector2i(40, 12)))
	assert_int(player.facing).is_equal(Walk.Facing.LEFT)
	assert_vector(player.velocity).is_equal(Vector2.ZERO)
	assert_vector(camera.centre).is_equal(player.global_position)
	assert_str(String((player.get_node("%Sprite") as AnimatedSprite2D).animation)).is_equal("still_left")

func test_put_player_drops_a_click_walk() -> void:
	var walker := beach.get_node("%ClickWalker") as ClickWalker
	walker.click_at(BeachLayout.cell_centre(Vector2i(100, 12)))
	assert_bool(walker.is_walking()).is_true()
	beach.put_player(Vector2i(40, 12), Walk.Facing.DOWN)
	assert_bool(walker.is_walking()).is_false()
	assert_vector(player.auto_direction).is_equal(Vector2.ZERO)

func test_put_player_works_while_paused() -> void:
	get_tree().paused = true
	beach.put_player(Vector2i(60, 12), Walk.Facing.DOWN)
	assert_vector(player.global_position).is_equal(BeachLayout.cell_centre(Vector2i(60, 12)))
	assert_vector(camera.centre).is_equal(player.global_position)
