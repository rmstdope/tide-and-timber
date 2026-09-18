extends GdUnitTestSuite
## UI size grows the clock, item bar, hints and his lines, each about its own spot; the world never grows.

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Display.use_prefs(DisplayPrefs.new())
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _scene(path: String) -> Node:
	var runner := scene_runner(path)
	var scene := runner.scene()
	scene.set_process(false)
	return scene

func _layer_of(n: Node) -> CanvasLayer:
	return n.get_parent() as CanvasLayer

func _is_scaled(n: Node, s: float, about: Vector2) -> bool:
	var layer := _layer_of(n)
	return layer != null and layer.transform.is_equal_approx(OverlayScale.layer_transform(s, about))

func test_clock_grows_about_the_top_left() -> void:
	var dn := _scene("res://src/day_night/day_night.tscn")
	var hud := dn.get_node("%Hud") as CanvasLayer
	assert_bool(hud.transform.is_equal_approx(OverlayScale.layer_transform(2.0, Vector2.ZERO))).is_true()
	Display.use_prefs(DisplayPrefs.new())
	assert_bool(hud.transform == Transform2D.IDENTITY).is_true()

func test_sunset_line_grows_about_its_bottom_centre() -> void:
	var dn := _scene("res://src/day_night/day_night.tscn")
	var sunset := dn.get_node("%Sunset")
	assert_bool(_layer_of(sunset) != dn.get_node("%Hud")).is_true()
	assert_bool(_is_scaled(sunset, 2.0, Vector2(160, 166))).is_true()

func test_item_bar_grows_about_the_bottom_centre() -> void:
	var beach := _scene("res://src/beach/beach.tscn")
	assert_bool(_is_scaled(beach.get_node("%ItemBar"), 2.0, Vector2(160, 180))).is_true()
	assert_bool(_layer_of(beach.get_node("%BuildList")).transform == Transform2D.IDENTITY).is_true()

func test_build_hint_grows_about_its_bottom_centre() -> void:
	var beach := _scene("res://src/beach/beach.tscn")
	assert_bool(_is_scaled(beach.get_node("%KeyHint"), 2.0, Vector2(160, 148))).is_true()

func test_move_hint_grows_about_the_bottom_centre() -> void:
	var waking := _scene("res://src/waking/waking.tscn")
	var hint := waking.get_node("%MoveHint")
	assert_bool(_is_scaled(hint, 2.0, Vector2(160, 180))).is_true()
	var cover_layer := _layer_of(waking.get_node("%Cover"))
	assert_bool(cover_layer.transform == Transform2D.IDENTITY).is_true()
	assert_int(cover_layer.layer).is_greater(_layer_of(hint).layer)

func test_lines_grow_about_their_bottom_centre() -> void:
	var waking := _scene("res://src/waking/waking.tscn")
	var bottom := Vector2(160, 166)
	assert_bool(_is_scaled(waking.get_node("%NightLine"), 2.0, bottom)).is_true()
	assert_bool(_is_scaled(waking.get_node("%Beach").get_node("%ShelterLine"), 2.0, bottom)).is_true()
	assert_bool(_is_scaled(waking.get_node("%Autosave").get_node("%Dawn"), 2.0, bottom)).is_true()
	var black := waking.get_node("%BlackLine")
	assert_bool(_is_scaled(black, 2.0, Vector2(160, 90))).is_true()
	assert_int(_layer_of(black).layer).is_equal(31)
	assert_bool(_is_scaled(waking.get_node("%Card"), 2.0, Vector2(160, 90))).is_true()

func test_use_prompt_grows_about_its_bottom_centre() -> void:
	var beach := _scene("res://src/beach/beach.tscn")
	var prompt := beach.get_node("%Prompt") as Node2D
	assert_vector(prompt.scale).is_equal(Vector2(2, 2))
	Display.use_prefs(DisplayPrefs.new())
	assert_vector(prompt.scale).is_equal(Vector2.ONE)

func test_world_never_grows() -> void:
	var beach := _scene("res://src/beach/beach.tscn")
	for n: String in ["%Player", "%Ghost", "%World"]:
		assert_vector((beach.get_node(n) as Node2D).scale).is_equal(Vector2.ONE)

func test_rising_line_grows_over_him() -> void:
	var beach := _scene("res://src/beach/beach.tscn")
	var line := RisingLine.show_over(beach.get_node("%Player"), "+1 Driftwood")
	assert_vector(line.scale).is_equal(Vector2(2, 2))

func test_build_hint_lifts_above_the_bar() -> void:
	var beach := _scene("res://src/beach/beach.tscn")
	var hint := beach.get_node("%KeyHint") as KeyHint
	hint.show_hint(DeviceHints.Hint.BUILD_LIST)
	await get_tree().process_frame
	assert_float(HintLift.screen_rect(hint).end.y).is_equal_approx(132.0, 0.01)
	assert_float(hint.position.y).is_equal_approx(128.0, 0.01)
	assert_float(hint.position.x).is_equal(float(roundi((320 - hint.size.x) / 2.0)))
	Display.use_prefs(DisplayPrefs.new())
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	await get_tree().process_frame
	assert_float(HintLift.screen_rect(hint).end.y).is_equal_approx(143.5, 0.01)
	assert_float(hint.position.y).is_equal_approx(133.0, 0.01)
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	assert_float(hint.position.y).is_equal_approx(136.0, 0.01)

func test_move_hint_lifts_above_the_bar() -> void:
	var waking := _scene("res://src/waking/waking.tscn")
	var hint := waking.get_node("%MoveHint") as Control
	await get_tree().process_frame
	assert_float(hint.position.y).is_equal_approx(142.0, 0.01)
	assert_float(HintLift.screen_rect(hint).end.y).is_equal_approx(132.0, 0.01)
	assert_float(hint.position.x).is_equal(0.0)
	assert_vector(hint.size).is_equal(Vector2(320, 14))
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	assert_float(hint.position.y).is_equal_approx(166.0, 0.01)
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	await get_tree().process_frame
	assert_float(HintLift.screen_rect(hint).end.y).is_equal_approx(143.5, 0.01)
