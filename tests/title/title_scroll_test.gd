extends GdUnitTestSuite
## The title menu when it no longer fits above the Select strip: it is shown in a clipped band, scrolls
## to the highlight, and ▲ / ▼ show where planks are hidden.

const SCENE := "res://src/title/title_screen.tscn"
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title_scroll"
const NO_SAVE := "user://test_saves/title_none"   # never created
const S := DisplayPrefs.Setting

var runner: GdUnitSceneRunner
var screen: TitleScreen
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(640, 360)
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	_rm(ROOT)
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode

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
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	screen.set_process(false)
	screen.quit_game = func() -> void: pass
	screen.start_new_game = func() -> void: pass
	screen.start_continue = func() -> void: pass
	screen.read_save(dir)

func _saved() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_open(DIR)

func _broken() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(DIR.path_join("meta.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1}))
	f.close()
	_open(DIR)

func _size(steps: int) -> void:
	for i in absi(steps):
		Display.prefs.step(S.UI_SIZE, signi(steps))

func _tap(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()

func _node(unique: String) -> Control:
	return screen.get_node("%" + unique) as Control

# gdUnit's simulate_mouse_move takes window coordinates; the scene's rects are in the 320x180 canvas.
func _to_window(canvas_point: Vector2) -> Vector2:
	return get_tree().root.get_final_transform() * canvas_point

func _a_move() -> InputEventMouseMotion:
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(1, 0)
	return move

func _shown(unique: String) -> bool:
	return _node("MenuClip").get_global_rect().encloses(_node(unique).get_global_rect())

func test_normal_menu_does_not_scroll() -> void:
	_saved()
	await _settle()
	assert_bool(screen.menu_scrolls).is_false()
	assert_that(_node("MenuClip").get_rect()).is_equal(Rect2(0, 0, 320, 180))
	assert_that(_node("Menu").position).is_equal(Vector2(0, 83))
	assert_bool(_node("MenuMarks").visible).is_false()

func test_largest_menu_without_a_save_still_fits() -> void:
	_size(2)
	_open(NO_SAVE)
	await _settle()
	assert_bool(screen.menu_scrolls).is_false()
	assert_that(_node("Menu").position).is_equal(Vector2(-160, 30))

func test_largest_menu_with_a_save_opens_at_the_top() -> void:
	_size(2)
	_saved()
	await _settle()
	assert_bool(screen.menu_scrolls).is_true()
	assert_int(screen.menu_offset).is_equal(0)
	assert_that(_node("MenuClip").get_rect()).is_equal(Rect2(0, 22, 320, 108))
	assert_that(_node("Menu").position).is_equal(Vector2(-160, 0))
	assert_bool(_node("MenuMarks").visible).is_true()
	assert_that(_node("MenuMarks").position).is_equal(Vector2(-160, 2))
	assert_that(_node("MenuMarks").size).is_equal(Vector2(320, 74))
	assert_bool(screen.shows_menu_mark_above()).is_false()
	assert_bool(screen.shows_menu_mark_below()).is_true()
	assert_bool(_shown("Continue")).is_true()
	assert_float(_node("MenuClip").get_global_rect().end.y + ScrollWindow.MARK_ROW * 2.0) \
			.is_less_equal(screen.strip.screen_top() - 2.0)

func test_moving_down_scrolls_and_wraps() -> void:
	_size(2)
	_saved()
	await _settle()
	await _tap(KEY_DOWN)
	assert_int(screen.menu_offset).is_equal(0)
	await _tap(KEY_DOWN)
	assert_int(screen.menu_offset).is_equal(9)
	assert_float(_node("Menu").position.y).is_equal(-18.0)
	assert_bool(_shown("Settings")).is_true()
	assert_bool(screen.shows_menu_mark_above()).is_true()
	assert_bool(screen.shows_menu_mark_below()).is_true()
	await _tap(KEY_DOWN)
	assert_int(screen.menu_offset).is_equal(30)
	assert_bool(_shown("Quit")).is_true()
	assert_bool(screen.shows_menu_mark_below()).is_false()
	await _tap(KEY_DOWN)
	assert_int(screen.menu_offset).is_equal(0)
	assert_bool(screen.shows_menu_mark_above()).is_false()

func test_dimmed_continue_scrolls_and_shows_on_the_first_choice() -> void:
	_size(2)
	_broken()
	await _settle()
	assert_bool(screen.menu_scrolls).is_true()
	assert_int(screen.menu_offset).is_equal(0)
	await _tap(KEY_UP)
	assert_bool(_shown("Quit")).is_true()
	assert_bool(screen.shows_menu_mark_below()).is_false()
	await _tap(KEY_DOWN)
	assert_int(screen.menu_offset).is_equal(0)
	assert_bool(_shown("Continue")).is_true()

func test_hovering_a_partly_hidden_plank_scrolls_to_it() -> void:
	_size(2)
	_saved()
	await _settle()
	_node("Settings").gui_input.emit(_a_move())
	assert_int(screen.menu.highlighted).is_equal(TitleMenu.Choice.SETTINGS)
	assert_int(screen.menu_offset).is_equal(9)
	assert_bool(_shown("Settings")).is_true()

func test_back_to_normal_puts_the_menu_back() -> void:
	_size(2)
	_saved()
	await _settle()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	assert_int(screen.menu_offset).is_equal(9)
	Display.use_prefs(DisplayPrefs.new())
	await _settle()
	assert_bool(screen.menu_scrolls).is_false()
	assert_that(_node("Menu").position).is_equal(Vector2(0, 83))
	assert_that(_node("Menu").scale).is_equal(Vector2.ONE)
	assert_that(_node("MenuClip").get_rect()).is_equal(Rect2(0, 0, 320, 180))
	assert_bool(_node("MenuMarks").visible).is_false()

func test_large_menu_with_a_save_fits() -> void:
	_size(1)
	_saved()
	await _settle()
	assert_bool(screen.menu_scrolls).is_false()

func test_marks_go_while_the_settings_board_is_open() -> void:
	_size(2)
	_saved()
	await _settle()
	assert_bool(_node("MenuMarks").visible).is_true()
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _settle()
	assert_bool(screen.menu.settings_open).is_true()
	assert_bool(_node("MenuMarks").visible).is_false()
	await _tap(KEY_ESCAPE)
	await _settle()
	assert_bool(screen.menu.settings_open).is_false()
	assert_bool(_node("MenuMarks").visible).is_true()

func test_a_plank_scrolled_out_of_the_band_is_out_of_the_pointer_s_reach() -> void:
	_size(2)
	_saved()
	await _settle()
	var quit := _node("Quit")
	assert_bool(_shown("Quit")).is_false()
	var at := quit.get_global_rect().get_center()
	assert_bool(_node("MenuClip").get_global_rect().has_point(at)).is_false()   # below the band
	runner.simulate_mouse_move(_to_window(at))
	await runner.await_input_processed()
	# the clip keeps it out of reach: it neither takes the highlight nor scrolls the menu to itself
	assert_int(screen.menu.highlighted).is_equal(TitleMenu.Choice.CONTINUE)
	assert_int(screen.menu_offset).is_equal(0)

func test_a_plank_inside_the_band_still_takes_the_pointer() -> void:
	_size(2)
	_saved()
	await _settle()
	assert_bool(_shown("NewGame")).is_true()
	runner.simulate_mouse_move(_to_window(_node("NewGame").get_global_rect().get_center()))
	await runner.await_input_processed()
	assert_int(screen.menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
