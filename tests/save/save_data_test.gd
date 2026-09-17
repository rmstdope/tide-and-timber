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

func test_day_in() -> void:
	assert_int(SaveData.day_in({"clock": {"total_minutes": 4680.0}})).is_equal(4)
	assert_int(SaveData.day_in({})).is_equal(0)
	assert_int(SaveData.day_in({"clock": "x"})).is_equal(0)
	assert_int(SaveData.day_in({"clock": {"total_minutes": "4680"}})).is_equal(0)
	assert_int(SaveData.day_in({"clock": {"total_minutes": -1.0}})).is_equal(0)
