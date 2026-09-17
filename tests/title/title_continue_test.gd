extends GdUnitTestSuite
## The title screen with a save on disk: Continue, the start-over box, and a dimmed Continue with its replace box.

const SCENE := "res://src/title/title_screen.tscn"
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title"

var runner: GdUnitSceneRunner
var screen: TitleScreen
var calls: Array[String] = []

func after_test() -> void:
	_rm(ROOT)
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

func _open(dir: String, steps: Dictionary[int, Callable] = SaveMigrations.chain()) -> void:
	InputDevice.reset()
	calls = []
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	var recorded := calls
	screen.quit_game = func() -> void: recorded.append("quit")
	screen.start_new_game = func() -> void: recorded.append("new_game")
	screen.start_continue = func() -> void: recorded.append("continue")
	screen.migration_steps = steps
	screen.read_save(dir)

static func _looking_to_facing(f: Dictionary) -> Variant:
	f.player["facing"] = f.player["looking"]
	f.player.erase("looking")
	return f

func _make_older() -> void:
	SaveStore.save_slot(_sample(), DIR)
	var player: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join("player.json")))
	player["looking"] = player["facing"]
	player.erase("facing")
	var f := FileAccess.open(DIR.path_join("player.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(player))
	f.close()
	_write_meta(JSON.stringify({"version": 0, "game_version": "0.0"}))

func _open_older() -> void:
	_make_older()
	var steps: Dictionary[int, Callable] = {0: _looking_to_facing}
	_open(DIR, steps)

func _saved() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_open(DIR)

func _newer() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_write_meta(JSON.stringify({"version": 2, "game_version": "0.4"}))
	_open(DIR)

func _broken() -> void:
	_write_meta(JSON.stringify({"version": 1}))
	_open(DIR)

func _node(path: String) -> Node:
	return screen.get_node(path)

func _plank(unique: String) -> PanelContainer:
	return screen.get_node("%" + unique) as PanelContainer

func assert_highlighted(unique: String) -> void:
	for plank: String in ["Continue", "NewGame", "Settings", "Quit"]:
		var want := TitleScreen.PLANK_HIGHLIGHT_STYLE if plank == unique else TitleScreen.PLANK_STYLE
		assert_object(_plank(plank).get_theme_stylebox("panel")) \
			.override_failure_message("%s should%s be highlighted" % [plank, "" if plank == unique else " not"]) \
			.is_same(want)

func _box_highlighted(unique: String) -> void:
	var buttons := ["KeepMyIsland", "StartOver"] if unique in ["KeepMyIsland", "StartOver"] else ["Cancel", "ReplaceStartOver"]
	for button: String in buttons:   # only the open box's buttons: both Start over buttons share one BoxButton
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

func _open_replace_box() -> void:
	_newer()
	await _press(KEY_ENTER)

func test_save_shows_continue_with_the_day() -> void:
	_saved()
	assert_bool(_visible("%Continue")).is_true()
	assert_str(_text("Menu/Continue/Lines/Label")).is_equal("Continue")
	assert_bool(_visible("%DayLine")).is_true()
	assert_str(_text("%DayLine")).is_equal("DAY 4")
	assert_highlighted("Continue")
	assert_float((_node("%Menu") as Control).position.y).is_equal(83.0)

func test_menu_fits_with_a_save() -> void:
	_saved()
	await await_idle_frame()
	var menu := (_node("%Menu") as Control).get_global_rect()
	assert_bool(Rect2(0, 0, 320, 180).encloses(menu)).override_failure_message("menu at %s" % menu).is_true()
	assert_bool(menu.intersects((_node("%Version") as Control).get_global_rect())).is_false()
	for path in ["Menu/Continue/Lines/Label", "%DayLine"]:
		var label := _node(path) as Label
		assert_float(label.get_minimum_size().x).is_less_equal(label.size.x)

func test_wraps_over_four() -> void:
	_saved()
	await _press(KEY_UP)
	assert_highlighted("Quit")
	await _press(KEY_DOWN)
	assert_highlighted("Continue")
	await _press(KEY_DOWN)
	assert_highlighted("NewGame")
	await _press(KEY_DOWN)
	assert_highlighted("Settings")

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
	assert_bool(_visible("%ReplaceBox")).is_false()
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
	_move_over(_plank("StartOver"))
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

func test_box_words_fit() -> void:
	_saved()
	await await_idle_frame()
	var view := Rect2(0, 0, 320, 180)
	for box in ["StartOverBox", "ReplaceBox"]:
		var panel := _node(box) as Control
		assert_bool(view.encloses(panel.get_global_rect())).is_true()
		var first := _node(box + "/FirstLine") as Label
		assert_float(first.get_minimum_size().x).override_failure_message("%s FirstLine too wide" % box).is_less_equal(first.size.x)
		assert_int((_node(box + "/SecondLine") as Label).get_line_count()).is_less_equal(3)
	for path in ["StartOverBox/KeepMyIsland/Label", "StartOverBox/StartOver/Label", "ReplaceBox/Cancel/Label", "ReplaceBox/ReplaceStartOver/Label"]:
		var label := _node(path) as Label
		assert_float(label.get_minimum_size().x).override_failure_message("%s too wide" % path).is_less_equal(label.size.x)

func test_older_save_looks_like_any_save() -> void:
	_open_older()
	assert_bool(_visible("%Continue")).is_true()
	assert_highlighted("Continue")
	assert_str(_text("%DayLine")).is_equal("DAY 4")
	for box in ["%Dim", "%StartOverBox", "%ReplaceBox", "%Reason"]:
		assert_bool(_visible(box)).is_false()

func test_older_save_continues_with_nothing_said() -> void:
	_open_older()
	var meta := FileAccess.get_file_as_string(DIR.path_join("meta.json"))
	await _press(KEY_ENTER)
	for box in ["%Dim", "%StartOverBox", "%ReplaceBox", "%Reason"]:
		assert_bool(_visible(box)).is_false()
	await await_millis(1300)
	assert_array(calls).is_equal(["continue"])
	var game: Waking = auto_free(screen.make_continued_game())
	assert_int(game.resume_data.player_facing).is_equal(Walk.Facing.LEFT)
	assert_float(game.resume_data.clock_minutes).is_equal(4680.0)
	assert_array(game.resume_data.lean_to_cells).is_empty()
	assert_bool(game.resume_data.has_fire).is_false()
	assert_str(FileAccess.get_file_as_string(DIR.path_join("meta.json"))).is_equal(meta)

func _assert_dimmed() -> void:
	assert_bool(_visible("%Continue")).is_true()
	assert_object(_plank("Continue").get_theme_stylebox("panel")).is_same(TitleScreen.PLANK_DIMMED_STYLE)
	assert_object((_node("Menu/Continue/Lines/Label") as Label).get_theme_color("font_color")).is_equal(TitleScreen.LABEL_DIMMED_COLOR)
	assert_bool(_visible("%DayLine")).is_false()
	for plank: String in ["NewGame", "Quit"]:
		var want := TitleScreen.PLANK_HIGHLIGHT_STYLE if plank == "NewGame" else TitleScreen.PLANK_STYLE
		assert_object(_plank(plank).get_theme_stylebox("panel")).override_failure_message(plank).is_same(want)

func test_newer_save_dims_continue_with_its_reason() -> void:
	_newer()
	_assert_dimmed()
	assert_bool(_visible("%Reason")).is_true()
	assert_str(_text("%Reason")).is_equal("Save is from a newer version")
	assert_float((_node("%Menu") as Control).position.y).is_equal(75.0)

func test_broken_save_dims_continue_with_its_reason() -> void:
	_broken()
	_assert_dimmed()
	assert_bool(_visible("%Reason")).is_true()
	assert_str(_text("%Reason")).is_equal("This save couldn't be opened")

func test_beach_refused_save_is_broken() -> void:
	var data := _sample()
	var bad: Array[Vector2i] = [Vector2i(0, 0)]
	data.taken = {"driftwood": bad}
	SaveStore.save_slot(data, DIR)
	_open(DIR)
	_assert_dimmed()
	assert_str(_text("%Reason")).is_equal("This save couldn't be opened")

func test_readable_save_has_no_reason() -> void:
	_saved()
	assert_bool(_visible("%Reason")).is_false()
	assert_highlighted("Continue")
	assert_object((_node("Menu/Continue/Lines/Label") as Label).get_theme_color("font_color")).is_equal(TitleScreen.LABEL_COLOR)
	assert_float((_node("%Menu") as Control).position.y).is_equal(83.0)

func test_no_save_has_no_reason() -> void:
	_open("user://test_saves/none")
	assert_bool(_visible("%Reason")).is_false()
	assert_bool(_visible("%Continue")).is_false()
	assert_float((_node("%Menu") as Control).position.y).is_equal(97.0)

func test_dimmed_menu_fits() -> void:
	_newer()
	await await_idle_frame()
	var view := Rect2(0, 0, 320, 180)
	var version := (_node("%Version") as Control).get_global_rect()
	for plank: String in ["Continue", "NewGame", "Settings", "Quit"]:
		var rect := _plank(plank).get_global_rect()
		assert_float(rect.size.x).override_failure_message("%s width" % plank).is_equal(90.0)
		assert_float(rect.position.x).override_failure_message("%s x" % plank).is_equal(115.0)
		assert_bool(view.encloses(rect)).override_failure_message("%s at %s" % [plank, rect]).is_true()
		assert_bool(rect.intersects(version)).is_false()
	var reason := _node("%Reason") as Label
	assert_float(reason.get_minimum_size().x).is_less_equal(reason.size.x)
	var r := reason.get_global_rect()
	assert_float(_plank("Continue").get_global_rect().end.y).is_less_equal(r.position.y)
	assert_float(r.end.y).is_less_equal(_plank("NewGame").get_global_rect().position.y)
	assert_bool(r.intersects(version)).is_false()

func test_keys_skip_dimmed_continue() -> void:
	_newer()
	await _press(KEY_UP)
	_assert_menu_highlight("Quit")
	await _press(KEY_UP)
	_assert_menu_highlight("Settings")
	await _press(KEY_DOWN)
	_assert_menu_highlight("Quit")
	await _press(KEY_DOWN)
	_assert_menu_highlight("NewGame")
	runner.simulate_action_pressed("menu_up")
	await runner.await_input_processed()
	_assert_menu_highlight("Quit")

func _assert_menu_highlight(unique: String) -> void:
	for plank: String in ["NewGame", "Quit"]:
		var want := TitleScreen.PLANK_HIGHLIGHT_STYLE if plank == unique else TitleScreen.PLANK_STYLE
		assert_object(_plank(plank).get_theme_stylebox("panel")).override_failure_message(plank).is_same(want)
	assert_object(_plank("Continue").get_theme_stylebox("panel")).is_same(TitleScreen.PLANK_DIMMED_STYLE)

func test_mouse_on_dimmed_continue_does_nothing() -> void:
	_newer()
	_move_over(_plank("Continue"))
	_assert_menu_highlight("NewGame")
	_click("Continue", MOUSE_BUTTON_LEFT)
	assert_array(calls).is_empty()
	assert_float(_fade_alpha()).is_equal(0.0)
	for box in ["%Dim", "%StartOverBox", "%ReplaceBox"]:
		assert_bool(_visible(box)).is_false()
	_assert_menu_highlight("NewGame")

func test_new_game_over_unreadable_save_asks_to_replace() -> void:
	await _open_replace_box()
	assert_bool(_visible("%Dim")).is_true()
	assert_bool(_visible("%ReplaceBox")).is_true()
	assert_bool(_visible("%StartOverBox")).is_false()
	assert_str(_text("ReplaceBox/FirstLine")).is_equal("Start a new game?")
	assert_str(_text("ReplaceBox/SecondLine")).is_equal("Your saved island will be replaced, even though this version can't open it.")
	assert_str(_text("ReplaceBox/Cancel/Label")).is_equal("Cancel")
	assert_str(_text("ReplaceBox/ReplaceStartOver/Label")).is_equal("Start over")
	_box_highlighted("Cancel")
	assert_array(calls).is_empty()

func test_replace_box_highlight_moves() -> void:
	await _open_replace_box()
	await _press(KEY_RIGHT)
	_box_highlighted("ReplaceStartOver")
	await _press(KEY_LEFT)
	_box_highlighted("Cancel")
	_move_over(_plank("ReplaceStartOver"))
	_box_highlighted("ReplaceStartOver")

func _assert_replace_cancelled() -> void:
	assert_bool(_visible("%ReplaceBox")).is_false()
	assert_bool(_visible("%Dim")).is_false()
	_assert_menu_highlight("NewGame")
	assert_array(calls).is_empty()
	assert_str(FileAccess.get_file_as_string(DIR.path_join("meta.json"))).is_equal(JSON.stringify({"version": 2, "game_version": "0.4"}))

func test_cancel_by_enter() -> void:
	await _open_replace_box()
	await _press(KEY_ENTER)
	_assert_replace_cancelled()

func test_cancel_by_escape() -> void:
	await _open_replace_box()
	await _press(KEY_ESCAPE)
	_assert_replace_cancelled()

func test_cancel_by_click() -> void:
	await _open_replace_box()
	_click("Cancel", MOUSE_BUTTON_LEFT)
	_assert_replace_cancelled()

func test_cancel_by_b() -> void:
	await _open_replace_box()
	await _press(KEY_RIGHT)
	runner.simulate_action_pressed("menu_cancel")
	await runner.await_input_processed()
	_assert_replace_cancelled()

func test_start_over_replaces_by_starting_a_new_game() -> void:
	await _open_replace_box()
	var meta := FileAccess.get_file_as_string(DIR.path_join("meta.json"))
	await _press(KEY_RIGHT)
	await _press(KEY_ENTER)
	assert_bool(_visible("%ReplaceBox")).is_false()
	assert_bool(screen.menu.locked).is_true()
	await await_millis(1300)
	assert_array(calls).is_equal(["new_game"])
	assert_str(FileAccess.get_file_as_string(DIR.path_join("meta.json"))).is_equal(meta)

func test_replace_box_words_fit() -> void:
	_newer()
	await await_idle_frame()
	for path in ["ReplaceBox/FirstLine", "ReplaceBox/Cancel/Label", "ReplaceBox/ReplaceStartOver/Label"]:
		var label := _node(path) as Label
		assert_float(label.get_minimum_size().x).override_failure_message("%s too wide" % path).is_less_equal(label.size.x)
	var second := _node("ReplaceBox/SecondLine") as Label
	assert_int(second.get_line_count()).is_less_equal(3)
	assert_float(float(second.get_line_count() * second.get_line_height())).is_less_equal(second.size.y)
	assert_float(second.get_global_rect().end.y).is_less_equal(_plank("Cancel").get_global_rect().position.y)
	assert_bool(Rect2(0, 0, 320, 180).encloses((_node("%ReplaceBox") as Control).get_global_rect())).is_true()

func test_readable_save_new_game_box_unchanged() -> void:
	await _open_start_over_box()
	assert_bool(_visible("%StartOverBox")).is_true()
	assert_bool(_visible("%ReplaceBox")).is_false()

# A mouse movement straight to a control, as Godot delivers one over it.
func _move_over(control: Control, relative := Vector2(1, 0)) -> void:
	var move := InputEventMouseMotion.new()
	move.relative = relative
	control.gui_input.emit(move)

func test_resting_pointer_does_not_move_the_box_highlight() -> void:
	await _open_start_over_box()
	_plank("StartOver").mouse_entered.emit()
	_box_highlighted("KeepMyIsland")

func test_start_over_box_shows_select_and_back() -> void:
	await _open_start_over_box()
	assert_str(screen.strip.text()).is_equal("[Enter] Select   [Esc] Back")
	await _press(KEY_ESCAPE)
	assert_str(screen.strip.text()).is_equal("[Enter] Select")

func test_replace_box_shows_select_and_back() -> void:
	await _open_replace_box()
	assert_str(screen.strip.text()).is_equal("[Enter] Select   [Esc] Back")
