extends GdUnitTestSuite
## What each hint says on each device, in the agreed notation.

const K := DeviceTracker.Kind
const H := DeviceHints.Hint
const PADS := [K.XBOX, K.PLAYSTATION, K.NINTENDO]

func _text(hint: DeviceHints.Hint, kind: DeviceTracker.Kind, verb: String = "") -> String:
	return DeviceHints.as_text(DeviceHints.line(hint, kind, verb))

func test_keyboard_move_text() -> void:
	assert_str(_text(H.MOVE, K.KEYBOARD)).is_equal("[W][A][S][D] Move")

func test_pad_move_text() -> void:
	for kind: DeviceTracker.Kind in PADS:
		assert_str(_text(H.MOVE, kind)).is_equal("(L) Move")

func test_keyboard_use_text() -> void:
	assert_str(_text(H.USE, K.KEYBOARD, "Take")).is_equal("[E] Take")
	assert_str(_text(H.USE, K.KEYBOARD, "Shake")).is_equal("[E] Shake")

func test_pad_use_text() -> void:
	assert_str(_text(H.USE, K.XBOX, "Take")).is_equal("(A) Take")
	assert_str(_text(H.USE, K.PLAYSTATION, "Take")).is_equal("(✕) Take")
	assert_str(_text(H.USE, K.NINTENDO, "Take")).is_equal("(B) Take")

func test_keyboard_build_list_text() -> void:
	assert_str(_text(H.BUILD_LIST, K.KEYBOARD)).is_equal("[E] Build   [Esc] Close")

func test_pad_build_list_text() -> void:
	assert_str(_text(H.BUILD_LIST, K.XBOX)).is_equal("(A) Build   (B) Close")
	assert_str(_text(H.BUILD_LIST, K.PLAYSTATION)).is_equal("(✕) Build   (○) Close")
	assert_str(_text(H.BUILD_LIST, K.NINTENDO)).is_equal("(B) Build   (A) Close")

func test_placing_text() -> void:
	assert_str(_text(H.PLACING, K.KEYBOARD)).is_equal("[E] Place   [Esc] Back")
	assert_str(_text(H.PLACING, K.XBOX)).is_equal("(A) Place   (B) Back")

func test_xbox_colours() -> void:
	assert_that(DeviceHints.pictures(K.XBOX, DeviceHints.Slot.BOTTOM)[0].face).is_equal(Color("#3f9a3f"))
	assert_that(DeviceHints.pictures(K.XBOX, DeviceHints.Slot.RIGHT)[0].face).is_equal(Color("#c0433a"))

func test_every_picture_label_is_drawable() -> void:
	for kind: DeviceTracker.Kind in [K.KEYBOARD] + PADS:
		for slot: DeviceHints.Slot in DeviceHints.Slot.values():
			for p: DeviceHints.Picture in DeviceHints.pictures(kind, slot):
				for c in p.label:
					assert_int(Glyphs.ORDER.find(c)).override_failure_message("%s not drawable" % c).is_greater_equal(0)

func test_round_and_stick_labels_are_one_glyph() -> void:
	for kind: DeviceTracker.Kind in [K.KEYBOARD] + PADS:
		for slot: DeviceHints.Slot in DeviceHints.Slot.values():
			for p: DeviceHints.Picture in DeviceHints.pictures(kind, slot):
				if p.shape != DeviceHints.Shape.KEY and p.shape != DeviceHints.Shape.SHOULDER:
					assert_int(p.label.length()).is_equal(1)

# --- the player's own keys and buttons

const CA := Controls.Action
const CD := Controls.Device
const SH := DeviceHints.Shape

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

func _button(b: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b as JoyButton
	return e

func _motion(axis: int, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis as JoyAxis
	e.axis_value = value
	return e

func _with(c: Controls, hint: DeviceHints.Hint, kind: DeviceTracker.Kind, verb: String = "") -> String:
	return DeviceHints.as_text(DeviceHints.line(hint, kind, verb, c))

func test_use_hint_follows_the_players_key() -> void:
	var c := Controls.new()
	c.set_slot(CA.USE, CD.KEYBOARD, 0, _key(KEY_F))
	assert_str(_with(c, H.USE, K.KEYBOARD, "Take")).is_equal("[F] Take")

func test_use_hint_follows_the_players_button() -> void:
	var c := Controls.new()
	c.set_slot(CA.USE, CD.CONTROLLER, 0, _button(JOY_BUTTON_Y))
	assert_str(_with(c, H.USE, K.XBOX, "Take")).is_equal("(Y) Take")
	assert_str(_with(c, H.USE, K.PLAYSTATION, "Take")).is_equal("(△) Take")
	assert_str(_with(c, H.USE, K.NINTENDO, "Take")).is_equal("(X) Take")

func test_use_hint_without_a_key_has_no_picture() -> void:
	var c := Controls.new()
	c.clear_slot(CA.USE, CD.KEYBOARD, 0)
	assert_array(DeviceHints.line(H.USE, K.KEYBOARD, "Take", c)).is_equal(["Take"])

func test_build_list_falls_back_to_enter_without_use_key() -> void:
	var c := Controls.new()
	c.clear_slot(CA.USE, CD.KEYBOARD, 0)
	assert_str(_with(c, H.BUILD_LIST, K.KEYBOARD)).is_equal("[Enter] Build   [Esc] Close")
	c.clear_slot(CA.USE, CD.CONTROLLER, 0)
	assert_str(_with(c, H.PLACING, K.XBOX)).is_equal("(A) Place   (B) Back")

func test_move_hint_follows_walk_keys() -> void:
	var c := Controls.new()
	c.clear_slot(CA.WALK_LEFT, CD.KEYBOARD, 0)
	assert_str(_with(c, H.MOVE, K.KEYBOARD)).is_equal("[W][←][S][D] Move")

func test_move_hint_right_stick_collapses() -> void:
	var c := Controls.new()
	c.set_slot(CA.WALK_UP, CD.CONTROLLER, 0, _motion(JOY_AXIS_RIGHT_Y, -1.0))
	c.set_slot(CA.WALK_DOWN, CD.CONTROLLER, 0, _motion(JOY_AXIS_RIGHT_Y, 1.0))
	c.set_slot(CA.WALK_LEFT, CD.CONTROLLER, 0, _motion(JOY_AXIS_RIGHT_X, -1.0))
	c.set_slot(CA.WALK_RIGHT, CD.CONTROLLER, 0, _motion(JOY_AXIS_RIGHT_X, 1.0))
	assert_str(_with(c, H.MOVE, K.XBOX)).is_equal("(R) Move")

func test_move_hint_dpad_lists_each() -> void:
	var c := Controls.new()
	c.set_slot(CA.WALK_UP, CD.CONTROLLER, 0, _button(JOY_BUTTON_DPAD_UP))
	c.set_slot(CA.WALK_DOWN, CD.CONTROLLER, 0, _button(JOY_BUTTON_DPAD_DOWN))
	c.set_slot(CA.WALK_LEFT, CD.CONTROLLER, 0, _button(JOY_BUTTON_DPAD_LEFT))
	c.set_slot(CA.WALK_RIGHT, CD.CONTROLLER, 0, _button(JOY_BUTTON_DPAD_RIGHT))
	assert_str(_with(c, H.MOVE, K.XBOX)).is_equal("(↑)(←)(↓)(→) Move")

func _pic(e: InputEvent, kind: DeviceTracker.Kind) -> Array:
	var p := DeviceHints.picture_for(e, kind)
	return [p.shape, p.label]

func test_pad_pictures_by_family() -> void:
	var rows := [
		[_button(2), [SH.ROUND, "X"], [SH.ROUND, "□"], [SH.ROUND, "Y"]],
		[_button(4), [SH.SHOULDER, "View"], [SH.SHOULDER, "Share"], [SH.ROUND, "-"]],
		[_button(6), [SH.SHOULDER, "Start"], [SH.SHOULDER, "Opt"], [SH.ROUND, "+"]],
		[_button(9), [SH.SHOULDER, "LB"], [SH.SHOULDER, "L1"], [SH.SHOULDER, "L"]],
		[_motion(4, 1.0), [SH.SHOULDER, "LT"], [SH.SHOULDER, "L2"], [SH.SHOULDER, "ZL"]],
	]
	for row: Array in rows:
		assert_array(_pic(row[0], K.XBOX)).is_equal(row[1])
		assert_array(_pic(row[0], K.PLAYSTATION)).is_equal(row[2])
		assert_array(_pic(row[0], K.NINTENDO)).is_equal(row[3])
	assert_array(_pic(_button(15), K.XBOX)).is_equal([SH.SHOULDER, "B15"])
	assert_array(_pic(_motion(1, -1.0), K.XBOX)).is_equal([SH.SHOULDER, "L↑"])
	assert_array(_pic(_motion(2, 1.0), K.XBOX)).is_equal([SH.SHOULDER, "R→"])
	assert_array(_pic(_motion(7, 1.0), K.XBOX)).is_equal([SH.SHOULDER, "A7"])
	assert_array(_pic(_key(KEY_F), K.XBOX)).is_equal([SH.KEY, "F"])

func test_every_pad_label_is_drawable() -> void:
	for kind: DeviceTracker.Kind in PADS:
		var events: Array[InputEvent] = []
		for b in 21:
			events.append(_button(b))
		for axis in 6:
			events.append(_motion(axis, -1.0))
			events.append(_motion(axis, 1.0))
		for e in events:
			for ch in DeviceHints.picture_for(e, kind).label:
				assert_bool(ch == " " or Glyphs.ORDER.find(ch) >= 0) \
					.override_failure_message("%s not drawable" % ch).is_true()

func test_build_hint_falls_back_when_a_menu_takes_the_use_key() -> void:
	var c := Controls.new()
	c.set_slot(CA.USE, CD.KEYBOARD, 0, _key(KEY_ESCAPE))
	assert_str(_with(c, H.BUILD_LIST, K.KEYBOARD)).is_equal("[Enter] Build   [Esc] Close")
	assert_str(_with(c, H.PLACING, K.KEYBOARD)).is_equal("[Enter] Place   [Esc] Back")
	var d := Controls.new()
	d.set_slot(CA.USE, CD.KEYBOARD, 0, _key(KEY_DOWN))
	assert_str(_with(d, H.BUILD_LIST, K.KEYBOARD)).is_equal("[Enter] Build   [Esc] Close")
	assert_str(_with(d, H.PLACING, K.KEYBOARD)).is_equal("[↓] Place   [Esc] Back")
	var p := Controls.new()
	p.set_slot(CA.USE, CD.CONTROLLER, 0, _button(JOY_BUTTON_B))
	assert_str(_with(p, H.BUILD_LIST, K.XBOX)).is_equal("(A) Build   (B) Close")

