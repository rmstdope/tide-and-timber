extends GdUnitTestSuite
## The title's Start over and Replace boxes at large UI sizes: narrowed, centred, buttons stacked left on top.

const SCENE := "res://src/title/title_screen.tscn"
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title_box_stack"
const EPS := Vector2(0.01, 0.01)

const START_OVER_NORMAL: Array[Rect2] = [Rect2(12, 42, 296, 96), Rect2(8, 8, 280, 12), Rect2(8, 24, 280, 28), Rect2(24, 66, 120, 20), Rect2(152, 66, 120, 20)]
const START_OVER_LARGE: Array[Rect2] = [Rect2(58, 24, 204, 133), Rect2(8, 8, 188, 19), Rect2(8, 31, 188, 30), Rect2(42, 75, 120, 20), Rect2(42, 103, 120, 20)]
const START_OVER_LARGEST: Array[Rect2] = [Rect2(84, 24, 152, 133), Rect2(8, 8, 136, 19), Rect2(8, 31, 136, 30), Rect2(16, 75, 120, 20), Rect2(16, 103, 120, 20)]
const REPLACE_NORMAL: Array[Rect2] = [Rect2(12, 42, 296, 96), Rect2(8, 6, 280, 12), Rect2(8, 20, 280, 42), Rect2(24, 66, 120, 20), Rect2(152, 66, 120, 20)]
const REPLACE_LARGE: Array[Rect2] = [Rect2(58, 28, 204, 124), Rect2(8, 6, 188, 12), Rect2(8, 20, 188, 42), Rect2(42, 66, 120, 20), Rect2(42, 94, 120, 20)]
const REPLACE_LARGEST: Array[Rect2] = [Rect2(84, 18, 152, 145), Rect2(8, 6, 136, 12), Rect2(8, 20, 136, 63), Rect2(16, 87, 120, 20), Rect2(16, 115, 120, 20)]

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var runner: GdUnitSceneRunner
var screen: TitleScreen
var calls: Array[String] = []

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(640, 360)
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	Display.use_prefs(DisplayPrefs.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
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
	d.clock_minutes = 4680.0
	return d

func _write_meta(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(DIR.path_join("meta.json"), FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _open(dir: String) -> void:
	InputDevice.reset()
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

func _newer() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_write_meta(JSON.stringify({"version": 2, "game_version": "0.4"}))
	_open(DIR)

func _plank(unique: String) -> PanelContainer:
	return screen.get_node("%" + unique) as PanelContainer

func _box_highlighted(unique: String) -> void:
	var buttons := ["KeepMyIsland", "StartOver"] if unique in ["KeepMyIsland", "StartOver"] else ["Cancel", "ReplaceStartOver"]
	for button: String in buttons:
		var want := TitleScreen.PLANK_HIGHLIGHT_STYLE if button == unique else TitleScreen.PLANK_STYLE
		assert_object(_plank(button).get_theme_stylebox("panel")) \
			.override_failure_message("%s should%s be highlighted" % [button, "" if button == unique else " not"]) \
			.is_same(want)

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _open_start_over_box() -> void:
	_saved()
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)

func _open_replace_box() -> void:
	_newer()
	await _press(KEY_ENTER)

func _large() -> void:
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)

func _largest() -> void:
	_large()
	_large()

func _control(path: String) -> Control:
	return screen.get_node(path) as Control

func _rect(path: String) -> Rect2:
	var n := _control(path)
	return Rect2(n.position, n.size)

## The box's rest panel: the node now carries the framed rect, so the rest layout is read from the screen.
func _panel_rect(box: String) -> Rect2:
	return screen._start_over_box.panel if box == "StartOver" else screen._replace_box.panel

func _assert_box(box: String, want: Array[Rect2]) -> void:
	var paths: Array[String]
	if box == "StartOver":
		paths = ["StartOverBox/Clip/Content/FirstLine", "StartOverBox/Clip/Content/SecondLine", "%KeepMyIsland", "%StartOver"]
	else:
		paths = ["ReplaceBox/Clip/Content/FirstLine", "ReplaceBox/Clip/Content/SecondLine", "%Cancel", "%ReplaceStartOver"]
	assert_that(_panel_rect(box)).override_failure_message("%s panel is %s, want %s" % [box, _panel_rect(box), want[0]]) \
		.is_equal(want[0])
	for i in paths.size():
		assert_that(_rect(paths[i])).override_failure_message("%s is %s, want %s" % [paths[i], _rect(paths[i]), want[i + 1]]) \
			.is_equal(want[i + 1])

func _move_over(control: Control, relative := Vector2(1, 0)) -> void:
	var move := InputEventMouseMotion.new()
	move.relative = relative
	control.gui_input.emit(move)

func test_normal_is_todays_layout() -> void:
	await _open_start_over_box()
	_assert_box("StartOver", START_OVER_NORMAL)
	assert_vector(_control("%StartOverBox").pivot_offset).is_equal(Vector2(148, 48))
	await _open_replace_box()
	_assert_box("Replace", REPLACE_NORMAL)

func test_start_over_stacks_at_largest() -> void:
	await _open_start_over_box()
	_largest()
	_assert_box("StartOver", START_OVER_LARGEST)
	assert_bool(_control("%StartOverBox").visible).is_true()
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.KEEP_MY_ISLAND)
	_box_highlighted("KeepMyIsland")

func test_start_over_stacks_at_large() -> void:
	await _open_start_over_box()
	_large()
	_assert_box("StartOver", START_OVER_LARGE)

func test_replace_stacks_at_largest() -> void:
	await _open_replace_box()
	_largest()
	_assert_box("Replace", REPLACE_LARGEST)
	_box_highlighted("Cancel")

func test_replace_stacks_at_large() -> void:
	await _open_replace_box()
	_large()
	_assert_box("Replace", REPLACE_LARGE)

func test_stacked_box_stays_centred_on_screen() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame   # the boxes are framed once the strip's own deferred layout has run
	for unique: String in ["%StartOverBox", "%ReplaceBox"]:
		var c := _control(unique)
		assert_vector(c.position + c.pivot_offset).is_equal(Vector2(160, 90))
		assert_vector(c.scale).is_equal(Vector2(2, 2))
		assert_vector(c.get_global_rect().get_center()).is_equal_approx(Vector2(160, 76), EPS)
	Display.use_prefs(DisplayPrefs.new())
	_large()
	await get_tree().process_frame
	var box := _control("%StartOverBox")
	assert_vector(box.pivot_offset).is_equal(Vector2(102, 58))
	assert_vector(box.get_global_rect().get_center()).is_equal_approx(Vector2(160, 79.5), EPS)

func test_stacking_while_up_keeps_the_highlight() -> void:
	await _open_start_over_box()
	await _press(KEY_RIGHT)
	_largest()
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.START_OVER)
	_box_highlighted("StartOver")
	assert_that(_rect("%StartOver")).is_equal(Rect2(16, 103, 120, 20))
	Display.use_prefs(DisplayPrefs.new())
	_assert_box("StartOver", START_OVER_NORMAL)
	assert_vector(_control("%StartOverBox").pivot_offset).is_equal(Vector2(148, 48))
	assert_vector(_control("%StartOverBox").scale).is_equal(Vector2.ONE)
	_box_highlighted("StartOver")

func test_window_resize_refits() -> void:
	await _open_start_over_box()
	_large()
	assert_float(_control("%StartOverBox").size.x).is_equal(204.0)
	get_tree().root.size = Vector2i(320, 180)
	var box := _control("%StartOverBox")
	assert_float(box.size.x).is_equal(152.0)
	assert_vector(box.position + box.pivot_offset).is_equal(Vector2(160, 90))
	get_tree().root.size = Vector2i(640, 360)

func test_a_box_opened_while_stacked_is_already_fitted() -> void:
	_saved()
	_largest()
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)
	_assert_box("StartOver", START_OVER_LARGEST)

func test_stacked_buttons_do_not_overlap() -> void:
	await _open_start_over_box()
	_largest()
	for pair: Array in [["%StartOverBox", "%KeepMyIsland", "%StartOver"], ["%ReplaceBox", "%Cancel", "%ReplaceStartOver"]]:
		var box := _control(pair[0] + "/Clip/Content").get_global_rect()
		var top := _control(pair[1]).get_global_rect()
		var bottom := _control(pair[2]).get_global_rect()
		assert_bool(top.intersects(bottom)).override_failure_message("%s overlaps %s" % [pair[1], pair[2]]).is_false()
		assert_float(top.position.y).is_less(bottom.position.y)
		assert_bool(box.encloses(top)).is_true()
		assert_bool(box.encloses(bottom)).is_true()

func test_up_down_do_nothing_side_by_side() -> void:
	await _open_start_over_box()
	await _press(KEY_DOWN)
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.KEEP_MY_ISLAND)
	await _press(KEY_RIGHT)
	await _press(KEY_UP)
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.START_OVER)
	assert_bool(_control("%StartOverBox").visible).is_true()

func test_select_and_back_unchanged_when_stacked() -> void:
	await _open_start_over_box()
	_largest()
	await _press(KEY_RIGHT)
	await _press(KEY_ENTER)
	assert_bool(screen.menu.locked).is_true()
	assert_bool(_control("%StartOverBox").visible).is_false()
	Display.use_prefs(DisplayPrefs.new())
	await _open_start_over_box()
	_largest()
	await _press(KEY_RIGHT)
	await _press(KEY_ESCAPE)
	assert_bool(_control("%StartOverBox").visible).is_false()
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.KEEP_MY_ISLAND)
	assert_int(screen.menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
	assert_array(calls).is_empty()

func test_hover_still_selects_a_stacked_button() -> void:
	await _open_start_over_box()
	_largest()
	_move_over(_control("%StartOver"))
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.START_OVER)
	_box_highlighted("StartOver")
