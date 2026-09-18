extends GdUnitTestSuite
## At larger Text size the title's Start over and Replace boxes grow their words; grown buttons stack.

const SCENE := "res://src/title/title_screen.tscn"
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title_box_text_size"
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

func _text_up(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	await await_idle_frame()
	await await_idle_frame()

func test_large_text_stacks_the_start_over_buttons() -> void:
	await _open_start_over_box()
	await _text_up(1)
	assert_bool(screen._start_over_box.stacked).is_true()
	var keep := _rect("%KeepMyIsland")
	var start := _rect("%StartOver")
	assert_float(absf(keep.get_center().x - start.get_center().x)).is_less_equal(0.5)
	assert_float(keep.end.y).is_less(start.position.y)

func test_grown_button_is_wide_enough_for_its_words() -> void:
	await _open_start_over_box()
	await _text_up(1)
	assert_float(_control("%KeepMyIsland").size.x).is_greater_equal(ceilf(("Keep my island".length() * 8) * 1.5))

func test_both_boxes_are_laid_out_before_they_open() -> void:
	await _open_start_over_box()
	await _text_up(2)
	assert_float(_control("%ReplaceBox").size.x).is_equal(_control("%StartOverBox").size.x)

func test_text_normal_is_todays_layout() -> void:
	await _open_start_over_box()
	assert_that(_panel_rect("StartOver")).is_equal(Rect2(12, 42, 296, 96))
	assert_that(_panel_rect("Replace")).is_equal(Rect2(12, 42, 296, 96))
