extends GdUnitTestSuite
## At larger Text size the morning card's words grow; the card widens, then its lines wrap and it grows taller.

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var layer: CanvasLayer
var card: MorningCardView

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())
	layer = CanvasLayer.new()
	card = MorningCardView.new()
	layer.add_child(card)
	get_tree().root.add_child(layer)

func after_test() -> void:
	layer.free()
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())
	InputDevice.reset()

func _step(setting: DisplayPrefs.Setting, steps: int) -> void:
	for i in steps:
		Display.prefs.step(setting, 1)
	await await_idle_frame()

func _show(lines: Array[String]) -> void:
	card.show_lines(lines)

func test_largest_text_widens_the_card() -> void:
	await _step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	_show(["DAY 3", NightLoss.NOTHING])
	assert_float(card.size.x).is_equal(304.0)
	assert_float(card.position.x).is_equal(8.0)
	for l in card.labels:
		assert_that(l.scale).is_equal(Vector2(2, 2))

func test_largest_text_grows_the_card_taller() -> void:
	await _step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	_show(["DAY 3", NightLoss.NOTHING])
	assert_float(card.size.y).is_equal(float(MorningCardView.height_for(2, 2.0)))

func test_a_line_too_long_for_the_screen_wraps() -> void:
	await _step(DisplayPrefs.Setting.UI_SIZE, 2)
	await _step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	_show(["DAY 3", NightLoss.NOTHING])
	var ui := UiScale.current(Display.prefs, get_tree().root)
	assert_float(card.size.x).is_equal(TextScale.fit_width(160, 1000, ui))
	# the layer grows the card about the screen's centre by ui
	assert_float(160.0 - card.size.x * ui / 2.0).is_greater_equal(0.0)
	assert_float(160.0 + card.size.x * ui / 2.0).is_less_equal(320.0)
	var rel := TextScale.relative(Display.prefs, get_tree().root)
	assert_float(card.size.y).is_greater(float(MorningCardView.height_for(2, rel)))

func test_text_normal_is_todays_card() -> void:
	_show(["DAY 3", NightLoss.NOTHING])
	assert_float(card.size.x).is_equal(160.0)
	assert_float(card.size.y).is_equal(float(MorningCardView.height_for(2)))
	assert_that(card.labels[0].scale).is_equal(Vector2.ONE)
	assert_float(card.labels[0].position.y).is_equal(6.0)
	assert_float(card.labels[1].position.y).is_equal(18.0)

func test_a_size_change_while_the_card_shows_relays_it_out() -> void:
	_show(["DAY 3", NightLoss.NOTHING])
	var before := card.size.x
	await _step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	assert_float(card.size.x).is_not_equal(before)
