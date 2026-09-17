extends GdUnitTestSuite
## F1-F4 as debug shortcuts: by physical key, pressed only, never a repeat, nothing else.

func _key(code: Key, pressed := true, echo := false, physical := true) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	if physical:
		e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	return e

func test_f1_to_f4_are_the_four_shortcuts() -> void:
	assert_int(DebugShortcut.of(_key(KEY_F1))).is_equal(DebugShortcut.Name.READOUT)
	assert_int(DebugShortcut.of(_key(KEY_F2))).is_equal(DebugShortcut.Name.COLLISION_AREAS)
	assert_int(DebugShortcut.of(_key(KEY_F3))).is_equal(DebugShortcut.Name.SPEED)
	assert_int(DebugShortcut.of(_key(KEY_F4))).is_equal(DebugShortcut.Name.WALK_THROUGH)

func test_other_keys_are_none() -> void:
	for k: Key in [KEY_F5, KEY_1, KEY_E, KEY_ESCAPE]:
		assert_int(DebugShortcut.of(_key(k))).is_equal(DebugShortcut.Name.NONE)

func test_release_and_repeat_are_none() -> void:
	assert_int(DebugShortcut.of(_key(KEY_F1, false))).is_equal(DebugShortcut.Name.NONE)
	assert_int(DebugShortcut.of(_key(KEY_F1, true, true))).is_equal(DebugShortcut.Name.NONE)

func test_read_by_physical_key() -> void:
	assert_int(DebugShortcut.of(_key(KEY_F1, true, false, false))).is_equal(DebugShortcut.Name.NONE)
	var moved := InputEventKey.new()
	moved.keycode = KEY_A
	moved.physical_keycode = KEY_F1
	moved.pressed = true
	assert_int(DebugShortcut.of(moved)).is_equal(DebugShortcut.Name.READOUT)

func test_pad_buttons_are_none() -> void:
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_BACK
	b.pressed = true
	assert_int(DebugShortcut.of(b)).is_equal(DebugShortcut.Name.NONE)
