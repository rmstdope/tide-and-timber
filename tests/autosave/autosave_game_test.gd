extends GdUnitTestSuite
## The real save at dawn, into a test folder.

const DIR := "user://test_saves/autosave"

var runner: GdUnitSceneRunner
var beach: Beach
var dn: DayNight
var autosave: Autosave

func before_test() -> void:
	InputDevice.reset()
	runner = scene_runner("res://src/beach/beach.tscn")
	beach = runner.scene() as Beach
	dn = load("res://src/day_night/day_night.tscn").instantiate()
	beach.add_child(dn)
	autosave = load("res://src/autosave/autosave.tscn").instantiate()
	autosave.slot_dir = DIR
	beach.add_child(autosave)
	autosave.watch(beach, dn)
	dn.start()
	dn.set_process(false)
	autosave.set_process(false)

func after_test() -> void:
	autosave.get_tree().paused = false
	_rm("user://test_saves")
	InputDevice.reset()

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

func _n(unique: String) -> Node:
	return autosave.get_node("%" + unique)

func test_nothing_saved_on_day_1() -> void:
	dn.tick(1529.0)
	assert_bool(SaveStore.exists(DIR)).is_false()
	assert_bool(_n("Dawn").visible).is_false()

func test_saved_at_day_2_dawn() -> void:
	beach.inventory.add(Item.Kind.DRIFTWOOD, 3)
	beach.get_node("%Player").global_position = Vector2(400, 200)
	dn.tick(1531.0)
	assert_bool(SaveStore.exists(DIR)).is_true()
	var data := SaveStore.load_slot(DIR)
	assert_object(data).is_not_null()
	assert_float(data.clock_minutes).is_equal(1800.0)
	assert_vector(data.player_position).is_equal(Vector2(400, 200))
	assert_dict(data.inventory_slots[0]).is_equal({"kind": Item.Kind.DRIFTWOOD, "count": 3})
	autosave.tick(0.5)
	assert_bool(_n("Dawn").visible).is_true()

func test_unwritable_folder_opens_the_box() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var f := FileAccess.open("user://test_saves/blocked", FileAccess.WRITE)
	f.store_string("x")
	f.close()
	autosave.slot_dir = "user://test_saves/blocked/slot"
	dn.tick(1531.0)
	assert_bool(_n("Box").visible).is_true()
	assert_bool(autosave.get_tree().paused).is_true()

func _pad(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = button
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func _mouse_moved() -> void:
	var move := InputEventMouseMotion.new()
	move.position = Vector2(300, 20)
	move.relative = Vector2(2, 0)
	Input.parse_input_event(move)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func _tap(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_box_over_play_and_the_build_hint_show_the_same_device() -> void:
	var hint := beach.get_node("%KeyHint") as KeyHint
	hint.show_hint(DeviceHints.Hint.BUILD_LIST)
	autosave.save_game = func() -> Error: return ERR_FILE_CANT_WRITE
	autosave.on_dawn()
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	assert_str(autosave.strip.text()).is_equal("(A) Select   (B) Back")
	assert_str(hint.text()).is_equal("(A) Build   (B) Close")
	await _mouse_moved()
	assert_str(autosave.strip.text()).is_equal("(A) Select   (B) Back")
	assert_str(hint.text()).is_equal("(A) Build   (B) Close")
	await _tap(KEY_RIGHT)
	assert_str(autosave.strip.text()).is_equal("[Enter] Select   [Esc] Back")
	assert_str(hint.text()).is_equal("[E] Build   [Esc] Close")
