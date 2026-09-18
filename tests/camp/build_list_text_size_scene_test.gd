extends GdUnitTestSuite
## On the beach, the build list follows Text size: its words grow, and it stacks and widens with them.
##
## At 640x360 the list stacks only at UI Largest and Text Largest (Text size alone never widens it past
## the picture), and there the stacked list, 252 x 101 drawn 2x, fits the room above the hint.

const SCENE := "res://src/beach/beach.tscn"

var runner: GdUnitSceneRunner
var beach: Beach
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
	inventory = beach.inventory
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _list() -> BuildList:
	return beach.get_node("%BuildList") as BuildList

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()
	await await_millis(50)

func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()

func test_the_beach_list_grows_with_text_size() -> void:
	inventory.add(Item.Kind.DRIFTWOOD, 9)
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	await _settle()
	await _press(KEY_B)
	await _settle()
	assert_bool(_list().stacked).is_true()
	assert_vector(_list().list_size()).is_equal(Vector2(252, 101))
	assert_vector(_list().size).is_equal(Vector2(252, 101))
	assert_vector(_list().scale).is_equal(Vector2(2, 2))
	assert_vector(_list().title_label.scale).is_equal(Vector2(2, 2))
	assert_str(_list().cost_labels[1].text).is_equal("Needs a lean-to")

# Retired in tr-1o0.1: the build list wrapping its words and scrolling. At 640x360 no UI size, Text size and
# window reaches either, so the list has neither. This is what fails if a later change grows the list past
# the room above the lifted build hint, or its words past the list.
func test_at_the_largest_sizes_the_list_fits_above_the_hint_unwrapped(
		window: Vector2i, test_parameters := [[Vector2i(1280, 720)], [Vector2i(640, 360)]]) -> void:
	get_tree().root.size = window
	inventory.add(Item.Kind.DRIFTWOOD, 9)
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	await _settle()
	await _press(KEY_B)
	await _settle()
	var list := _list()
	var hint_top := HintLift.screen_rect(beach.get_node("%KeyHint") as Control).position.y
	var s := list.scale.y
	assert_float(list.position.y + list.list_size().y * s).override_failure_message(
			"the list's bottom runs past the room above the hint at %s" % hint_top) \
		.is_less_equal(hint_top - ScrollWindow.EDGE)
	assert_float(list.position.y).is_greater_equal(ScrollWindow.EDGE)
	var room := list._text_width_available()
	for label: Label in list.name_labels + list.cost_labels:
		assert_float(BuildList._text_width(label)).override_failure_message(
				"'%s' is wider than the %s its row gives it" % [label.text, room]).is_less_equal(room)
