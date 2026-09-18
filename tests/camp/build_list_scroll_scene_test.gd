extends GdUnitTestSuite
## On the beach at Largest, the build list opens framed above the lifted build hint and scrolls to the highlight.

const SCENE := "res://src/beach/beach.tscn"

var runner: GdUnitSceneRunner
var beach: Beach
var builder: Builder
var inventory: Inventory
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	InputDevice.reset()
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach
	builder = beach.get_node("%Builder") as Builder
	inventory = beach.inventory
	Display.use_prefs(DisplayPrefs.new())
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _n(unique: String) -> Node:
	return beach.get_node("%" + unique)

func _list() -> BuildList:
	return _n("BuildList") as BuildList

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()
	await await_millis(50)
	await await_idle_frame()
	await await_idle_frame()

func _driftwood(n: int) -> void:
	inventory.add(Item.Kind.DRIFTWOOD, n)

## The build hint's on-screen top. Hud is an identity transform, so this is the list's band edge.
func _hint_top() -> float:
	return HintLift.screen_rect(_n("KeyHint") as Control).position.y

func _visible(i: int) -> bool:
	return _list().clip.get_global_rect().encloses(_list().rows[i].get_global_rect())

func test_largest_list_opens_framed_above_the_lifted_hint() -> void:
	_driftwood(9)
	await _press(KEY_B)
	assert_float(_hint_top()).is_equal(108.0)
	assert_bool(_list().scrolls).is_true()
	assert_float(_list().position.y).is_equal(2.0)
	assert_float(_list().position.y + _list().size.y * 2).is_equal(_hint_top() - 2.0)
	assert_int(_list().offset).is_equal(0)
	assert_bool(_list().shows_mark_above()).is_false()
	assert_bool(_list().shows_mark_below()).is_true()
	assert_bool(_visible(0)).is_true()

func test_down_scrolls_to_the_fire_row() -> void:
	_driftwood(9)
	await _press(KEY_B)
	await _press(KEY_DOWN)
	assert_int(builder.menu.highlighted).is_equal(1)
	assert_int(_list().offset).is_equal(23)
	assert_bool(_list().shows_mark_above()).is_true()
	assert_bool(_list().shows_mark_below()).is_false()
	assert_bool(_visible(1)).is_true()
	await _press(KEY_UP)
	assert_int(_list().offset).is_equal(0)

func test_hovering_the_fire_row_scrolls_to_it() -> void:
	_driftwood(9)
	await _press(KEY_B)
	_list().rows[1].mouse_entered.emit()
	assert_int(builder.menu.highlighted).is_equal(1)
	assert_int(_list().offset).is_equal(23)

func test_closing_and_reopening_starts_at_the_top() -> void:
	_driftwood(9)
	await _press(KEY_B)
	await _press(KEY_DOWN)
	assert_int(_list().offset).is_equal(23)
	await _press(KEY_ESCAPE)
	await _press(KEY_B)
	assert_int(builder.menu.highlighted).is_equal(0)
	assert_int(_list().offset).is_equal(0)
	assert_bool(_list().shows_mark_above()).is_false()

func test_large_list_fits_above_the_lifted_hint() -> void:
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, -1)
	_driftwood(9)
	await _press(KEY_B)
	assert_bool(_list().scrolls).is_false()
	assert_vector(_list().size).is_equal(BuildList.SIZE)
	assert_vector(_list().scale).is_equal(Vector2(1.5, 1.5))
