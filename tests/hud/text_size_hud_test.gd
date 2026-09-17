extends GdUnitTestSuite
## Text size grows the HUD's words: the hint bands, the clock, item counts, the name plank and the
## use prompt. Every view keeps its own anchor and lays out again when Text size changes.

const Setting := DisplayPrefs.Setting

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(640, 360)
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _scene(path: String) -> Node:
	var runner := scene_runner(path)
	var scene := runner.scene()
	scene.set_process(false)
	return scene

# --- hint bands ---

func test_menu_strip_band_grows_in_the_corner() -> void:
	var strip := auto_free(MenuStrip.new()) as MenuStrip
	add_child(strip)
	strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	Display.prefs.step(Setting.TEXT_SIZE, 2)
	await get_tree().process_frame
	assert_vector(strip.size).is_equal_approx(Vector2(228, 21), Vector2(0.01, 0.01))
	assert_vector(strip.get_global_transform_with_canvas().origin) \
		.is_equal_approx(Vector2(4, 155), Vector2(0.01, 0.01))
	assert_int(strip.view.line_height()).is_equal(18)
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	assert_vector(strip.size).is_equal_approx(Vector2(148, 12), Vector2(0.01, 0.01))
	assert_vector(strip.get_global_transform_with_canvas().origin) \
		.is_equal_approx(Vector2(4, 164), Vector2(0.01, 0.01))

func test_menu_strip_grown_by_text_lifts_above_the_bar() -> void:
	var bar_layer := auto_free(CanvasLayer.new()) as CanvasLayer
	var ui := UiScale.new()
	ui.anchor = OverlayScale.ANCHOR_BOTTOM_CENTRE
	bar_layer.add_child(ui)
	bar_layer.add_child(ItemBar.new())
	add_child(bar_layer)
	var strip := auto_free(MenuStrip.new()) as MenuStrip
	add_child(strip)
	strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	Display.prefs.step(Setting.TEXT_SIZE, 2)
	await get_tree().process_frame
	assert_vector(strip.get_global_transform_with_canvas().origin) \
		.is_equal_approx(Vector2(4, 134), Vector2(0.01, 0.01))
	assert_float(strip.screen_top()).is_equal_approx(134.0, 0.01)

func test_build_hint_band_grows_and_keeps_its_bottom() -> void:
	var beach := _scene("res://src/beach/beach.tscn")
	var hint := beach.get_node("%KeyHint") as KeyHint
	Display.prefs.step(Setting.TEXT_SIZE, 2)
	hint.show_hint(DeviceHints.Hint.BUILD_LIST)
	await get_tree().process_frame
	assert_float(hint.size.y).is_equal_approx(21.0, 0.01)
	assert_float(hint.size.x).is_equal_approx(hint.view.line_width() + 8.0, 0.01)
	assert_float(hint.position.y).is_equal_approx(127.0, 0.01)
	assert_float(HintLift.screen_rect(hint).end.y).is_equal_approx(148.0, 0.01)
	assert_float(hint.position.x).is_equal_approx(roundi((320 - hint.size.x) / 2.0), 0.01)

func test_move_hint_band_grows_and_lifts_above_the_bar() -> void:
	var waking := _scene("res://src/waking/waking.tscn")
	var move_hint := waking.get_node("%MoveHint") as Control
	Display.prefs.step(Setting.TEXT_SIZE, 2)
	await get_tree().process_frame
	assert_vector(move_hint.size).is_equal_approx(Vector2(320, 23), Vector2(0.01, 0.01))
	assert_vector((move_hint.get_node("Band") as Control).size) \
		.is_equal_approx(Vector2(320, 23), Vector2(0.01, 0.01))
	assert_vector((move_hint.get_node("Line") as Control).size) \
		.is_equal_approx(Vector2(320, 23), Vector2(0.01, 0.01))
	assert_float(move_hint.position.y).is_equal_approx(132.0, 0.01)
	assert_float(HintLift.screen_rect(move_hint).end.y).is_equal_approx(155.0, 0.01)
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	assert_vector(move_hint.size).is_equal_approx(Vector2(320, 14), Vector2(0.01, 0.01))
	assert_float(move_hint.position.y).is_equal_approx(166.0, 0.01)

# --- the clock ---

func test_clock_plank_widens_and_grows_taller() -> void:
	var dn := _scene("res://src/day_night/day_night.tscn")
	var plank := dn.get_node("%Plank") as Control
	var day := dn.get_node("%DayLabel") as Label
	var dial := dn.get_node("%Dial") as Control
	var time := dn.get_node("%TimeLabel") as Label
	Display.prefs.step(Setting.TEXT_SIZE, 1)
	assert_vector(plank.size).is_equal_approx(Vector2(68, 62), Vector2(0.01, 0.01))
	assert_vector(day.scale).is_equal_approx(Vector2(1.5, 1.5), Vector2(0.01, 0.01))
	assert_vector(day.position).is_equal_approx(Vector2(0, 5), Vector2(0.01, 0.01))
	assert_vector(dial.position).is_equal_approx(Vector2(2, 18), Vector2(0.01, 0.01))
	assert_vector(dial.size).is_equal_approx(Vector2(64, 28), Vector2(0.01, 0.01))
	assert_vector(time.position).is_equal_approx(Vector2(0, 47), Vector2(0.01, 0.01))
	assert_vector(time.scale).is_equal_approx(Vector2(1.5, 1.5), Vector2(0.01, 0.01))
	Display.prefs.step(Setting.TEXT_SIZE, 1)
	assert_vector(plank.size).is_equal_approx(Vector2(88, 70), Vector2(0.01, 0.01))
	assert_vector(dial.position).is_equal_approx(Vector2(12, 22), Vector2(0.01, 0.01))
	assert_float(time.position.y).is_equal_approx(51.0, 0.01)
	Display.use_prefs(DisplayPrefs.new())
	assert_vector(plank.size).is_equal_approx(Vector2(64, 54), Vector2(0.01, 0.01))
	assert_vector(dial.position).is_equal_approx(Vector2(0, 14), Vector2(0.01, 0.01))
	assert_vector(time.position).is_equal_approx(Vector2(0, 43), Vector2(0.01, 0.01))
	assert_vector(day.scale).is_equal_approx(Vector2.ONE, Vector2(0.01, 0.01))
	assert_vector(time.scale).is_equal_approx(Vector2.ONE, Vector2(0.01, 0.01))
	assert_vector(plank.position).is_equal_approx(Vector2(4, 4), Vector2(0.01, 0.01))
	assert_bool((dn.get_node("%Hud") as CanvasLayer).transform == Transform2D.IDENTITY).is_true()

func test_clock_refits_when_the_day_gets_a_digit() -> void:
	var dn := _scene("res://src/day_night/day_night.tscn")
	Display.prefs.step(Setting.TEXT_SIZE, 2)
	dn.set_minutes(GameClock.START_MINUTES + 9 * GameClock.MINUTES_PER_DAY)
	assert_str((dn.get_node("%DayLabel") as Label).text).is_equal("DAY 10")
	assert_float((dn.get_node("%Plank") as Control).size.x).is_equal_approx(104.0, 0.01)

# --- the use prompt ---

func test_use_prompt_plank_grows_with_its_verb() -> void:
	var beach := _scene("res://src/beach/beach.tscn")
	var prompt := beach.get_node("%Prompt") as UsePrompt
	prompt.verb_label.text = "Take"
	Display.prefs.step(Setting.TEXT_SIZE, 2)
	assert_float(prompt.text_scale()).is_equal_approx(2.0, 0.01)
	assert_int(prompt.height()).is_equal(21)
	assert_int(prompt.width()).is_equal(81)
	assert_vector(prompt.verb_label.scale).is_equal_approx(Vector2(2, 2), Vector2(0.01, 0.01))
	assert_vector(prompt.verb_label.position).is_equal_approx(Vector2(-26, -18), Vector2(0.01, 0.01))
	assert_vector(prompt.scale).is_equal_approx(Vector2.ONE, Vector2(0.01, 0.01))
	Display.use_prefs(DisplayPrefs.new())
	assert_int(prompt.height()).is_equal(13)
	assert_int(prompt.width()).is_equal(49)
	assert_vector(prompt.verb_label.position).is_equal_approx(Vector2(-10, -10), Vector2(0.01, 0.01))
	assert_vector(prompt.verb_label.scale).is_equal_approx(Vector2.ONE, Vector2(0.01, 0.01))
