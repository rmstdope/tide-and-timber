extends GdUnitTestSuite
## The title's Start over and Replace boxes at large UI and Text sizes: narrowed, centred, buttons stacked left on top.
## At 640x360 UI size alone never stacks a box, so the stacked layouts are reached the way a player does, in
## the default 1280x720 window (k = 2): Start over first stacks at UI Large + Text Largest ("large" below) and
## at UI Largest + Text Largest ("largest"); Replace stacks only at UI Largest + Text Largest.
## Every test about a stacked box first asserts that it is stacked, so none can pass on the plain layout.

const SCENE := "res://src/title/title_screen.tscn"
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title_box_stack"
const EPS := Vector2(0.01, 0.01)

## A panel centred on the picture: the boxes' rest panels grow about Screen.CENTRE.
static func _centred(w: float, h: float) -> Rect2:
	return Rect2(Screen.CENTRE - Vector2(w, h) / 2.0, Vector2(w, h))

# Normal: today's layout, the 296x96 panel centred on the picture.
var START_OVER_NORMAL: Array[Rect2] = [_centred(296, 96), Rect2(8, 8, 280, 12), Rect2(8, 24, 280, 28), Rect2(24, 66, 120, 20), Rect2(152, 66, 120, 20)]
# UI Large + Text Largest at k = 2: s = 1.5, the words twice their size, the panel 418x138.
var START_OVER_LARGE: Array[Rect2] = [_centred(418, 138), Rect2(8, 8, 201, 8), Rect2(8, 28, 201, 19), Rect2(95, 80, 228, 20), Rect2(127, 108, 164, 20)]
# UI Largest + Text Largest at k = 2: s = 2, the panel 312x182 at rest.
var START_OVER_LARGEST: Array[Rect2] = [_centred(312, 182), Rect2(8, 8, 148, 19), Rect2(8, 50, 148, 30), Rect2(42, 124, 228, 20), Rect2(74, 152, 164, 20)]
var REPLACE_NORMAL: Array[Rect2] = [_centred(296, 96), Rect2(8, 6, 280, 12), Rect2(8, 20, 280, 42), Rect2(24, 66, 120, 20), Rect2(152, 66, 120, 20)]
# UI Largest + Text Largest at k = 2: the only combination that stacks Replace; the panel 312x190 at rest.
var REPLACE_LARGEST: Array[Rect2] = [_centred(312, 190), Rect2(8, 6, 148, 8), Rect2(8, 24, 148, 52), Rect2(96, 132, 120, 20), Rect2(74, 160, 164, 20)]

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var runner: GdUnitSceneRunner
var screen: TitleScreen
var calls: Array[String] = []

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
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

func _ui(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)

func _text(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)

## UI Large + Text Largest: the smallest combination that stacks Start over.
func _large() -> void:
	_ui(1)
	_text(2)

## UI Largest + Text Largest: the combination that stacks both boxes.
func _largest() -> void:
	_ui(2)
	_text(2)

func _assert_stacked(box: String) -> void:
	var layout: BoxLayout = screen._start_over_box if box == "StartOver" else screen._replace_box
	assert_bool(layout.stacked).override_failure_message("%s should be stacked" % box).is_true()

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
	assert_vector(_control("%StartOverBox").pivot_offset).is_equal(Vector2(296, 96) / 2.0)
	await _open_replace_box()
	_assert_box("Replace", REPLACE_NORMAL)

func test_start_over_stacks_at_largest() -> void:
	await _open_start_over_box()
	_largest()
	_assert_stacked("StartOver")
	_assert_box("StartOver", START_OVER_LARGEST)
	assert_bool(_control("%StartOverBox").visible).is_true()
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.KEEP_MY_ISLAND)
	_box_highlighted("KeepMyIsland")

func test_start_over_stacks_at_large() -> void:
	await _open_start_over_box()
	_large()
	_assert_stacked("StartOver")
	_assert_box("StartOver", START_OVER_LARGE)

func test_replace_stacks_at_largest() -> void:
	await _open_replace_box()
	_largest()
	_assert_stacked("Replace")
	_assert_box("Replace", REPLACE_LARGEST)
	_box_highlighted("Cancel")

## Replace's words are longer than Start over's buttons need: one step short of Largest on either
## setting, it stays side by side, centred.
func test_replace_stacks_at_large() -> void:
	await _open_replace_box()
	_large()
	assert_bool(screen._replace_box.stacked).is_false()
	assert_that(_panel_rect("Replace")).is_equal(_centred(418, 140))
	Display.use_prefs(DisplayPrefs.new())
	_ui(2)
	_text(1)
	assert_bool(screen._replace_box.stacked).is_false()
	assert_that(_panel_rect("Replace")).is_equal(_centred(312, 116))

func test_stacked_box_stays_centred_on_screen() -> void:
	await _open_start_over_box()
	_largest()
	_assert_stacked("StartOver")
	_assert_stacked("Replace")
	await get_tree().process_frame   # the boxes are framed once the strip's own deferred layout has run
	for unique: String in ["%StartOverBox", "%ReplaceBox"]:
		var c := _control(unique)
		assert_vector(c.position + c.pivot_offset).is_equal(Screen.CENTRE)
		assert_vector(c.scale).is_equal(Vector2(2, 2))
		# framed to the room above the strip: 155 tall, top at 91, so centred 23 above the picture's centre
		assert_vector(c.get_global_rect().get_center()).is_equal_approx(Screen.CENTRE - Vector2(0, 23), EPS)
	Display.use_prefs(DisplayPrefs.new())
	_large()
	_assert_stacked("StartOver")
	await get_tree().process_frame
	var box := _control("%StartOverBox")
	assert_vector(box.pivot_offset).is_equal(Vector2(209, 69))
	assert_vector(box.get_global_rect().get_center()).is_equal_approx(Screen.CENTRE, EPS)

func test_stacking_while_up_keeps_the_highlight() -> void:
	await _open_start_over_box()
	await _press(KEY_RIGHT)
	_largest()
	_assert_stacked("StartOver")
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.START_OVER)
	_box_highlighted("StartOver")
	assert_that(_rect("%StartOver")).is_equal(START_OVER_LARGEST[4])
	Display.use_prefs(DisplayPrefs.new())
	_assert_box("StartOver", START_OVER_NORMAL)
	assert_vector(_control("%StartOverBox").pivot_offset).is_equal(Vector2(296, 96) / 2.0)
	assert_vector(_control("%StartOverBox").scale).is_equal(Vector2.ONE)
	_box_highlighted("StartOver")

func test_window_resize_refits() -> void:
	await _open_start_over_box()
	_large()
	_assert_stacked("StartOver")
	assert_float(_control("%StartOverBox").size.x).is_equal(418.0)
	get_tree().root.size = Vector2i(640, 360)   # k = 1: Large rounds up to s = 2
	var box := _control("%StartOverBox")
	assert_float(box.size.x).is_equal(312.0)
	assert_vector(box.position + box.pivot_offset).is_equal(Screen.CENTRE)
	get_tree().root.size = Vector2i(1280, 720)

func test_a_box_opened_while_stacked_is_already_fitted() -> void:
	_saved()
	_largest()
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)
	_assert_stacked("StartOver")
	_assert_box("StartOver", START_OVER_LARGEST)

func test_stacked_buttons_do_not_overlap() -> void:
	await _open_start_over_box()
	_largest()
	_assert_stacked("StartOver")
	_assert_stacked("Replace")
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
	_assert_stacked("StartOver")
	await _press(KEY_RIGHT)
	await _press(KEY_ENTER)
	assert_bool(screen.menu.locked).is_true()
	assert_bool(_control("%StartOverBox").visible).is_false()
	Display.use_prefs(DisplayPrefs.new())
	await _open_start_over_box()
	_largest()
	_assert_stacked("StartOver")
	await _press(KEY_RIGHT)
	await _press(KEY_ESCAPE)
	assert_bool(_control("%StartOverBox").visible).is_false()
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.KEEP_MY_ISLAND)
	assert_int(screen.menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
	assert_array(calls).is_empty()

func test_hover_still_selects_a_stacked_button() -> void:
	await _open_start_over_box()
	_largest()
	_assert_stacked("StartOver")
	_move_over(_control("%StartOver"))
	assert_int(screen.menu.box_selected).is_equal(TitleMenu.BoxButton.START_OVER)
	_box_highlighted("StartOver")
