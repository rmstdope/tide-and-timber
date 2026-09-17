extends GdUnitTestSuite
## UI size grows the pause layer, the dawn-save box, the morning card and the build list; strips keep their corner.

const EPS := Vector2(0.01, 0.01)

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(640, 360)
	Pause.debug_tools = false
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause") as Pause
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	Pause.debug_tools = OS.is_debug_build()
	get_tree().paused = false
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode

func _step(times: int) -> void:
	for i in times:
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _grown(layer: CanvasLayer, s: float) -> bool:
	return layer.transform.is_equal_approx(OverlayScale.layer_transform(s, OverlayScale.ANCHOR_CENTRE))

func _open_settings() -> SettingsBoard:
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	return pause.get_node("%SettingsBoard") as SettingsBoard

func test_pause_layer_grows_about_the_centre() -> void:
	assert_bool(pause.transform == Transform2D.IDENTITY).is_true()
	_step(1)
	assert_bool(_grown(pause, 1.5)).is_true()
	_step(1)
	assert_bool(_grown(pause, 2.0)).is_true()

func test_paused_board_strip_stays_in_the_corner() -> void:
	_step(2)
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await get_tree().process_frame
	assert_vector(pause.strip.get_global_transform_with_canvas().origin).is_equal_approx(Vector2(4, 152), EPS)
	var resume := pause.get_node("%Resume") as Control
	var centre := resume.get_global_transform_with_canvas() * (Vector2(120, 16) / 2)
	assert_float(centre.x).is_equal_approx(160.0, 0.01)

func test_settings_board_grows_while_ui_size_changes_and_keeps_the_highlight() -> void:
	var board := await _open_settings()
	var value := board.get_node("%UiSize/Row/Value") as Label
	await _tap(KEY_RIGHT)
	assert_int(Display.prefs.ui_size).is_equal(DisplayPrefs.Size.LARGE)
	assert_float(pause.transform.get_scale().x).is_equal_approx(1.5, 0.0001)
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)
	assert_bool(board.visible).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_bool(is_same((board.get_node("%UiSize") as Control).get_theme_stylebox("panel"), Pause.PLANK_HIGHLIGHT_STYLE)).is_true()
	assert_str(value.text).is_equal("Large")
	await _tap(KEY_RIGHT)
	assert_float(pause.transform.get_scale().x).is_equal_approx(2.0, 0.0001)
	assert_str(value.text).is_equal("Largest")
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)
	await _tap(KEY_LEFT)
	await _tap(KEY_LEFT)
	assert_bool(pause.transform == Transform2D.IDENTITY).is_true()
	assert_str(value.text).is_equal("Normal")
	assert_int(board.rules.highlighted).is_equal(SettingsMenu.Plank.UI_SIZE)

func test_a_grown_row_is_where_it_is_drawn() -> void:
	_step(2)
	var board := await _open_settings()
	var drawn := Vector2(160, 64)
	var text_row := board.get_node("%TextSize") as Control
	var ui_row := board.get_node("%UiSize") as Control
	var local := text_row.get_global_transform_with_canvas().affine_inverse() * drawn
	assert_bool(Rect2(Vector2.ZERO, Vector2(200, 16)).has_point(local)).is_true()
	var in_ui := ui_row.get_global_transform_with_canvas().affine_inverse() * drawn
	assert_bool(Rect2(Vector2.ZERO, ui_row.size).has_point(in_ui)).is_false()

func test_dawn_save_box_grows_about_the_centre() -> void:
	_step(2)
	var autosave := waking.get_node("%Autosave") as Autosave
	assert_bool(_grown(autosave.get_node("%Box").get_parent() as CanvasLayer, 2.0)).is_true()
	autosave.save_game = func() -> Error: return FAILED
	autosave.on_dawn()
	await get_tree().process_frame
	assert_vector(autosave.strip.get_global_transform_with_canvas().origin).is_equal_approx(Vector2(4, 152), EPS)

func test_morning_card_grows_about_the_centre() -> void:
	_step(2)
	assert_bool(_grown(waking.get_node("%Card").get_parent() as CanvasLayer, 2.0)).is_true()

func test_nothing_else_on_those_layers_moves_at_normal() -> void:
	assert_bool(pause.transform == Transform2D.IDENTITY).is_true()
	var box_layer := waking.get_node("%Autosave").get_node("%Box").get_parent() as CanvasLayer
	assert_bool(box_layer.transform == Transform2D.IDENTITY).is_true()
	var card_layer := waking.get_node("%Card").get_parent() as CanvasLayer
	assert_bool(card_layer.transform == Transform2D.IDENTITY).is_true()

func test_build_list_grows_beside_him() -> void:
	var beach := waking.get_node("%Beach")
	var list := beach.get_node("%BuildList") as BuildList
	var him := Vector2(100, 150)
	list.place_beside(him)
	assert_vector(list.scale).is_equal(Vector2.ONE)
	assert_vector(list.position).is_equal(Vector2(112, 81))
	_step(1)
	assert_vector(list.scale).is_equal(Vector2(1.5, 1.5))
	assert_vector(list.position).is_equal(BuildList.top_left_for(him, 1.5))
	_step(1)
	assert_vector(list.scale).is_equal(Vector2(2, 2))
	assert_vector(list.position).is_equal(BuildList.top_left_for(him, 2.0))
	assert_bool((list.get_parent() as CanvasLayer).transform == Transform2D.IDENTITY).is_true()
