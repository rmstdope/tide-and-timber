extends GdUnitTestSuite

func before_test() -> void:
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	Display.use_prefs(DisplayPrefs.new())

func _ghost() -> BuildGhost:
	var g := auto_free(BuildGhost.new()) as BuildGhost
	add_child(g)
	return g

func _shapes() -> void:
	Display.prefs.step(DisplayPrefs.Setting.CUES, 1)

func test_bad_spot_on_standard_has_no_cross() -> void:
	var g := _ghost()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, false)
	assert_bool(g.shows_cross()).is_false()

func test_bad_spot_on_shapes_has_a_cross() -> void:
	var g := _ghost()
	_shapes()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, false)
	assert_bool(g.shows_cross()).is_true()

func test_good_spot_on_shapes_stays_plain() -> void:
	var g := _ghost()
	_shapes()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, true)
	assert_bool(g.shows_cross()).is_false()

func test_bad_fire_spot_on_shapes_has_a_cross() -> void:
	var g := _ghost()
	_shapes()
	g.show_at(BuildMenu.Thing.FIRE, Vector2.ZERO, false)
	assert_bool(g.shows_cross()).is_true()

func test_changing_cues_redraws_the_outline() -> void:
	var g := _ghost()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, false)
	await await_idle_frame()
	var draws := [0]
	g.draw.connect(func() -> void: draws[0] += 1)
	_shapes()
	await await_idle_frame()
	assert_int(draws[0]).is_equal(1)
	assert_bool(g.shows_cross()).is_true()

func test_a_hidden_outline_is_not_redrawn() -> void:
	var g := _ghost()
	var draws := [0]
	g.draw.connect(func() -> void: draws[0] += 1)
	_shapes()
	await await_idle_frame()
	assert_int(draws[0]).is_equal(0)
