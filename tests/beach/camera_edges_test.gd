extends GdUnitTestSuite
## The view stops at the island's edge: it never shows anything that is not the island.

const SCENE := "res://src/beach/beach.tscn"
const D := 1.0 / 60.0

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

func _view() -> Rect2:
	return Rect2(camera.global_position - Screen.CENTRE, Screen.SIZE)

func _follow(steps: int) -> void:
	for i in steps:
		camera._physics_process(D)

func test_the_view_stops_at_the_treeline() -> void:
	_place(Vector2i(92, 9))
	assert_vector(camera.global_position).is_equal(Vector2(1480, 180))
	assert_float(_view().position.y).is_equal(0.0)

func test_the_view_stops_at_the_water() -> void:
	_place(Vector2i(92, 17))
	assert_vector(camera.global_position).is_equal(Vector2(1480, 236))
	assert_float(_view().end.y).is_equal(416.0)

func test_the_view_stops_at_both_ends_of_the_strip() -> void:
	_place(Vector2i(16, 11))
	assert_float(camera.global_position.x).is_equal(320.0)
	assert_float(_view().position.x).is_equal(0.0)
	_place(Vector2i(167, 11))
	assert_float(camera.global_position.x).is_equal(2624.0)
	assert_float(_view().end.x).is_equal(2944.0)

func test_the_view_never_leaves_the_island() -> void:
	for x in [12, 16, 92, 167, 171]:
		for y in [9, 11, 14, 17]:
			_place(Vector2i(x, y))
			assert_bool(BeachLayout.world_rect().encloses(_view())) \
				.override_failure_message("view %s left the island at %s" % [_view(), Vector2i(x, y)]).is_true()

func test_he_walks_up_the_screen_once_the_view_holds() -> void:
	_place(Vector2i(92, 13))
	player.global_position = BeachLayout.cell_centre(Vector2i(92, 9))
	_follow(300)
	assert_vector(camera.global_position).is_equal(Vector2(1480, 180))
	assert_float(player.global_position.y - camera.global_position.y).is_equal(-28.0)

func test_following_resumes_when_he_walks_back() -> void:
	_place(Vector2i(92, 13))
	player.global_position = BeachLayout.cell_centre(Vector2i(92, 9))
	_follow(300)
	assert_float(camera.global_position.y).is_equal(180.0)
	player.global_position = BeachLayout.cell_centre(Vector2i(92, 15))
	_follow(300)
	assert_float(camera.global_position.y).is_equal(248.0 - LooseFollow.DEAD_ZONE_HALF.y)

func test_the_spawn_is_untouched_by_the_limits() -> void:
	_place(BeachLayout.SPAWN_CELL)
	assert_vector(camera.global_position).is_equal(Vector2(1480, 184))
