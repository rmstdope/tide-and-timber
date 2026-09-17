extends GdUnitTestSuite
## The title screen with a save on disk: Continue, the start-over box and the cannot-open box.

const SCENE := "res://src/title/title_screen.tscn"
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title"

var runner: GdUnitSceneRunner
var screen: TitleScreen
var calls: Array[String] = []

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
	d.clock_minutes = 4680.0   # DAY 4 06:00
	return d

func _write_meta(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(DIR.path_join("meta.json"), FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _open(dir: String) -> void:
	calls = []
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	var recorded := calls
	screen.quit_game = func() -> void: recorded.append("quit")
	screen.start_new_game = func() -> void: recorded.append("new_game")
	screen.start_continue = func() -> void: recorded.append("continue")
	screen.read_save(dir)

func _saved() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_open(DIR)

func _unopenable() -> void:
	_write_meta('{"version": 1}')
	_open(DIR)

func _node(path: String) -> Node:
	return screen.get_node(path)

func _plank(unique: String) -> PanelContainer:
	return screen.get_node("%" + unique) as PanelContainer

func assert_highlighted(unique: String) -> void:
	for plank: String in ["Continue", "NewGame", "Quit"]:
		var want := TitleScreen.PLANK_HIGHLIGHT_STYLE if plank == unique else TitleScreen.PLANK_STYLE
		assert_object(_plank(plank).get_theme_stylebox("panel")) \
			.override_failure_message("%s should%s be highlighted" % [plank, "" if plank == unique else " not"]) \
			.is_same(want)

func _box_highlighted(unique: String) -> void:
	for button: String in ["KeepMyIsland", "StartOver", "Ok"]:
		var want := TitleScreen.PLANK_HIGHLIGHT_STYLE if button == unique else TitleScreen.PLANK_STYLE
		assert_object(_plank(button).get_theme_stylebox("panel")) \
			.override_failure_message("%s should%s be highlighted" % [button, "" if button == unique else " not"]) \
			.is_same(want)

func _fade_alpha() -> float:
	return (screen.get_node("%Fade") as CanvasItem).modulate.a

func _visible(path: String) -> bool:
	return (_node(path) as CanvasItem).visible

func _text(path: String) -> String:
	return (_node(path) as Label).text

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _click(unique: String, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	_plank(unique).gui_input.emit(event)

func _open_start_over_box() -> void:
	_saved()
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)

func _open_cannot_open_box() -> void:
	_unopenable()
	await _press(KEY_ENTER)

func test_save_shows_continue_with_the_day() -> void:
	_saved()
	assert_bool(_visible("%Continue")).is_true()
	assert_str(_text("Menu/Continue/Lines/Label")).is_equal("Continue")
	assert_bool(_visible("%DayLine")).is_true()
	assert_str(_text("%DayLine")).is_equal("DAY 4")
	assert_highlighted("Continue")
	assert_float((_node("%Menu") as Control).position.y).is_equal(104.0)

func test_menu_fits_with_a_save() -> void:
	_saved()
	await await_idle_frame()
	var menu := (_node("%Menu") as Control).get_global_rect()
	assert_bool(Rect2(0, 0, 320, 180).encloses(menu)).override_failure_message("menu at %s" % menu).is_true()
	assert_bool(menu.intersects((_node("%Version") as Control).get_global_rect())).is_false()
	for path in ["Menu/Continue/Lines/Label", "%DayLine"]:
		var label := _node(path) as Label
		assert_float(label.get_minimum_size().x).is_less_equal(label.size.x)

func test_wraps_over_three() -> void:
	_saved()
	await _press(KEY_UP)
	assert_highlighted("Quit")
	await _press(KEY_DOWN)
	assert_highlighted("Continue")
	await _press(KEY_DOWN)
	assert_highlighted("NewGame")

func test_continue_fades_then_continues() -> void:
	_saved()
	await _press(KEY_ENTER)
	assert_array(calls).is_empty()
	assert_bool(screen.menu.locked).is_true()
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)
	_click("Quit", MOUSE_BUTTON_LEFT)
	await await_millis(1300)
	assert_array(calls).is_equal(["continue"])
	assert_float(_fade_alpha()).is_equal(1.0)

func test_continued_game_carries_the_save() -> void:
	_saved()
	var game: Node = auto_free(screen.make_continued_game())
	assert_object(game).is_instanceof(Waking)
	assert_float((game as Waking).resume_data.clock_minutes).is_equal(4680.0)
	assert_vector((game as Waking).resume_data.player_position).is_equal(Vector2(400, 200))

func test_new_game_asks_first() -> void:
	await _open_start_over_box()
	assert_bool(_visible("%Dim")).is_true()
	assert_bool(_visible("%StartOverBox")).is_true()
	assert_bool(_visible("%CannotOpenBox")).is_false()
	assert_str(_text("StartOverBox/FirstLine")).is_equal("Wash up on a new island?")
	assert_str(_text("StartOverBox/SecondLine")).is_equal("Everything you built will be lost to the sea.")
	assert_str(_text("StartOverBox/KeepMyIsland/Label")).is_equal("Keep my island")
	assert_str(_text("StartOverBox/StartOver/Label")).is_equal("Start over")
	_box_highlighted("KeepMyIsland")
	assert_array(calls).is_empty()
	assert_float(_fade_alpha()).is_equal(0.0)

func test_box_highlight_moves() -> void:
	await _open_start_over_box()
	await _press(KEY_RIGHT)
	_box_highlighted("StartOver")
	await _press(KEY_LEFT)
	_box_highlighted("KeepMyIsland")
	_plank("StartOver").mouse_entered.emit()
	_box_highlighted("StartOver")
	await _press(KEY_UP)
	_box_highlighted("StartOver")
	assert_highlighted("NewGame")

func _assert_start_over_kept() -> void:
	assert_bool(_visible("%StartOverBox")).is_false()
	assert_bool(_visible("%Dim")).is_false()
	assert_highlighted("NewGame")
	assert_array(calls).is_empty()
	assert_bool(SaveStore.exists(DIR)).is_true()

func test_keep_my_island_by_enter() -> void:
	await _open_start_over_box()
	await _press(KEY_ENTER)
	_assert_start_over_kept()

func test_keep_my_island_by_escape() -> void:
	await _open_start_over_box()
	await _press(KEY_ESCAPE)
	_assert_start_over_kept()

func test_keep_my_island_by_click() -> void:
	await _open_start_over_box()
	_click("KeepMyIsland", MOUSE_BUTTON_LEFT)
	_assert_start_over_kept()

func test_keep_my_island_by_b() -> void:
	await _open_start_over_box()
	await _press(KEY_RIGHT)
	runner.simulate_action_pressed("menu_cancel")
	await runner.await_input_processed()
	_assert_start_over_kept()

func test_start_over_fades_to_a_new_game_and_keeps_the_save() -> void:
	await _open_start_over_box()
	await _press(KEY_RIGHT)
	await _press(KEY_ENTER)
	assert_bool(_visible("%StartOverBox")).is_false()
	assert_bool(screen.menu.locked).is_true()
	await await_millis(1300)
	assert_array(calls).is_equal(["new_game"])
	assert_bool(SaveStore.exists(DIR)).is_true()
	assert_float(SaveStore.load_slot(DIR).clock_minutes).is_equal(4680.0)

func test_click_outside_the_box_does_nothing() -> void:
	await _open_start_over_box()
	runner.simulate_mouse_move(Vector2(10, 10))
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()
	assert_bool(_visible("%StartOverBox")).is_true()
	assert_array(calls).is_empty()

func test_unopenable_save_still_offers_continue() -> void:
	_unopenable()
	assert_bool(_visible("%Continue")).is_true()
	assert_highlighted("Continue")
	assert_bool(_visible("%DayLine")).is_false()

func test_newer_save_shows_its_day() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_write_meta('{"version": 999}')
	_open(DIR)
	assert_highlighted("Continue")
	assert_bool(_visible("%DayLine")).is_true()
	assert_str(_text("%DayLine")).is_equal("DAY 4")

func test_beach_refused_save_cannot_open() -> void:
	var data := _sample()
	var bad: Array[Vector2i] = [Vector2i(0, 0)]
	data.taken = {"driftwood": bad}
	SaveStore.save_slot(data, DIR)
	_open(DIR)
	await _press(KEY_ENTER)
	assert_bool(_visible("%CannotOpenBox")).is_true()
	assert_array(calls).is_empty()

func _assert_cannot_open_closed(meta: String) -> void:
	assert_bool(_visible("%CannotOpenBox")).is_false()
	assert_bool(_visible("%Dim")).is_false()
	assert_highlighted("NewGame")
	assert_bool(_visible("%Continue")).is_true()
	assert_array(calls).is_empty()
	assert_str(FileAccess.get_file_as_string(DIR.path_join("meta.json"))).is_equal(meta)
	assert_array(Array(DirAccess.get_files_at(DIR))).is_equal(["meta.json"])

func test_continue_on_an_unopenable_save_explains() -> void:
	await _open_cannot_open_box()
	var meta := FileAccess.get_file_as_string(DIR.path_join("meta.json"))
	assert_bool(_visible("%Dim")).is_true()
	assert_bool(_visible("%CannotOpenBox")).is_true()
	assert_bool(_visible("%StartOverBox")).is_false()
	assert_str(_text("CannotOpenBox/FirstLine")).is_equal("The tide has blurred this journal.")
	assert_str(_text("CannotOpenBox/SecondLine")).is_equal("Your saved island couldn't be opened.")
	assert_str(_text("CannotOpenBox/Ok/Label")).is_equal("OK")
	_box_highlighted("Ok")
	assert_float(_fade_alpha()).is_equal(0.0)
	assert_array(calls).is_empty()
	await _press(KEY_ENTER)
	_assert_cannot_open_closed(meta)

func test_cannot_open_box_closes_by_escape() -> void:
	await _open_cannot_open_box()
	await _press(KEY_ESCAPE)
	_assert_cannot_open_closed('{"version": 1}')

func test_cannot_open_box_closes_by_click() -> void:
	await _open_cannot_open_box()
	_click("Ok", MOUSE_BUTTON_LEFT)
	_assert_cannot_open_closed('{"version": 1}')

func test_cannot_open_box_closes_by_b() -> void:
	await _open_cannot_open_box()
	runner.simulate_action_pressed("menu_cancel")
	await runner.await_input_processed()
	_assert_cannot_open_closed('{"version": 1}')

func test_new_game_after_cannot_open_asks_first() -> void:
	await _open_cannot_open_box()
	await _press(KEY_ENTER)
	await _press(KEY_ENTER)
	assert_bool(_visible("%StartOverBox")).is_true()

func test_box_words_fit() -> void:
	_saved()
	await await_idle_frame()
	var view := Rect2(0, 0, 320, 180)
	for box in ["StartOverBox", "CannotOpenBox"]:
		var panel := _node(box) as Control
		assert_bool(view.encloses(panel.get_global_rect())).is_true()
		var first := _node(box + "/FirstLine") as Label
		assert_float(first.get_minimum_size().x).override_failure_message("%s FirstLine too wide" % box).is_less_equal(first.size.x)
		assert_int((_node(box + "/SecondLine") as Label).get_line_count()).is_less_equal(2)
	for path in ["StartOverBox/KeepMyIsland/Label", "StartOverBox/StartOver/Label", "CannotOpenBox/Ok/Label"]:
		var label := _node(path) as Label
		assert_float(label.get_minimum_size().x).override_failure_message("%s too wide" % path).is_less_equal(label.size.x)
