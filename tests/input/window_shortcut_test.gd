extends GdUnitTestSuite
## The fixed fullscreen shortcut's rules: Cmd+Enter on macOS, Alt+Enter elsewhere, never repeated, its release swallowed.

const R := WindowShortcut.Result

func _key(physical: Key, pressed: bool, alt := false, meta := false, echo := false) -> InputEventKey:
	var k := InputEventKey.new()
	k.physical_keycode = physical
	k.keycode = physical
	k.key_label = physical
	k.pressed = pressed
	k.alt_pressed = alt
	k.meta_pressed = meta
	k.echo = echo
	return k

func test_alt_enter_toggles_off_mac() -> void:
	assert_int(WindowShortcut.new(false).read(_key(KEY_ENTER, true, true))).is_equal(R.TOGGLE)

func test_keypad_enter_with_alt_toggles_off_mac() -> void:
	assert_int(WindowShortcut.new(false).read(_key(KEY_KP_ENTER, true, true))).is_equal(R.TOGGLE)

func test_cmd_enter_toggles_on_mac() -> void:
	assert_int(WindowShortcut.new(true).read(_key(KEY_ENTER, true, false, true))).is_equal(R.TOGGLE)

func test_extra_modifiers_still_toggle() -> void:
	var k := _key(KEY_ENTER, true, true)
	k.shift_pressed = true
	assert_int(WindowShortcut.new(false).read(k)).is_equal(R.TOGGLE)

func test_the_other_platforms_modifier_does_nothing() -> void:
	assert_int(WindowShortcut.new(false).read(_key(KEY_ENTER, true, false, true))).is_equal(R.NONE)
	assert_int(WindowShortcut.new(true).read(_key(KEY_ENTER, true, true))).is_equal(R.NONE)

func test_plain_enter_is_none() -> void:
	var s := WindowShortcut.new(false)
	assert_int(s.read(_key(KEY_ENTER, true))).is_equal(R.NONE)
	assert_int(s.read(_key(KEY_ENTER, false))).is_equal(R.NONE)

func test_alt_alone_is_none() -> void:
	var s := WindowShortcut.new(false)
	assert_int(s.read(_key(KEY_ALT, true, true))).is_equal(R.NONE)
	assert_int(s.read(_key(KEY_ALT, false))).is_equal(R.NONE)

func test_an_echo_is_swallowed_not_toggled() -> void:
	var s := WindowShortcut.new(false)
	assert_int(s.read(_key(KEY_ENTER, true, true))).is_equal(R.TOGGLE)
	assert_int(s.read(_key(KEY_ENTER, true, true, false, true))).is_equal(R.SWALLOW)

func test_the_release_after_a_toggle_is_swallowed_even_with_alt_up() -> void:
	var s := WindowShortcut.new(false)
	assert_int(s.read(_key(KEY_ENTER, true, true))).is_equal(R.TOGGLE)
	assert_int(s.read(_key(KEY_ALT, false))).is_equal(R.NONE)
	assert_int(s.read(_key(KEY_ENTER, false))).is_equal(R.SWALLOW)
	assert_int(s.read(_key(KEY_ENTER, true))).is_equal(R.NONE)
	assert_int(s.read(_key(KEY_ENTER, false))).is_equal(R.NONE)

func test_modifier_keys() -> void:
	assert_int(WindowShortcut.modifier_key(true)).is_equal(KEY_META)
	assert_int(WindowShortcut.modifier_key(false)).is_equal(KEY_ALT)

func test_blank_matches_no_action() -> void:
	var k := _key(KEY_ENTER, true, true)
	WindowShortcut.blank(k)
	assert_bool(k.is_action_pressed(&"menu_accept")).is_false()
	assert_int(k.physical_keycode).is_equal(KEY_NONE)
	assert_int(k.keycode).is_equal(KEY_NONE)
	assert_int(k.key_label).is_equal(KEY_NONE)
	assert_int(k.unicode).is_equal(0)

func test_an_echo_after_alt_is_let_go_is_still_swallowed() -> void:
	var s := WindowShortcut.new(false)
	s.read(_key(KEY_ENTER, true, true))
	assert_int(s.read(_key(KEY_ENTER, true, false, false, true))).is_equal(R.SWALLOW)
	assert_int(s.read(_key(KEY_ENTER, false))).is_equal(R.SWALLOW)
	assert_int(s.read(_key(KEY_ENTER, true))).is_equal(R.NONE)
