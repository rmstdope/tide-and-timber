extends GdUnitTestSuite
## The waiting box's hold line and its fit inside the panel.

const K := DeviceTracker.Kind
const D := Controls.Device

var font: Font = load("res://assets/fonts/PressStart2P-Regular.ttf")

func _w(text: String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, HintLine.FONT_SIZE).x

func test_hold_line_words() -> void:
	assert_str(DeviceHints.as_text(WaitingBox.hold_items(D.KEYBOARD, K.KEYBOARD))).is_equal("Hold   [Esc] to cancel")
	assert_str(DeviceHints.as_text(WaitingBox.hold_items(D.CONTROLLER, K.XBOX))).is_equal("Hold   (B) to cancel")
	assert_str(DeviceHints.as_text(WaitingBox.hold_items(D.CONTROLLER, K.PLAYSTATION))).is_equal("Hold   (○) to cancel")
	assert_str(DeviceHints.as_text(WaitingBox.hold_items(D.CONTROLLER, K.NINTENDO))).is_equal("Hold   (A) to cancel")

func test_box_fits() -> void:
	for kind: DeviceTracker.Kind in [K.KEYBOARD, K.XBOX, K.PLAYSTATION, K.NINTENDO]:
		for d: Controls.Device in D.values():
			var ring_end := 160 + WaitingBox.hold_width(WaitingBox.hold_items(d, kind), font) / 2.0 + WaitingBox.RING_GAP + 10
			assert_float(ring_end).is_less_equal(WaitingBox.PANEL.end.x - 4)
	var texts: Array = Controls.NAMES.values() + [ControlsMenu.PRESS_KEY, ControlsMenu.PRESS_BUTTON]
	for t: String in texts:
		assert_float(_w(t)).override_failure_message(t).is_less_equal(WaitingBox.PANEL.size.x - 8)
	assert_float(WaitingBox.PANEL.end.y).is_less_equal(180.0)
	assert_float(WaitingBox.HOLD_TOP + 10).is_less_equal(WaitingBox.PANEL.end.y - 4)
