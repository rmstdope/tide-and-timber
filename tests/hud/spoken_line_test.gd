extends GdUnitTestSuite

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

func _label(n: String, w: float) -> Label:
	var l := Label.new()
	l.name = n
	l.size = Vector2(w, 16)
	l.add_theme_font_size_override(&"font_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

func _band_line(text_left := 0.0) -> SpokenLine:
	var line := SpokenLine.new()
	line.position = Vector2(12, 150)
	line.size = Vector2(296, 16)
	var band := ColorRect.new()
	band.name = "Band"
	band.size = Vector2(296, 16)
	line.add_child(band)
	var text := _label("Text", 296 - text_left)
	text.position.x = text_left
	line.add_child(text)
	add_child(line)
	auto_free(line)
	return line

func _bare_line() -> Label:
	var l := _label("BlackLine", 320)
	l.set_script(preload("res://src/hud/spoken_line.gd"))
	l.set("grows_up", false)
	l.position = Vector2(0, 82)
	add_child(l)
	auto_free(l)
	return l

func test_width_at_keeps_normal_width_while_it_fits() -> void:
	assert_float(SpokenLine.width_at(296, 1.0)).is_equal(296.0)
	assert_float(SpokenLine.width_at(320, 1.0)).is_equal(320.0)
	assert_float(SpokenLine.width_at(296, 1.5)).is_equal(208.0)
	assert_float(SpokenLine.width_at(296, 2.0)).is_equal(156.0)
	assert_float(SpokenLine.width_at(296, 5.0 / 3.0)).is_equal(187.0)

func test_normal_is_unchanged() -> void:
	var line := _band_line()
	line.say("That should see me through the night.")
	line.fit(1.0)
	var text := line.get_node("Text") as Label
	assert_vector(line.position).is_equal(Vector2(12, 150))
	assert_vector(line.size).is_equal(Vector2(296, 16))
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_vector((line.get_node("Band") as Control).size).is_equal(Vector2(296, 16))

func test_largest_wraps_and_grows_up() -> void:
	var line := _band_line()
	line.say("That should see me through the night.")
	line.fit(2.0)
	var text := line.get_node("Text") as Label
	assert_float(line.size.x).is_equal(156.0)
	assert_float(line.position.x).is_equal(82.0)
	assert_int(text.get_line_count()).is_greater_equal(2)
	assert_float(line.position.y + line.size.y).is_equal(166.0)
	assert_vector((line.get_node("Band") as Control).size).is_equal(line.size)
	assert_float(text.get_minimum_size().y).is_less_equal(text.size.y)

func test_centred_line_grows_about_its_centre() -> void:
	var l := _bare_line()
	(l as Object).call("say", "So cold... just... rest a moment...")
	(l as Object).call("fit", 2.0)
	assert_float(l.size.x).is_equal(156.0)
	assert_float(l.position.y + l.size.y / 2.0).is_equal_approx(90.0, 0.5)

func test_text_left_is_kept() -> void:
	var line := _band_line(16)
	line.say("Another morning. Still here.")
	line.fit(2.0)
	assert_float((line.get_node("Text") as Control).size.x).is_equal(line.size.x - 16)

func test_refits_on_display_changed() -> void:
	get_tree().root.size = Vector2i(640, 360)
	var line := _band_line()
	line.say("That should see me through the night.")
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	assert_float(line.size.x).is_equal(156.0)
	Display.use_prefs(DisplayPrefs.new())
	assert_float(line.size.x).is_equal(296.0)
	assert_float(line.size.y).is_equal(16.0)

func test_refits_on_window_resize() -> void:
	get_tree().root.size = Vector2i(640, 360)
	var line := _band_line()
	line.say("That should see me through the night.")
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	assert_float(line.size.x).is_equal(208.0)
	get_tree().root.size = Vector2i(320, 180)
	assert_float(line.size.x).is_equal(156.0)

func test_text_large_widens_without_wrapping() -> void:
	var line := _band_line()
	line.say("The tide is turning again.")
	line.fit(1.0, 1.5)
	var text := line.get_node("Text") as Label
	var step := text.get_line_height() + text.get_theme_constant(&"line_spacing")
	assert_float(line.size.x).is_equal(312.0)
	assert_float(line.position.x).is_equal(4.0)
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_vector(text.scale).is_equal(Vector2(1.5, 1.5))
	assert_float(text.size.x).is_equal(208.0)
	assert_float(line.size.y).is_equal(16.0 + ceilf(step * 1.5) - step)
	assert_float(line.position.y + line.size.y).is_equal(166.0)
	assert_vector((line.get_node("Band") as Control).size).is_equal(line.size)

func test_text_large_long_line_wraps_at_the_margin() -> void:
	var line := _band_line()
	line.say("That should see me through the night.")
	line.fit(1.0, 1.5)
	var text := line.get_node("Text") as Label
	assert_float(line.size.x).is_equal(312.0)
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
	assert_int(text.get_line_count()).is_greater_equal(2)
	assert_float(line.position.y + line.size.y).is_equal(166.0)
	assert_float(text.get_minimum_size().y).is_less_equal(text.size.y)

func test_largest_ui_and_text_wrap_within_the_screen() -> void:
	var line := _band_line()
	line.say("That should see me through the night.")
	line.fit(2.0, 2.0)
	var text := line.get_node("Text") as Label
	assert_float(line.size.x).is_equal(156.0)
	assert_float(line.position.x).is_equal(82.0)
	assert_float(text.size.x).is_equal(78.0)
	assert_int(text.get_line_count()).is_greater_equal(2)
	assert_float(line.position.y + line.size.y).is_equal(166.0)
	assert_float(line.size.y).is_greater(16.0)

func test_short_line_keeps_normal_width_at_text_large() -> void:
	var line := _band_line()
	line.say("Rest now.")
	line.fit(1.0, 1.5)
	assert_float(line.size.x).is_equal(296.0)
	assert_float(line.position.x).is_equal(12.0)
	assert_int((line.get_node("Text") as Label).autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)

func test_text_left_is_kept_when_words_grow() -> void:
	var line := _band_line(16)
	line.say("The tide is turning again.")
	line.fit(1.0, 1.5)
	var text := line.get_node("Text") as Control
	assert_float(text.position.x).is_equal(16.0)
	assert_float(text.size.x * 1.5).is_equal_approx(line.size.x - 16.0, 0.001)

func test_bare_line_grows_about_its_centre() -> void:
	var l := _bare_line()
	(l as Object).call("say", "So cold... just... rest a moment...")
	(l as Object).call("fit", 1.0, 2.0)
	assert_vector(l.scale).is_equal(Vector2(2, 2))
	assert_float(l.size.x * 2.0).is_equal(312.0)
	assert_float(l.position.x).is_equal(4.0)
	assert_float(l.position.y + l.size.y * 2.0 / 2.0).is_equal_approx(90.0, 0.5)

func test_refits_on_text_size_changed() -> void:
	get_tree().root.size = Vector2i(640, 360)
	var line := _band_line()
	line.say("The tide is turning again.")
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	assert_float(line.size.x).is_equal(312.0)
	Display.use_prefs(DisplayPrefs.new())
	assert_float(line.size.x).is_equal(296.0)
	assert_float(line.size.y).is_equal(16.0)
	assert_vector((line.get_node("Text") as Label).scale).is_equal(Vector2.ONE)
