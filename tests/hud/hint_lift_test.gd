extends GdUnitTestSuite
## A grown bottom hint lifts above the item bar's plank on screen; a Normal-sized one, or one with no bar, stays.

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _rect_approx(a: Rect2, b: Rect2) -> bool:
	return a.position.is_equal_approx(b.position) and a.size.is_equal_approx(b.size)

func test_no_bar_no_lift() -> void:
	assert_float(HintLift.lift(Rect2(4, 152, 296, 24), 12.0, Rect2())).is_equal(0.0)

func test_grown_hint_over_the_bar_sits_2_above_it() -> void:
	assert_float(HintLift.lift(Rect2(4, 152, 296, 24), 12.0, Rect2(20, 134, 282, 44))).is_equal_approx(-44.0, 0.01)
	assert_float(HintLift.lift(Rect2(4, 158, 222, 18), 12.0, Rect2(55, 145.5, 211.5, 33))).is_equal_approx(-32.5, 0.01)

func test_normal_sized_hint_never_lifts() -> void:
	assert_float(HintLift.lift(Rect2(4, 164, 148, 12), 12.0, Rect2(90, 157, 141, 22))).is_equal(0.0)

func test_grown_hint_clear_of_the_bar_stays() -> void:
	var bar := Rect2(20, 134, 282, 44)
	assert_float(HintLift.lift(Rect2(4, 152, 14, 24), 12.0, bar)).is_equal(0.0)
	assert_float(HintLift.lift(Rect2(4, 100, 296, 24), 12.0, bar)).is_equal(0.0)
	assert_float(HintLift.lift(Rect2(4, 110, 296, 24), 12.0, bar)).is_equal(0.0)

func test_bar_rect_is_the_plank_on_screen() -> void:
	scene_runner("res://src/beach/beach.tscn")
	await get_tree().process_frame
	assert_bool(_rect_approx(HintLift.bar_rect(get_tree()), Rect2(90, 157, 141, 22))).is_true()
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	assert_bool(_rect_approx(HintLift.bar_rect(get_tree()), Rect2(20, 134, 282, 44))).is_true()

func test_hidden_bar_has_no_rect() -> void:
	var beach := scene_runner("res://src/beach/beach.tscn").scene()
	await get_tree().process_frame
	(beach.get_node("%ItemBar") as Control).hide()
	assert_bool(HintLift.bar_rect(get_tree()).has_area()).is_false()

func test_bar_joins_its_group() -> void:
	var beach := scene_runner("res://src/beach/beach.tscn").scene()
	await get_tree().process_frame
	assert_bool(get_tree().get_first_node_in_group(ItemBar.GROUP) == beach.get_node("%ItemBar")).is_true()

func test_place_converts_to_the_parent_units() -> void:
	var bar_layer := auto_free(CanvasLayer.new()) as CanvasLayer
	var bar_scale := UiScale.new()
	bar_scale.anchor = OverlayScale.ANCHOR_BOTTOM_CENTRE
	bar_layer.add_child(bar_scale)
	bar_layer.add_child(ItemBar.new())
	add_child(bar_layer)
	var layer := auto_free(CanvasLayer.new()) as CanvasLayer
	var ui := UiScale.new()
	ui.anchor = Vector2(160, 180)
	layer.add_child(ui)
	var c := Control.new()
	c.size = Vector2(320, 14)
	layer.add_child(c)
	add_child(layer)
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	assert_float(HintLift.place(c, 166.0, 14.0)).is_equal_approx(-48.0, 0.01)
	assert_float(c.position.y).is_equal_approx(142.0, 0.01)
	assert_float(HintLift.screen_rect(c).end.y).is_equal_approx(132.0, 0.01)
	assert_float(c.position.x).is_equal(0.0)
