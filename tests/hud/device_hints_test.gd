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
				if p.shape != DeviceHints.Shape.KEY:
					assert_int(p.label.length()).is_equal(1)
