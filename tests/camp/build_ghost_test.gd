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

func test_bad_spot_on_standard_has_a_cross() -> void:
	var g := _ghost()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, false)
	assert_bool(g.shows_cross()).is_true()

func test_good_spot_on_standard_stays_plain() -> void:
	var g := _ghost()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, true)
	assert_bool(g.shows_cross()).is_false()

func test_bad_fire_spot_on_standard_has_a_cross() -> void:
	var g := _ghost()
	g.show_at(BuildMenu.Thing.FIRE, Vector2.ZERO, false)
	assert_bool(g.shows_cross()).is_true()

func test_the_cross_follows_the_spot() -> void:
	var g := _ghost()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, false)
	assert_bool(g.shows_cross()).is_true()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, true)
	assert_bool(g.shows_cross()).is_false()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, false)
	assert_bool(g.shows_cross()).is_true()

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

func test_changing_cues_leaves_the_outline_alone() -> void:
	var g := _ghost()
	g.show_at(BuildMenu.Thing.LEAN_TO, Vector2.ZERO, false)
	await await_idle_frame()
	var draws := [0]
	g.draw.connect(func() -> void: draws[0] += 1)
	var changes := [0]
	var count_change := func() -> void: changes[0] += 1
	Display.changed.connect(count_change)
	_shapes()
	await await_idle_frame()
	assert_int(draws[0]).is_equal(0)
	assert_bool(g.shows_cross()).is_true()
	Display.prefs.step(DisplayPrefs.Setting.CUES, -1)
	await await_idle_frame()
	assert_int(draws[0]).is_equal(0)
	assert_bool(g.shows_cross()).is_true()
	Display.changed.disconnect(count_change)
	assert_int(changes[0]).is_equal(2)

func test_a_hidden_outline_is_not_redrawn() -> void:
	var g := _ghost()
	var draws := [0]
	g.draw.connect(func() -> void: draws[0] += 1)
	_shapes()
	await await_idle_frame()
	assert_int(draws[0]).is_equal(0)
