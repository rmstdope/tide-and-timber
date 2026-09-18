extends GdUnitTestSuite
## At larger Text size the title's Start over and Replace boxes grow their words; grown buttons stack.

const SCENE := "res://src/title/title_screen.tscn"
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title_box_text_size"


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

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _open_start_over_box() -> void:
	_saved()
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)

func _control(path: String) -> Control:
	return screen.get_node(path) as Control

func _rect(path: String) -> Rect2:
	var n := _control(path)
	return Rect2(n.position, n.size)

## The box's rest panel: the node now carries the framed rect, so the rest layout is read from the screen.
func _panel_rect(box: String) -> Rect2:
	return screen._start_over_box.panel if box == "StartOver" else screen._replace_box.panel

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
	assert_float(screen._replace_box.panel.size.x).is_equal(312.0)
	assert_float(_control("%ReplaceBox").size.x).is_equal(_control("%StartOverBox").size.x)

func test_text_normal_is_todays_layout() -> void:
	await _open_start_over_box()
	assert_that(_panel_rect("StartOver")).is_equal(Rect2(12, 42, 296, 96))
	assert_that(_panel_rect("Replace")).is_equal(Rect2(12, 42, 296, 96))
