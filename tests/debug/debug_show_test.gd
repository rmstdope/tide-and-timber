extends GdUnitTestSuite
## The Show page's rules: its rows, the readout's lines and the outlines' geometry.

var menu: DebugMenu

func before_test() -> void:
	menu = DebugMenu.new()

func after_test() -> void:
	DebugSwitches.readout = false
	DebugSwitches.collision_areas = false
	DebugSwitches.use_areas = false

func _rows() -> Array[DebugRow]:
	DebugShow.add_rows(menu)
	return menu.rows_of(DebugMenu.Page.SHOW)

func test_show_page_rows_in_order() -> void:
	var rows := _rows()
	assert_array(rows.map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Readout", "Collision areas", "Use areas"])
	for p: int in DebugMenu.Page.values():
		if p != DebugMenu.Page.SHOW:
			assert_array(menu.rows_of(p)).is_empty()

func test_switches_start_off() -> void:
	assert_bool(DebugSwitches.readout).is_false()
	assert_bool(DebugSwitches.collision_areas).is_false()
	assert_bool(DebugSwitches.use_areas).is_false()
	for r in _rows():
		assert_str(r.value_text()).is_equal("Off")

func test_step_flips_either_way() -> void:
	var rows := _rows()
	rows[1].step.call(1)
	assert_bool(DebugSwitches.collision_areas).is_true()
	assert_str(rows[1].value_text()).is_equal("On")
	rows[1].step.call(1)
	assert_bool(DebugSwitches.collision_areas).is_false()
	rows[1].step.call(-1)
	assert_bool(DebugSwitches.collision_areas).is_true()
	assert_bool(DebugSwitches.readout).is_false()
	assert_bool(DebugSwitches.use_areas).is_false()

func test_select_flips_and_is_done() -> void:
	var rows := _rows()
	assert_int(rows[0].select.call()).is_equal(DebugRow.Result.DONE)
	assert_bool(DebugSwitches.readout).is_true()
	rows[2].select.call()
	assert_bool(DebugSwitches.use_areas).is_true()

func _beach_lines() -> Array[String]:
	var clock := GameClock.new()
	clock.total_minutes = 2 * 1440 + 16 * 60 + 30
	return DebugShow.readout_lines(60.0, clock, 4.0, Vector2(152.4, 83.6))

func test_readout_lines_on_the_beach() -> void:
	assert_array(_beach_lines()).is_equal(["DAY 3 16:30", "SPEED x4", "FPS 60", "X 152 Y 84"])

func test_readout_lines_in_the_story() -> void:
	assert_array(DebugShow.readout_lines(59.6, null, 1.0, null)).is_equal(["FPS 60"])

func test_readout_lines_draw_in_glyphs() -> void:
	for line in _beach_lines():
		for ch in line:
			if ch != " ":
				assert_int(Glyphs.ORDER.find(ch)).is_greater_equal(0)

func test_cells_in_clamps_to_the_map() -> void:
	assert_object(DebugShow.cells_in(Rect2(-10, -10, 40, 20))).is_equal(Rect2i(0, 0, 2, 1))
	assert_object(DebugShow.cells_in(Rect2(2900, 400, 320, 180)).end).is_equal(BeachLayout.MAP_SIZE)

func test_tile_edges_outline_a_solid_block() -> void:
	var solid := func(c: Vector2i) -> bool: return c == Vector2i(1, 1) or c == Vector2i(2, 1)
	var pts := DebugShow.tile_edges(Rect2i(0, 0, 4, 3), solid)
	assert_int(pts.size()).is_equal(12)
	var found := false
	for i in range(0, pts.size(), 2):
		if pts[i] == Vector2(16, 16.5) and pts[i + 1] == Vector2(32, 16.5):
			found = true
		for p in [pts[i], pts[i + 1]]:
			assert_float(p.x).is_not_equal(31.5)
			assert_float(p.x).is_not_equal(32.5)
	assert_bool(found).is_true()

func test_tile_edges_off_map_neighbour_is_open() -> void:
	var solid := func(c: Vector2i) -> bool: return c == Vector2i.ZERO
	assert_int(DebugShow.tile_edges(Rect2i(0, 0, 1, 1), solid).size()).is_equal(8)

func test_solid_rects_include_shapes_under_world() -> void:
	var world: Node2D = auto_free(Node2D.new())
	var body := StaticBody2D.new()
	body.position = Vector2(100, 50)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 8)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	body.add_child(shape)
	world.add_child(body)
	var mover := CharacterBody2D.new()
	var off := CollisionShape2D.new()
	off.shape = RectangleShape2D.new()
	off.disabled = true
	mover.add_child(off)
	world.add_child(mover)
	add_child(world)
	assert_array(DebugShow.solid_rects(world)).is_equal([Rect2(92, 42, 16, 8)])

func test_use_spots_skip_gone_usables() -> void:
	var holder: Node2D = auto_free(Node2D.new())
	add_child(holder)
	var a := Usable.new()
	a.position = Vector2(10, 0)
	holder.add_child(a)
	var parent := Node2D.new()
	holder.add_child(parent)
	var b := Usable.new()
	b.position = Vector2(30, 0)
	parent.add_child(b)
	parent.queue_free()
	assert_array(DebugShow.use_spots(get_tree())).is_equal([Vector2(10, 0)])
