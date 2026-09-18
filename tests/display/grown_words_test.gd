extends GdUnitTestSuite
## GrownWords: a holder a container lays out, with one Label inside whose words grow by Text size.

const S := DisplayPrefs.Setting
const FONT := "res://assets/fonts/PressStart2P-Regular.ttf"

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
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	InputDevice.reset()
	Display.use_prefs(DisplayPrefs.new())

func _holder(t: String, normal: Vector2) -> GrownWords:
	var g := GrownWords.new()
	g.normal_size = normal
	var l := Label.new()
	l.name = "Words"
	l.text = t
	l.add_theme_font_size_override("font_size", 8)
	g.add_child(l)
	add_child(auto_free(g))
	return g

func test_normal_text_is_the_normal_cell() -> void:
	var g := _holder("Largest", Vector2(64, 12))
	assert_vector(g.get_combined_minimum_size()).is_equal(Vector2(64, 12))
	assert_float(g.rel).is_equal(1.0)
	assert_vector(g.words().scale).is_equal(Vector2.ONE)
	assert_bool(g.wrapped).is_false()
	assert_vector(_holder("UI size", Vector2(0, 12)).get_combined_minimum_size()).is_equal(Vector2(56, 12))
	assert_vector(_holder("New Game", Vector2.ZERO).get_combined_minimum_size()).is_equal(Vector2(64, 8))

func test_large_text_grows_words_and_cell() -> void:
	Display.prefs.step(S.TEXT_SIZE, 1)
	var g := _holder("Largest", Vector2(64, 12))
	assert_vector(g.get_combined_minimum_size()).is_equal(Vector2(96, 16))
	assert_vector(g.words().scale).is_equal(Vector2(1.5, 1.5))
	assert_vector(_holder("UI size", Vector2(0, 12)).get_combined_minimum_size()).is_equal(Vector2(84, 16))
	assert_vector(_holder("◀", Vector2(12, 12)).get_combined_minimum_size()).is_equal(Vector2(18, 16))
	assert_vector(_holder("New Game", Vector2(0, 14)).get_combined_minimum_size()).is_equal(Vector2(96, 18))

func test_largest_text() -> void:
	Display.prefs.step(S.TEXT_SIZE, 2)
	assert_vector(_holder("◀", Vector2(12, 12)).get_combined_minimum_size()).is_equal(Vector2(24, 20))
	assert_vector(_holder("UI size", Vector2(0, 12)).get_combined_minimum_size()).is_equal(Vector2(112, 20))

func test_text_setter_refits() -> void:
	Display.prefs.step(S.TEXT_SIZE, 1)
	var g := _holder("Quit", Vector2.ZERO)
	assert_vector(g.get_combined_minimum_size()).is_equal(Vector2(48, 12))
	g.text = "Settings"
	assert_vector(g.get_combined_minimum_size()).is_equal(Vector2(96, 12))
	assert_str(g.words().text).is_equal("Settings")

func test_wraps_past_max_width_and_unwraps() -> void:
	Display.prefs.step(S.TEXT_SIZE, 2)
	var g := _holder("This save couldn't be opened", Vector2.ZERO)
	g.max_width = 312
	assert_bool(g.wrapped).is_true()
	assert_vector(g.get_combined_minimum_size()).is_equal(Vector2(312, 38))
	assert_int(g.words().autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
	g.max_width = INF
	assert_bool(g.wrapped).is_false()
	assert_vector(g.get_combined_minimum_size()).is_equal(Vector2(448, 16))
	assert_int(g.words().autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)

func test_words_fill_the_holder_at_its_scale() -> void:
	Display.prefs.step(S.TEXT_SIZE, 1)
	var g := _holder("Largest", Vector2(64, 12))
	g.size = Vector2(100, 16)
	assert_vector(g.words().position).is_equal(Vector2.ZERO)
	assert_float(g.words().size.x).is_equal_approx(66.667, 0.01)
	assert_float(g.words().size.y).is_equal_approx(10.667, 0.01)

func test_refits_on_text_size_changed() -> void:
	var g := _holder("Largest", Vector2(64, 12))
	Display.prefs.step(S.TEXT_SIZE, 1)
	assert_vector(g.get_combined_minimum_size()).is_equal(Vector2(96, 16))
	Display.use_prefs(DisplayPrefs.new())
	assert_vector(g.get_combined_minimum_size()).is_equal(Vector2(64, 12))
	assert_vector(g.words().scale).is_equal(Vector2.ONE)

func test_line_count() -> void:
	var font := load(FONT) as Font
	assert_int(GrownWords.line_count("Quit to title", 64, font, 8)).is_equal(2)
	assert_int(GrownWords.line_count("Quit to title", 104, font, 8)).is_equal(1)
