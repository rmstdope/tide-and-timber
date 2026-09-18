extends GdUnitTestSuite

# The title screen's art is painted at 640x360, at the island's pixel density (tr-1o0.2).
# One scene per test, built in before_test: never a second one inside a test.

var title: Control

func before_test() -> void:
	title = auto_free((load("res://src/title/title_screen.tscn") as PackedScene).instantiate())

func _rect(path: String) -> Rect2:
	return (title.get_node("Art/" + path) as Control).get_rect()

func test_the_art_is_drawn_at_one_times_the_picture() -> void:
	var art := title.get_node("Art") as Control
	assert_vector(art.scale).is_equal(Vector2.ONE)
	assert_vector(art.size).is_equal(Screen.SIZE)
	for path: String in ["%MenuClip", "Title", "Tagline"]:
		var n := title.get_node(path)
		assert_bool(art.is_ancestor_of(n)).override_failure_message(path).is_false()

func test_the_bands_tile_the_picture_from_top_to_bottom() -> void:
	var bands := ["Sky1", "Sky2", "Sky3", "Sea", "DeepSea", "SandEdge", "Sand"]
	var boundaries := [0.0, 76.0, 136.0, 198.0, 250.0, 290.0, 298.0, 360.0]
	assert_float(boundaries[-1]).is_equal(Screen.HEIGHT)
	for i in bands.size():
		var r := _rect(bands[i])
		assert_float(r.position.x).override_failure_message(bands[i]).is_equal(0.0)
		assert_float(r.size.x).override_failure_message(bands[i]).is_equal(Screen.WIDTH)
		assert_float(r.position.y).override_failure_message(bands[i]).is_equal(boundaries[i])
		assert_float(r.end.y).override_failure_message(bands[i]).is_equal(boundaries[i + 1])

func test_the_sun_is_half_set_on_the_horizon() -> void:
	var sun := _rect("Sun")
	assert_that(sun).is_equal(Rect2(304, 169, 32, 29))
	assert_float(sun.end.y).is_equal(_rect("Sea").position.y)
	assert_float(sun.get_center().x).is_equal(Screen.CENTRE.x)

func test_the_wreck_straddles_the_horizon() -> void:
	var polygon: PackedVector2Array = title.get_node("Art/Wreck").polygon
	assert_that(polygon).is_equal(PackedVector2Array([
		Vector2(500, 193), Vector2(545, 193), Vector2(540, 206), Vector2(495, 206)]))
	var horizon := _rect("Sea").position.y
	var ys: Array[float] = []
	for p in polygon:
		ys.append(p.y)
	assert_float(ys.min()).is_less(horizon)
	assert_float(ys.max()).is_greater(horizon)

func test_the_palm_is_planted_in_the_sand() -> void:
	var trunk := _rect("PalmTrunk")
	assert_that(trunk).is_equal(Rect2(20, 244, 6, 55))
	assert_float(trunk.end.y).is_equal(_rect("SandEdge").end.y + 1)
	var leaves := _rect("PalmLeaves")
	assert_that(leaves).is_equal(Rect2(3, 238, 40, 6))
	assert_float(leaves.end.y).is_equal(trunk.position.y)
	assert_that(_rect("PalmLeavesShade")).is_equal(Rect2(3, 244, 40, 3))

func test_the_foam_is_spread_across_the_sea() -> void:
	var waves := title.get_node("%Waves").get_children()
	var expected := [Rect2(20, 230, 30, 2), Rect2(100, 244, 20, 2), Rect2(190, 260, 45, 2),
		Rect2(330, 236, 28, 2), Rect2(470, 252, 36, 2)]
	assert_int(waves.size()).is_equal(expected.size())
	var water := _rect("Sea").merge(_rect("DeepSea"))
	var last_end := -1.0
	for i in waves.size():
		var r := (waves[i] as Control).get_rect()
		assert_that(r).is_equal(expected[i])
		assert_bool(water.encloses(r)).is_true()
		assert_float(r.position.x).is_greater(last_end)
		last_end = r.end.x
