extends GdUnitTestSuite
## The title menu at a larger Text size: the plank words grow, every plank takes the widest plank's width
## and grows taller, and the Reason line under a dimmed Continue widens to the screen, then wraps.

const SCENE := "res://src/title/title_screen.tscn"
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title_text_size"
const S := DisplayPrefs.Setting

var runner: GdUnitSceneRunner
var screen: TitleScreen
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
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

func _tap(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()

func _node(unique: String) -> Control:
	return screen.get_node("%" + unique) as Control

func test_normal_text_menu_as_before() -> void:
	_saved()
	await _settle()
	assert_vector(_node("NewGame").size).is_equal(Vector2(90, 18))
	assert_vector(_node("Continue").size).is_equal(Vector2(90, 21))
	assert_vector(_node("Menu").position).is_equal(Vector2(0, 83))
	# The constant menu_top_at grows the menu about must be the scene's own Normal height.
	assert_float(_node("Menu").get_combined_minimum_size().y) \
		.is_equal(TitleScreen.MENU_HEIGHT_WITH_SAVE)

func test_large_text_widens_and_heightens_every_plank() -> void:
	Display.prefs.step(S.TEXT_SIZE, 1)
	_saved()
	await _settle()
	assert_vector(_node("Continue").size).is_equal(Vector2(100, 29))
	for name: String in ["NewGame", "Settings", "Quit"]:
		assert_vector(_node(name).size).is_equal(Vector2(100, 22))
	assert_float(_node("Menu").get_combined_minimum_size().y).is_equal(104.0)
	assert_bool(screen.menu_scrolls).is_false()
	var top := TitleScreen.menu_top_at(TitleScreen.MENU_TOP_WITH_SAVE, 104, 1.0,
			TitleScreen.MENU_HEIGHT_WITH_SAVE, screen.strip.screen_top())
	assert_float(_node("Menu").position.y).is_equal(top)
	assert_float(_node("Menu").position.y + 104.0).is_less_equal(screen.strip.screen_top() - 2.0)

func test_largest_text_wraps_the_reason_line() -> void:
	Display.prefs.step(S.TEXT_SIZE, 2)
	_broken()
	await _settle()
	assert_bool((_node("Reason") as GrownWords).wrapped).is_true()
	assert_vector(_node("Reason").get_combined_minimum_size()).is_equal(Vector2(312, 38))
	assert_vector(_node("NewGame").size).is_equal(Vector2(132, 26))
	assert_vector(_node("Continue").size).is_equal(Vector2(132, 26))
	assert_bool(Rect2(0, 0, 320, 180).encloses(_node("Menu").get_global_rect())).is_true()

func test_the_normal_height_constants_match_the_scene() -> void:
	_broken()
	await _settle()
	assert_float(_node("Menu").get_combined_minimum_size().y).is_equal(TitleScreen.MENU_HEIGHT_DIMMED)
	_open("user://test_saves/title_text_size_none")   # never created: no save
	await _settle()
	assert_float(_node("Menu").get_combined_minimum_size().y).is_equal(TitleScreen.MENU_HEIGHT)

func test_largest_ui_and_text_scroll_and_stay_on_screen() -> void:
	Display.prefs.step(S.UI_SIZE, 2)
	Display.prefs.step(S.TEXT_SIZE, 2)
	_saved()
	await _settle()
	assert_bool(screen.menu_scrolls).is_true()
	assert_bool(_node("MenuClip").get_global_rect().encloses(_node("Continue").get_global_rect())) \
		.is_true()
	for name: String in ["Continue", "NewGame", "Settings", "Quit"]:
		var r := _node(name).get_global_rect()
		assert_float(r.position.x).is_greater_equal(0.0)
		assert_float(r.end.x).is_less_equal(320.0)

func test_text_size_change_keeps_the_highlight() -> void:
	_saved()
	await _settle()
	await _tap(KEY_DOWN)
	assert_int(screen.menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
	Display.prefs.step(S.TEXT_SIZE, 1)
	await _settle()
	assert_int(screen.menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
	Display.use_prefs(DisplayPrefs.new())
	await _settle()
	assert_vector(_node("NewGame").size).is_equal(Vector2(90, 18))
	assert_vector(_node("Menu").position).is_equal(Vector2(0, 83))
