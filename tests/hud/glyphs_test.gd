extends GdUnitTestSuite

func test_width() -> void:
	assert_int(Glyphs.width("")).is_equal(0)
	assert_int(Glyphs.width("7")).is_equal(3)
	assert_int(Glyphs.width("999")).is_equal(11)

func test_three_digits_fit_the_slot_corner() -> void:
	assert_bool(15 - Glyphs.width("999") >= 1).is_true()

func test_order_has_the_hint_letters() -> void:
	assert_str(Glyphs.ORDER).is_equal("0123456789EABDLSWXYsc✕○△CFGHIJKMNOPQRTUVZabdefghijklmnopqrtuvwxyz-=[]\\;',./`+*□↑↓←→—!:")

func test_bang_is_the_last_glyph() -> void:
	assert_int(Glyphs.ORDER.find("!")).is_equal(84)
	assert_int(Glyphs.width("! —")).is_equal(11)

func test_bang_pixels() -> void:
	var img := Glyphs.SHEET.get_image()
	var pattern := [".#.", ".#.", ".#.", "...", ".#."]
	for y in 5:
		for x in 3:
			assert_bool(img.get_pixel(336 + x, y).a > 0.5).is_equal(pattern[y][x] == "#")

func test_esc_width() -> void:
	assert_int(Glyphs.width("Esc")).is_equal(11)

func test_sheet_width_matches_order() -> void:
	assert_int(Glyphs.SHEET.get_width()).is_equal(4 * Glyphs.ORDER.length())

func _drawable(label: String) -> bool:
	for c in label:
		if c != " " and Glyphs.ORDER.find(c) < 0:
			return false
	return true

func _key(code: int, location: KeyLocation = KEY_LOCATION_UNSPECIFIED) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code as Key
	e.location = location
	return e

# The printable keys on the physical (US) layout, and every key with a fixed short name.
func test_every_key_label_is_drawable() -> void:
	var codes: Array[int] = [KEY_APOSTROPHE, KEY_COMMA, KEY_MINUS, KEY_PERIOD, KEY_SLASH, KEY_SEMICOLON, KEY_EQUAL,
		KEY_BRACKETLEFT, KEY_BACKSLASH, KEY_BRACKETRIGHT, KEY_QUOTELEFT, KEY_BACKSPACE, KEY_SHIFT, KEY_CTRL, KEY_ALT,
		KEY_PAGEUP, KEY_PAGEDOWN, KEY_INSERT, KEY_DELETE, KEY_HOME, KEY_END, KEY_SPACE, KEY_TAB, KEY_CAPSLOCK,
		KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_KP_MULTIPLY, KEY_KP_DIVIDE,
		KEY_KP_SUBTRACT, KEY_KP_ADD, KEY_KP_PERIOD]
	for c in range(KEY_0, KEY_9 + 1):
		codes.append(c)
	for c in range(KEY_A, KEY_Z + 1):
		codes.append(c)
	for c in 10:
		codes.append(KEY_KP_0 + c)
	for c in 12:
		codes.append(KEY_F1 + c)
	for code in codes:
		for location: KeyLocation in [KEY_LOCATION_UNSPECIFIED, KEY_LOCATION_LEFT, KEY_LOCATION_RIGHT]:
			var label := KeyLabels.label(_key(code, location))
			assert_bool(_drawable(label)).override_failure_message("%d draws as %s" % [code, label]).is_true()

func test_colon_pixels() -> void:
	var i := Glyphs.ORDER.find(":")
	assert_int(i).is_greater_equal(0)
	var img := Glyphs.SHEET.get_image()
	var pattern := ["...", ".#.", "...", ".#.", "..."]
	for y in 5:
		for x in 3:
			assert_bool(img.get_pixel(4 * i + x, y).a > 0.5).is_equal(pattern[y][x] == "#")

func test_time_width() -> void:
	assert_int(Glyphs.width("21:00")).is_equal(19)
