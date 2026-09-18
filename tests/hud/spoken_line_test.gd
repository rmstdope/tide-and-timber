extends GdUnitTestSuite

## The spoken band as the scenes place it: 296 wide, centred, its bottom 14 above the picture's.
const BAND := Rect2((Screen.WIDTH - 296) / 2, Screen.HEIGHT - 30, 296, 16)
const BOTTOM := Screen.HEIGHT - 14
## The width a line narrows to at UI Largest (2x): the picture less SCREEN_MARGIN each side, halved.
const LARGEST_W := floorf((Screen.WIDTH - 2.0 * SpokenLine.SCREEN_MARGIN) / 2.0)
## A band hugs its words, so UI size alone never reaches the cap for these lines: the band's own
## narrowing is exercised at this explicit scale, past any UI size.
const NARROW := 4.0

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
	line.position = BAND.position
	line.size = BAND.size
	var band := ColorRect.new()
	band.name = "Band"
	band.size = Vector2(296, 16)
	line.add_child(band)
	if text_left > 0:
		var journal := ColorRect.new()     # the "any other child" the dawn line carries, as autosave.tscn
		journal.name = "Journal"
		journal.position.x = 4
		journal.size = Vector2(12, 12)
		line.add_child(journal)
	var text := _label("Text", 296 - text_left)
	text.position.x = text_left
	line.add_child(text)
	add_child(line)
	auto_free(line)
	return line

func _bare_line() -> Label:
	var l := _label("BlackLine", Screen.WIDTH)
	l.set_script(preload("res://src/hud/spoken_line.gd"))
	l.set("grows_up", false)
	l.position = Vector2(0, Screen.CENTRE.y - 8)
	add_child(l)
	auto_free(l)
	return l

## The line's band reaches `m` past its words on both sides.
func _assert_margins(line: SpokenLine, m: float) -> void:
	var text := line.get_node("Text") as Label
	assert_float(text.position.x).is_equal(m)
	assert_float(line.size.x - text.position.x - text.size.x * text.scale.x).is_equal_approx(m, 0.001)

func _assert_centred(c: Control, w: float) -> void:
	assert_float(c.position.x).is_equal(roundf((Screen.WIDTH - w) / 2.0))

func _cap(s: float) -> float:
	return floorf((Screen.WIDTH - 2.0 * SpokenLine.SCREEN_MARGIN) / s)

func test_wanted_width_is_the_words_plus_a_margin_each_side() -> void:
	assert_float(SpokenLine.wanted_width(100.0, 0.0)).is_equal(100.0 + 2.0 * SpokenLine.BAND_MARGIN)
	assert_float(SpokenLine.wanted_width(100.0, 4.0)).is_equal(100.0 + 2.0 * SpokenLine.BAND_MARGIN)
	assert_float(SpokenLine.wanted_width(100.0, 16.0)).is_equal(132.0)
	assert_float(SpokenLine.wanted_width(0.0, 0.0)).is_equal(2.0 * SpokenLine.BAND_MARGIN)

func test_a_line_is_centred_on_the_picture() -> void:
	var line := _band_line()
	line.say("That should see me through the night.")
	line.fit(1.0)
	var text := line.get_node("Text") as Label
	assert_float(line.position.y).is_equal(BAND.position.y)
	assert_float(line.size.y).is_equal(16.0)
	_assert_centred(line, line.size.x)
	_assert_margins(line, SpokenLine.BAND_MARGIN)
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_vector((line.get_node("Band") as Control).size).is_equal(line.size)

func test_a_long_line_hugs_and_keeps_its_bottom_edge() -> void:
	var line := _band_line()
	line.say("That should see me through the night.")
	line.fit(2.0)
	var text := line.get_node("Text") as Label
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_int(text.get_line_count()).is_equal(1)
	assert_float(line.size.y).is_equal(16.0)
	assert_float(line.position.y + line.size.y).is_equal(BOTTOM)
	assert_vector((line.get_node("Band") as Control).size).is_equal(line.size)
	_assert_margins(line, SpokenLine.BAND_MARGIN)

func test_a_longer_line_gets_a_wider_band() -> void:
	var short := _band_line()
	short.say("Driftwood.")
	short.fit(1.0)
	var long := _band_line()
	long.say("That should see me through the night.")
	long.fit(1.0)
	assert_float(long.size.x).is_greater(short.size.x)
	_assert_margins(short, SpokenLine.BAND_MARGIN)
	_assert_margins(long, SpokenLine.BAND_MARGIN)
	_assert_centred(short, short.size.x)
	_assert_centred(long, long.size.x)

func test_the_dawn_line_keeps_its_journal_inside_the_band() -> void:
	var line := _band_line(16)
	line.say("Another morning. Still here.")
	line.fit(1.0)
	var journal := line.get_node("Journal") as Control
	assert_float(line.size.x).is_less(296.0)
	assert_float(journal.position.x).is_equal(4.0)
	assert_float(journal.get_rect().end.x).is_less_equal(line.size.x)
	_assert_margins(line, 16.0)

func test_narrowed_band_wraps_and_grows_up() -> void:
	var line := _band_line()
	line.say("That should see me through the night.")
	line.fit(NARROW)
	var text := line.get_node("Text") as Label
	assert_float(line.size.x).is_equal(_cap(NARROW))
	_assert_centred(line, line.size.x)
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
	assert_float(text.size.x).is_equal(line.size.x - 2.0 * SpokenLine.BAND_MARGIN)
	assert_int(text.get_line_count()).is_greater_equal(2)
	assert_float(line.position.y + line.size.y).is_equal(BOTTOM)
	assert_vector((line.get_node("Band") as Control).size).is_equal(line.size)
	assert_float(text.get_minimum_size().y).is_less_equal(text.size.y)

func test_centred_line_grows_about_its_centre() -> void:
	var l := _bare_line()
	(l as Object).call("say", "So cold... just... rest a moment...")
	(l as Object).call("fit", 2.0)
	assert_float(l.size.x).is_less(Screen.WIDTH)  # the width it has in its scene
	_assert_centred(l, l.size.x)
	assert_float(l.position.y + l.size.y / 2.0).is_equal_approx(Screen.CENTRE.y, 0.5)

func test_text_left_is_kept() -> void:
	var line := _band_line(16)
	line.say("Another morning. Still here.")
	line.fit(2.0)
	var text := line.get_node("Text") as Control
	assert_float(text.position.x).is_equal(16.0)
	assert_float(text.size.x).is_equal(line.size.x - 2.0 * 16.0)

func test_refits_on_display_changed() -> void:
	# UI size alone never reaches the cap for a hugged band; UI and Text together do
	get_tree().root.size = Vector2i(1280, 720)
	var line := _band_line()
	line.say("That should see me through the night.")
	var text := line.get_node("Text") as Label
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	var capped := line.size.x
	assert_float(capped).is_equal(_cap(UiScale.current(Display.prefs, get_tree().root)))
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
	Display.use_prefs(DisplayPrefs.new())
	assert_float(line.size.x).is_less(capped)
	assert_float(line.size.y).is_equal(16.0)
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)

func test_refits_on_window_resize() -> void:
	# Large is 1.5 at k = 2 and rounds up to 2 at k = 1, which moves the cap
	get_tree().root.size = Vector2i(1280, 720)
	var line := _band_line()
	line.say("That should see me through the night.")
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	var first := line.size.x
	assert_float(first).is_equal(_cap(UiScale.current(Display.prefs, get_tree().root)))
	get_tree().root.size = Screen.MIN_WINDOW
	assert_float(line.size.x).is_equal(_cap(UiScale.current(Display.prefs, get_tree().root)))
	assert_float(line.size.x).is_not_equal(first)

func test_text_large_widens_without_wrapping() -> void:
	var line := _band_line()
	line.say("The tide is turning again.")
	line.fit(1.0, 1.5)
	var text := line.get_node("Text") as Label
	var step := text.get_line_height() + text.get_theme_constant(&"line_spacing")
	_assert_margins(line, SpokenLine.BAND_MARGIN)
	_assert_centred(line, line.size.x)
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_vector(text.scale).is_equal(Vector2(1.5, 1.5))
	assert_float(text.size.x).is_equal((line.size.x - 2.0 * SpokenLine.BAND_MARGIN) / 1.5)
	assert_float(line.size.y).is_equal(16.0 + ceilf(step * 1.5) - step)
	assert_float(line.position.y + line.size.y).is_equal(BOTTOM)
	assert_vector((line.get_node("Band") as Control).size).is_equal(line.size)

func test_text_large_widens_a_long_line_without_wrapping() -> void:
	var normal := _band_line()
	normal.say("That should see me through the night.")
	normal.fit(1.0)
	var line := _band_line()
	line.say("That should see me through the night.")
	line.fit(1.0, 1.5)
	var text := line.get_node("Text") as Label
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_int(text.get_line_count()).is_equal(1)
	_assert_margins(line, SpokenLine.BAND_MARGIN)
	assert_float(line.position.y + line.size.y).is_equal(BOTTOM)
	assert_float(line.size.x).is_greater(normal.size.x)

func test_largest_ui_and_text_wrap_within_the_screen() -> void:
	var line := _band_line()
	line.say("That should see me through the night.")
	line.fit(2.0, 2.0)
	var text := line.get_node("Text") as Label
	assert_float(line.size.x).is_equal(LARGEST_W)
	_assert_centred(line, LARGEST_W)
	assert_float(text.size.x).is_equal((LARGEST_W - 2.0 * SpokenLine.BAND_MARGIN) / 2.0)
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
	assert_int(text.get_line_count()).is_greater_equal(2)
	assert_float(line.position.y + line.size.y).is_equal(BOTTOM)
	assert_float(line.size.y).is_greater(16.0)

func test_a_short_line_still_hugs_at_text_large() -> void:
	var line := _band_line()
	line.say("Rest now.")
	line.fit(1.0, 1.5)
	assert_float(line.size.x).is_less(296.0)
	_assert_margins(line, SpokenLine.BAND_MARGIN)
	_assert_centred(line, line.size.x)
	assert_int((line.get_node("Text") as Label).autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)

func test_text_left_is_kept_when_words_grow() -> void:
	var line := _band_line(16)
	line.say("The tide is turning again.")
	line.fit(1.0, 1.5)
	var text := line.get_node("Text") as Control
	assert_float(text.position.x).is_equal(16.0)
	assert_float(text.size.x * 1.5).is_equal_approx(line.size.x - 2.0 * 16.0, 0.001)

func test_bare_line_grows_about_its_centre() -> void:
	var l := _bare_line()
	(l as Object).call("say", "So cold... just... rest a moment...")
	(l as Object).call("fit", 1.0, 2.0)
	assert_vector(l.scale).is_equal(Vector2(2, 2))
	assert_float(l.size.x * 2.0).is_less(Screen.WIDTH)  # the width it has in its scene
	_assert_centred(l, l.size.x * 2.0)
	assert_float(l.position.y + l.size.y * 2.0 / 2.0).is_equal_approx(Screen.CENTRE.y, 0.5)

func test_refits_on_text_size_changed() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	var line := _band_line()
	line.say("The tide is turning again.")
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)
	var large := line.size.x
	_assert_margins(line, SpokenLine.BAND_MARGIN)
	Display.use_prefs(DisplayPrefs.new())
	assert_float(line.size.x).is_less(large)
	_assert_margins(line, SpokenLine.BAND_MARGIN)
	assert_float(line.size.y).is_equal(16.0)
	assert_vector((line.get_node("Text") as Label).scale).is_equal(Vector2.ONE)

func test_text_left_is_kept_when_the_line_narrows() -> void:
	var line := _band_line(16)
	line.say("Another morning. Still here.")
	line.fit(2.0, 2.0)
	var text := line.get_node("Text") as Control
	assert_float(line.size.x).is_equal(LARGEST_W)
	assert_float(text.position.x).is_equal(16.0)
	assert_float(text.size.x).is_equal((LARGEST_W - 2.0 * 16.0) / 2.0)

func test_a_short_line_hugs_its_words() -> void:
	var line := _band_line()
	line.say("Driftwood.")
	line.fit(1.0)
	var text := line.get_node("Text") as Label
	assert_float(line.size.x).is_less(296.0)
	assert_float(text.position.x).is_equal(SpokenLine.BAND_MARGIN)
	assert_float(line.size.x - text.position.x - text.size.x).is_equal(SpokenLine.BAND_MARGIN)
	assert_int(text.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	assert_vector((line.get_node("Band") as Control).size).is_equal(line.size)
	assert_float(line.position.x).is_equal(roundf((Screen.WIDTH - line.size.x) / 2.0))
	assert_float(line.position.y + line.size.y).is_equal(BOTTOM)
