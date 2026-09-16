extends GdUnitTestSuite

func _grid() -> WalkGrid:
	return WalkGrid.new(Vector2i(8, 4), func(t: Vector2i) -> bool:
		return t.y >= 3 or t.x < 0 or t.y < 0 or t.x >= 8)

func _on_free_point(g: WalkGrid, w: Vector2) -> bool:
	var p := g.point_at(w)
	return g.is_free(p) and g.centre(p) == w

func test_solid_tile_blocks_points_whose_feet_overlap_it() -> void:
	var g := _grid()
	assert_bool(g.is_free(Vector2i(2, 5))).is_true()
	assert_bool(g.is_free(Vector2i(2, 6))).is_false()

func test_obstacle_blocks_points_its_box_overlaps() -> void:
	var g := _grid()
	g.refresh([Rect2(32, 16, 8, 8)])
	assert_bool(g.is_free(Vector2i(4, 2))).is_false()
	assert_bool(g.is_free(Vector2i(5, 3))).is_false()
	assert_bool(g.is_free(Vector2i(6, 2))).is_true()
	assert_bool(g.is_free(Vector2i(4, 4))).is_true()

func test_refresh_forgets_old_obstacles() -> void:
	var g := _grid()
	g.refresh([Rect2(32, 16, 8, 8)])
	g.refresh([])
	assert_bool(g.is_free(Vector2i(4, 2))).is_true()

func test_is_clear_uses_exact_position() -> void:
	var g := _grid()
	g.refresh([Rect2(32, 16, 8, 8)])
	assert_bool(g.is_clear(Vector2(36, 30))).is_true()
	assert_bool(g.is_clear(Vector2(36, 29))).is_false()

func test_start_point_steps_off_a_blocked_point() -> void:
	var g := _grid()
	g.refresh([Rect2(32, 16, 8, 8)])
	var p := g.start_point(Vector2(36, 26))
	assert_bool(p != WalkGrid.NONE).is_true()
	assert_bool(g.is_free(p)).is_true()
	assert_bool(absi(p.x - 4) <= 2 and absi(p.y - 3) <= 2).is_true()

func test_route_straight_ends_on_click() -> void:
	var r := _grid().route_to_point(Vector2(12, 12), Vector2(60, 12))
	assert_bool(r.short).is_false()
	assert_vector(r.waypoints[-1]).is_equal(Vector2(60, 12))

func test_route_goes_round_obstacle() -> void:
	var g := _grid()
	g.refresh([Rect2(32, 0, 8, 24)])
	var r := g.route_to_point(Vector2(12, 12), Vector2(60, 12))
	assert_bool(r.short).is_false()
	assert_vector(r.waypoints[-1]).is_equal(Vector2(60, 12))
	assert_bool(Array(r.waypoints).any(func(w: Vector2) -> bool: return w.y >= 36)).is_true()
	for i in r.waypoints.size() - 1:
		assert_bool(_on_free_point(g, r.waypoints[i])).is_true()

func test_walled_off_stops_nearest_and_is_short() -> void:
	var g := _grid()
	g.refresh([Rect2(32, 0, 8, 48)])
	var r := g.route_to_point(Vector2(12, 12), Vector2(60, 12))
	assert_bool(r.short).is_true()
	assert_float(r.waypoints[-1].x).is_less_equal(27.0)
	for w in r.waypoints:
		assert_bool(_on_free_point(g, w)).is_true()

func test_click_just_inside_solid_is_not_short() -> void:
	var r := _grid().route_to_point(Vector2(20, 12), Vector2(20, 50))
	assert_bool(r.short).is_false()
	assert_vector(r.waypoints[-1]).is_equal(Vector2(20, 44))

func test_already_there() -> void:
	var r := _grid().route_to_point(Vector2(60, 12), Vector2(61, 12))
	assert_int(r.waypoints.size()).is_equal(1)
	assert_vector(r.waypoints[0]).is_equal(Vector2(61, 12))
	assert_bool(r.short).is_false()

func test_route_into_reach_ends_beside_the_thing() -> void:
	var g := _grid()
	g.refresh([Rect2(50, 20, 12, 8)])
	var r := g.route_into_reach(Vector2(12, 12), Vector2(56, 28), 18.0)
	assert_bool(r.short).is_false()
	assert_bool(_on_free_point(g, r.waypoints[-1])).is_true()
	assert_float(r.waypoints[-1].distance_to(Vector2(56, 28))).is_less_equal(18.0)

func test_route_into_reach_walled_off_is_short() -> void:
	var g := _grid()
	g.refresh([Rect2(32, 0, 8, 48)])
	var r := g.route_into_reach(Vector2(12, 12), Vector2(56, 20), 18.0)
	assert_bool(r.short).is_true()
	assert_float(r.waypoints[-1].x).is_less_equal(27.0)
