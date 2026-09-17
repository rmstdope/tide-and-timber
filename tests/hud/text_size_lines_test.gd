extends GdUnitTestSuite
## Text size grows the words of every line he speaks, and of the line rising over him; nothing else grows.

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(640, 360)
	Display.use_prefs(DisplayPrefs.new())
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _scene(path: String) -> Node:
	var runner := scene_runner(path)
	var scene := runner.scene()
	scene.set_process(false)
	return scene

func _assert_words_grown(line: Node, words: Node) -> void:
	assert_vector((words as Node2D).scale if words is Node2D else (words as Control).scale).is_equal(Vector2(1.5, 1.5))
	var layer := line.get_parent() as CanvasLayer
	if layer:
		assert_bool(layer.transform == Transform2D.IDENTITY).is_true()

func test_every_line_grows_its_words() -> void:
	var dn := _scene("res://src/day_night/day_night.tscn")
	_assert_words_grown(dn.get_node("%Sunset"), dn.get_node("%Sunset").get_node("Text"))
	var waking := _scene("res://src/waking/waking.tscn")
	_assert_words_grown(waking.get_node("%NightLine"), waking.get_node("%NightLine").get_node("Text"))
	var black := waking.get_node("%BlackLine")
	_assert_words_grown(black, black)
	var shelter := waking.get_node("%Beach").get_node("%ShelterLine")
	_assert_words_grown(shelter, shelter.get_node("Text"))
	var dawn := waking.get_node("%Autosave").get_node("%Dawn")
	_assert_words_grown(dawn, dawn.get_node("Text"))

func test_dawn_journal_keeps_ui_scale() -> void:
	var waking := _scene("res://src/waking/waking.tscn")
	var journal := waking.get_node("%Autosave").get_node("%Dawn").get_node("Journal") as Control
	assert_vector(journal.scale).is_equal(Vector2.ONE)

func test_rising_line_words_grow() -> void:
	var beach := _scene("res://src/beach/beach.tscn")
	var line := RisingLine.show_over(beach.get_node("%Player") as Node2D, "+1 Driftwood")
	assert_vector(line.scale).is_equal(Vector2.ONE)
	var label := line.get_child(0) as Label
	assert_vector(label.scale).is_equal(Vector2(1.5, 1.5))
	assert_float(label.position.x).is_equal(-floorf(label.size.x * 1.5 / 2.0))
	assert_float(label.position.y).is_equal(-ceilf(label.size.y * 1.5))
