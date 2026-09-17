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

# The waiting box is drawn inside a page scaled by s about the fixed screen point (160, 90), in the
# waking scene and on the title alike, so a local y maps to screen 90 + s * (y - 90) with no node
# needed. It fits at every UI size, which is why it gets no Clip and never scrolls.
# It is, separately, wider than the screen at Largest; that belongs to tr-eg9.6.5.4.3 and is
# deliberately not checked here.
func test_the_panel_fits_the_screen_at_every_ui_size() -> void:
	for s: float in [1.0, 1.5, 2.0]:
		assert_float(90.0 + s * (WaitingBox.PANEL.position.y - 90.0)) \
			.override_failure_message("top at scale %f" % s).is_greater_equal(ScrollWindow.EDGE)
		assert_float(90.0 + s * (WaitingBox.PANEL.end.y - 90.0)) \
			.override_failure_message("bottom at scale %f" % s).is_less_equal(180.0 - ScrollWindow.EDGE)
