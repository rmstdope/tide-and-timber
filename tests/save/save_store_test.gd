extends GdUnitTestSuite

const ROOT := "user://test_saves"
const DIR := "user://test_saves/store"

func _sample() -> SaveData:
	var d := SaveData.new()
	d.player_position = Vector2(400, 200)
	d.player_facing = Walk.Facing.UP
	var slots: Array[Dictionary] = [{"kind": Item.Kind.COCONUT, "count": 2}, {}, {}, {}, {}, {}, {}, {}]
	d.inventory_slots = slots
	var cells: Array[Vector2i] = [Vector2i(1, 2)]
	d.taken = {"driftwood": cells}
	d.clock_minutes = 1800.0
	return d

func _rm(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		return
	if not DirAccess.dir_exists_absolute(path):
		return
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	for d in DirAccess.get_directories_at(path):
		_rm(path.path_join(d))
	DirAccess.remove_absolute(path)

func after_test() -> void:
	_rm(ROOT)

func _assert_same(a: SaveData, b: SaveData) -> void:
	assert_vector(a.player_position).is_equal(b.player_position)
	assert_int(a.player_facing).is_equal(b.player_facing)
	assert_array(a.inventory_slots).is_equal(b.inventory_slots)
	assert_dict(a.taken).is_equal(b.taken)
	assert_float(a.clock_minutes).is_equal(b.clock_minutes)

func test_nothing_saved_means_not_exists() -> void:
	assert_bool(SaveStore.exists(DIR)).is_false()
	assert_object(SaveStore.load_slot(DIR)).is_null()

func test_write_makes_one_small_file_per_stem() -> void:
	assert_int(SaveStore.save_slot(_sample(), DIR)).is_equal(OK)
	var files := Array(DirAccess.get_files_at(DIR))
	files.sort()
	assert_array(files).is_equal(["clock.json", "inventory.json", "meta.json", "player.json", "world.json"])
	assert_bool(SaveStore.exists(DIR)).is_true()

func test_save_then_load_round_trips() -> void:
	SaveStore.save_slot(_sample(), DIR)
	var loaded := SaveStore.load_slot(DIR)
	assert_object(loaded).is_not_null()
	_assert_same(loaded, _sample())

func test_second_save_replaces_the_first() -> void:
	var d := _sample()
	SaveStore.save_slot(d, DIR)
	d.player_position = Vector2(12, 34)
	assert_int(SaveStore.save_slot(d, DIR)).is_equal(OK)
	assert_vector(SaveStore.load_slot(DIR).player_position).is_equal(Vector2(12, 34))

func test_corrupt_file_loads_null() -> void:
	SaveStore.save_slot(_sample(), DIR)
	var f := FileAccess.open(DIR.path_join("player.json"), FileAccess.WRITE)
	f.store_string("{oops")
	f.close()
	assert_object(SaveStore.load_slot(DIR)).is_null()
	assert_bool(SaveStore.read(DIR).has("player")).is_false()

func test_unwritable_dir_returns_error() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var f := FileAccess.open(ROOT.path_join("blocked"), FileAccess.WRITE)
	f.store_string("x")
	f.close()
	assert_int(SaveStore.save_slot(_sample(), ROOT.path_join("blocked/slot"))).is_not_equal(OK)

func test_slot_dir_is_under_saves() -> void:
	assert_str(SaveStore.SLOT_DIR).is_equal("user://saves/slot_1")

func _put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func test_interrupted_replace_recovers_the_new_set() -> void:
	var old := _sample()
	SaveStore.save_slot(old, DIR)
	var new := _sample()
	new.player_position = Vector2(12, 34)
	new.clock_minutes = 3240.0
	var files := new.to_files()
	# the new set was written to .tmp, then the replace loop died after player and inventory
	for stem: String in files:
		_put(DIR.path_join(stem + ".json.tmp"), JSON.stringify(files[stem]))
	for stem in ["player", "inventory"]:
		DirAccess.remove_absolute(DIR.path_join(stem + ".json"))
		DirAccess.rename_absolute(DIR.path_join(stem + ".json.tmp"), DIR.path_join(stem + ".json"))
	DirAccess.remove_absolute(DIR.path_join("world.json"))
	var loaded := SaveStore.load_slot(DIR)
	assert_object(loaded).is_not_null()
	assert_vector(loaded.player_position).is_equal(Vector2(12, 34))
	assert_float(loaded.clock_minutes).is_equal(3240.0)
	assert_bool(SaveStore.exists(DIR)).is_true()

func test_unfinished_tmp_write_keeps_the_old_set() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_put(DIR.path_join("player.json.tmp"), JSON.stringify({"x": 1, "y": 2, "facing": "up"}))
	_put(DIR.path_join("meta.json.tmp"), "{\"vers")
	var loaded := SaveStore.load_slot(DIR)
	assert_object(loaded).is_not_null()
	assert_vector(loaded.player_position).is_equal(Vector2(400, 200))

func test_next_save_after_an_interrupted_one_is_clean() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_put(DIR.path_join("meta.json.tmp"), "{\"vers")
	var d := _sample()
	d.player_position = Vector2(7, 8)
	assert_int(SaveStore.save_slot(d, DIR)).is_equal(OK)
	var files := Array(DirAccess.get_files_at(DIR))
	files.sort()
	assert_array(files).is_equal(["clock.json", "inventory.json", "meta.json", "player.json", "world.json"])
	assert_vector(SaveStore.load_slot(DIR).player_position).is_equal(Vector2(7, 8))

func _write_meta(text: String) -> void:
	var f := FileAccess.open(DIR.path_join("meta.json"), FileAccess.WRITE)
	f.store_string(text)
	f.close()

func test_load_slot_goes_through_the_chain() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_write_meta('{"version": 0}')
	assert_object(SaveStore.load_slot(DIR)).is_null()
	assert_str(FileAccess.get_file_as_string(DIR.path_join("meta.json"))).is_equal('{"version": 0}')
	_write_meta('{"version": 1}')
	assert_object(SaveStore.load_slot(DIR)).is_not_null()
