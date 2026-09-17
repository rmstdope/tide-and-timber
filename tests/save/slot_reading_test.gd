extends GdUnitTestSuite
## Opening one slot: none, ready (after migrating), newer, or broken. Never writes.

const ROOT := "user://test_saves"
const DIR := "user://test_saves/reading"

func after_test() -> void:
	_rm(ROOT)

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

func _sample() -> SaveData:
	var d := SaveData.new()
	var slots: Array[Dictionary] = [{"kind": Item.Kind.DRIFTWOOD, "count": 3}, {}, {}, {}, {}, {}, {}, {}]
	d.inventory_slots = slots
	var none: Array[Vector2i] = []
	d.taken = {"driftwood": none, "shellfish": none.duplicate()}
	d.player_position = Vector2(400, 200)
	d.player_facing = Walk.Facing.LEFT
	d.clock_minutes = 4680.0
	return d

func _write(stem: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(DIR.path_join(stem + ".json"), FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _write_meta(meta: Dictionary) -> void:
	_write("meta", JSON.stringify(meta))

func _files_text() -> Dictionary:
	var out := {}
	for name in DirAccess.get_files_at(DIR):
		out[name] = FileAccess.get_file_as_string(DIR.path_join(name))
	return out

static func _looking_to_facing(f: Dictionary) -> Variant:
	f.player["facing"] = f.player["looking"]
	f.player.erase("looking")
	return f

func _older_steps() -> Dictionary[int, Callable]:
	var steps: Dictionary[int, Callable] = {0: _looking_to_facing}
	return steps

func _make_older() -> void:
	SaveStore.save_slot(_sample(), DIR)
	var player: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join("player.json")))
	player["looking"] = player["facing"]
	player.erase("facing")
	_write("player", JSON.stringify(player))
	_write_meta({"version": 0, "game_version": "0.0"})

func _assert_broken(reading: SlotReading) -> void:
	assert_int(reading.state).is_equal(SlotReading.State.BROKEN)
	assert_object(reading.data).is_null()

func test_no_folder_is_none() -> void:
	var reading := SlotReading.open(DIR)
	assert_int(reading.state).is_equal(SlotReading.State.NONE)
	assert_object(reading.data).is_null()

func test_current_save_is_ready() -> void:
	SaveStore.save_slot(_sample(), DIR)
	var reading := SlotReading.open(DIR)
	assert_int(reading.state).is_equal(SlotReading.State.READY)
	assert_vector(reading.data.player_position).is_equal(_sample().player_position)
	assert_float(reading.data.clock_minutes).is_equal(_sample().clock_minutes)

func test_older_save_migrates_and_is_ready() -> void:
	_make_older()
	var reading := SlotReading.open(DIR, _older_steps())
	assert_int(reading.state).is_equal(SlotReading.State.READY)
	assert_int(reading.data.player_facing).is_equal(_sample().player_facing)

func test_older_save_unmigrated_is_broken() -> void:
	_make_older()
	var steps: Dictionary[int, Callable] = {0: func(f: Dictionary) -> Variant: return f}
	_assert_broken(SlotReading.open(DIR, steps))

func test_opening_never_writes() -> void:
	_make_older()
	var before := _files_text()
	SlotReading.open(DIR, _older_steps())
	assert_dict(_files_text()).is_equal(before)

func test_older_save_with_no_step_is_broken() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_write_meta({"version": 0})
	_assert_broken(SlotReading.open(DIR))

func test_refusing_step_is_broken() -> void:
	_make_older()
	var steps: Dictionary[int, Callable] = {0: func(_f: Dictionary) -> Variant: return null}
	_assert_broken(SlotReading.open(DIR, steps))

func test_newer_save_is_newer_whatever_its_game_version() -> void:
	SaveStore.save_slot(_sample(), DIR)
	for meta: Dictionary in [{"version": 2, "game_version": "0.4"}, {"version": 2}, {"version": 2, "game_version": ""},
			{"version": 2, "game_version": 4}, {"version": 999, "game_version": "1.2.3-beta+4567-and-much-longer"}]:
		_write_meta(meta)
		var reading := SlotReading.open(DIR)
		assert_int(reading.state).override_failure_message("meta %s" % meta).is_equal(SlotReading.State.NEWER)
		assert_object(reading.data).is_null()

func test_unparsable_meta_is_broken() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_write("meta", "{oops")
	_assert_broken(SlotReading.open(DIR))

func test_bad_version_is_broken() -> void:
	SaveStore.save_slot(_sample(), DIR)
	for meta: Dictionary in [{"version": "1"}, {"version": 1.5}]:
		_write_meta(meta)
		_assert_broken(SlotReading.open(DIR))

func test_damaged_file_is_broken() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_write("player", "{oops")
	_assert_broken(SlotReading.open(DIR))

func test_beach_refused_is_broken() -> void:
	var data := _sample()
	var bad: Array[Vector2i] = [Vector2i(0, 0)]
	data.taken = {"driftwood": bad}
	SaveStore.save_slot(data, DIR)
	_assert_broken(SlotReading.open(DIR))
