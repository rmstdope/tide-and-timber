extends GdUnitTestSuite

const K := Item.Kind

func _sample() -> SaveData:
	var d := SaveData.new()
	d.player_position = Vector2(1480, 184)
	d.player_facing = Walk.Facing.LEFT
	var slots: Array[Dictionary] = [{"kind": K.DRIFTWOOD, "count": 3}, {}, {"kind": K.SHELLFISH, "count": 12}, {}, {}, {}, {}, {}]
	d.inventory_slots = slots
	var cells: Array[Vector2i] = [Vector2i(30, 13)]
	var none: Array[Vector2i] = []
	d.taken = {"driftwood": cells, "shellfish": none}
	d.clock_minutes = 1800.0
	return d

func _json_files() -> Dictionary:
	var files := _sample().to_files()
	var out := {}
	for stem: String in files:
		out[stem] = JSON.parse_string(JSON.stringify(files[stem]))
	return out

func test_to_files_exact_shape() -> void:
	var files := _sample().to_files()
	assert_dict(files["meta"]).is_equal({"version": 1, "game_version": str(ProjectSettings.get_setting("application/config/version"))})
	assert_dict(files["player"]).is_equal({"x": 1480.0, "y": 184.0, "facing": "left"})
	assert_dict(files["inventory"]["slots"][0]).is_equal({"item": "driftwood", "count": 3})
	assert_dict(files["inventory"]["slots"][1]).is_equal({})
	assert_int(files["inventory"]["slots"].size()).is_equal(8)
	assert_array(files["world"]["taken"]["driftwood"]).is_equal([[30, 13]])
	assert_array(files["world"]["taken"]["shellfish"]).is_equal([])
	assert_dict(files["clock"]).is_equal({"total_minutes": 1800.0})

func test_round_trip_through_json_text() -> void:
	var d := SaveData.from_files(_json_files())
	var s := _sample()
	assert_object(d).is_not_null()
	assert_vector(d.player_position).is_equal(s.player_position)
	assert_int(d.player_facing).is_equal(s.player_facing)
	assert_array(d.inventory_slots).is_equal(s.inventory_slots)
	assert_int(typeof(d.inventory_slots[0]["kind"])).is_equal(TYPE_INT)
	assert_int(typeof(d.inventory_slots[0]["count"])).is_equal(TYPE_INT)
	assert_dict(d.taken).is_equal(s.taken)
	assert_int(typeof(d.taken["driftwood"][0])).is_equal(TYPE_VECTOR2I)
	assert_float(d.clock_minutes).is_equal(1800.0)

func test_meta_names_the_game_version() -> void:
	assert_str(_sample().to_files().meta.game_version).is_equal(str(ProjectSettings.get_setting("application/config/version")))

func test_meta_without_game_version_still_loads() -> void:
	var files := _json_files()
	files.meta.erase("game_version")
	assert_object(SaveData.from_files(files)).is_not_null()
	files.meta["game_version"] = 42
	assert_object(SaveData.from_files(files)).is_not_null()

func _rejected(mutate: Callable) -> void:
	var files := _json_files()
	mutate.call(files)
	assert_object(SaveData.from_files(files)).is_null()

func test_rejects() -> void:
	_rejected(func(f: Dictionary) -> void: f.erase("meta"))
	_rejected(func(f: Dictionary) -> void: f["meta"]["version"] = 2)
	_rejected(func(f: Dictionary) -> void: f["meta"]["version"] = 0)
	_rejected(func(f: Dictionary) -> void: f["meta"]["version"] = "1")
	_rejected(func(f: Dictionary) -> void: f["player"]["facing"] = "north")
	_rejected(func(f: Dictionary) -> void: f["inventory"]["slots"].pop_back())
	_rejected(func(f: Dictionary) -> void: f["inventory"]["slots"][0]["item"] = "rope")
	_rejected(func(f: Dictionary) -> void: f["inventory"]["slots"][0]["count"] = 2.5)
	_rejected(func(f: Dictionary) -> void: f["inventory"]["slots"][0]["count"] = 0)
	_rejected(func(f: Dictionary) -> void: f["world"]["taken"]["driftwood"][0] = [1])
	_rejected(func(f: Dictionary) -> void: f["player"] = "oops")
	_rejected(func(f: Dictionary) -> void: f["player"]["x"] = "1")
	_rejected(func(f: Dictionary) -> void: f["world"]["taken"] = [])
	_rejected(func(f: Dictionary) -> void: f.erase("clock"))
	_rejected(func(f: Dictionary) -> void: f["clock"]["total_minutes"] = "1800")
	_rejected(func(f: Dictionary) -> void: f["clock"]["total_minutes"] = -1.0)

func test_day() -> void:
	var d := SaveData.new()
	d.clock_minutes = 780.0
	assert_int(d.day()).is_equal(1)
	d.clock_minutes = 1800.0
	assert_int(d.day()).is_equal(2)
	d.clock_minutes = 4680.0
	assert_int(d.day()).is_equal(4)

func _camp_sample() -> SaveData:
	var d := _sample()
	d.lean_to_cells = BuildSite.cells_for(BuildMenu.Thing.LEAN_TO, Vector2i(92, 11), Walk.Facing.DOWN)
	d.has_fire = true
	d.fire_cell = Vector2i(92, 14)
	d.fire_lit = true
	d.fire_out_at = 1860.0
	return d

func _camp_json(d: SaveData) -> Dictionary:
	var files := d.to_files()
	var out := {}
	for stem: String in files:
		out[stem] = JSON.parse_string(JSON.stringify(files[stem]))
	return out

func test_camp_round_trip_through_json_text() -> void:
	var s := _camp_sample()
	var d := SaveData.from_files(_camp_json(s))
	assert_object(d).is_not_null()
	assert_array(d.lean_to_cells).is_equal(s.lean_to_cells)
	assert_int(typeof(d.lean_to_cells[0])).is_equal(TYPE_VECTOR2I)
	assert_bool(d.has_fire).is_true()
	assert_vector(d.fire_cell).is_equal(Vector2i(92, 14))
	assert_bool(d.fire_lit).is_true()
	assert_float(d.fire_out_at).is_equal(1860.0)

func test_camp_exact_shape() -> void:
	assert_dict(_camp_sample().to_files()["world"]["camp"]).is_equal({
		"lean_to": [[91, 12], [92, 12], [93, 12], [91, 13], [92, 13], [93, 13]],
		"fire": {"x": 92, "y": 14, "lit": true, "out_at": 1860.0}})
	assert_dict(SaveData.new().to_files()["world"]["camp"]).is_equal({})

func test_ash_fire_writes_no_out_at() -> void:
	var s := _camp_sample()
	s.fire_lit = false
	assert_dict(s.to_files()["world"]["camp"]["fire"]).is_equal({"x": 92, "y": 14, "lit": false})
	assert_bool(SaveData.from_files(_camp_json(s)).fire_lit).is_false()
	var files := _camp_json(s)
	files["world"]["camp"]["fire"]["out_at"] = 1860.0
	assert_float(SaveData.from_files(files).fire_out_at).is_equal(INF)

func test_lit_fire_without_clock_writes_no_out_at() -> void:
	var s := _camp_sample()
	s.fire_out_at = INF
	assert_bool(s.to_files()["world"]["camp"]["fire"].has("out_at")).is_false()
	assert_float(SaveData.from_files(_camp_json(s)).fire_out_at).is_equal(INF)

func test_save_without_camp_loads_with_no_camp() -> void:
	var files := _camp_json(_camp_sample())
	files["world"].erase("camp")
	var d := SaveData.from_files(files)
	assert_object(d).is_not_null()
	assert_array(d.lean_to_cells).is_empty()
	assert_bool(d.has_fire).is_false()

func _camp_rejected(mutate: Callable) -> void:
	var files := _camp_json(_camp_sample())
	mutate.call(files)
	assert_object(SaveData.from_files(files)).is_null()

func test_camp_rejects() -> void:
	_rejected(func(f: Dictionary) -> void: f["world"]["camp"] = [])
	_camp_rejected(func(f: Dictionary) -> void: f["world"]["camp"]["lean_to"].pop_back())
	_camp_rejected(func(f: Dictionary) -> void: f["world"]["camp"]["lean_to"][0] = [1])
	_camp_rejected(func(f: Dictionary) -> void: f["world"]["camp"]["fire"] = "x")
	_camp_rejected(func(f: Dictionary) -> void: f["world"]["camp"]["fire"]["lit"] = 1)
	_camp_rejected(func(f: Dictionary) -> void: f["world"]["camp"]["fire"]["x"] = 1.5)
	_camp_rejected(func(f: Dictionary) -> void: f["world"]["camp"]["fire"]["out_at"] = "1860")
