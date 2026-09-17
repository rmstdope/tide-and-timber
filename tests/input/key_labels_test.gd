extends GdUnitTestSuite
## A key becomes a short label that fits a slot at the 320x180 base.

func _key(code: Key, location: KeyLocation = KEY_LOCATION_UNSPECIFIED) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.location = location
	return e

func _label(code: Key, location: KeyLocation = KEY_LOCATION_UNSPECIFIED) -> String:
	return KeyLabels.label(_key(code, location))

func test_long_names_are_short() -> void:
	assert_str(_label(KEY_BACKSPACE)).is_equal("Bksp")
	assert_str(_label(KEY_SHIFT, KEY_LOCATION_RIGHT)).is_equal("RShift")
	assert_str(_label(KEY_SHIFT, KEY_LOCATION_LEFT)).is_equal("LShift")
	assert_str(_label(KEY_SHIFT)).is_equal("Shift")
	assert_str(_label(KEY_CTRL, KEY_LOCATION_RIGHT)).is_equal("RCtrl")
	assert_str(_label(KEY_CTRL, KEY_LOCATION_LEFT)).is_equal("LCtrl")
	assert_str(_label(KEY_CTRL)).is_equal("Ctrl")
	assert_str(_label(KEY_ALT, KEY_LOCATION_RIGHT)).is_equal("RAlt")
	assert_str(_label(KEY_ALT, KEY_LOCATION_LEFT)).is_equal("LAlt")
	assert_str(_label(KEY_ALT)).is_equal("Alt")
	for n in 10:
		assert_str(_label((KEY_KP_0 + n) as Key)).is_equal("Num %d" % n)
	assert_str(_label(KEY_PAGEUP)).is_equal("PgUp")
	assert_str(_label(KEY_PAGEDOWN)).is_equal("PgDn")
	assert_str(_label(KEY_INSERT)).is_equal("Ins")
	assert_str(_label(KEY_DELETE)).is_equal("Del")
	assert_str(_label(KEY_HOME)).is_equal("Home")
	assert_str(_label(KEY_END)).is_equal("End")
	assert_str(_label(KEY_SPACE)).is_equal("Space")
	assert_str(_label(KEY_TAB)).is_equal("Tab")
	assert_str(_label(KEY_CAPSLOCK)).is_equal("Caps")
	assert_str(_label(KEY_ENTER)).is_equal("Enter")
	assert_str(_label(KEY_KP_ENTER)).is_equal("Enter")
	assert_str(_label(KEY_ESCAPE)).is_equal("Esc")
	assert_str(_label(KEY_KP_MULTIPLY)).is_equal("Num *")
	assert_str(_label(KEY_KP_DIVIDE)).is_equal("Num /")
	assert_str(_label(KEY_KP_SUBTRACT)).is_equal("Num -")
	assert_str(_label(KEY_KP_ADD)).is_equal("Num +")
	assert_str(_label(KEY_KP_PERIOD)).is_equal("Num .")
	for n in 12:
		assert_str(_label((KEY_F1 + n) as Key)).is_equal("F%d" % (n + 1))

func test_letters_and_symbols_print_as_on_the_key() -> void:
	assert_str(_label(KEY_Q)).is_equal("Q")
	assert_str(_label(KEY_1)).is_equal("1")
	assert_str(_label(KEY_MINUS)).is_equal("-")
	assert_str(_label(KEY_BRACKETLEFT)).is_equal("[")

func test_a_printed_character_beyond_ascii_shows_the_us_character() -> void:
	assert_str(KeyLabels.printed_label(KEY_BRACKETLEFT, 229)).is_equal("[")
	assert_str(KeyLabels.printed_label(KEY_Q, KEY_A)).is_equal("A")
	assert_str(KeyLabels.printed_label(KEY_Q, 0)).is_equal("Q")

func test_arrows_are_arrows() -> void:
	assert_str(_label(KEY_UP)).is_equal("↑")
	assert_str(_label(KEY_DOWN)).is_equal("↓")
	assert_str(_label(KEY_LEFT)).is_equal("←")
	assert_str(_label(KEY_RIGHT)).is_equal("→")
