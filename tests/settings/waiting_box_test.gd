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

var KEY_LINES := PackedStringArray(["Walk right", ControlsMenu.PRESS_KEY])
var PAD_LINES := PackedStringArray(["Walk right", ControlsMenu.PRESS_BUTTON])

func _key_items() -> Array:
	return WaitingBox.hold_items(D.KEYBOARD, K.KEYBOARD)

# The measured layout at Text size Normal and UI size Normal is today's hard-coded geometry.
func test_normal_layout_is_todays_geometry() -> void:
	var l := WaitingBox.layout_at(KEY_LINES, _key_items(), 1.0, 1.0, font)
	assert_float(l.rel).is_equal(1.0)
	assert_that(l.panel).is_equal(WaitingBox.PANEL)
	assert_array(Array(l.names)).is_equal(["Walk right"])
	assert_array(Array(l.presses)).is_equal([ControlsMenu.PRESS_KEY])
	assert_int(l.hold.size()).is_equal(1)
	assert_int((l.hold[0] as Array).size()).is_equal(3)
	assert_str((l.hold[0] as Array)[0]).is_equal(WaitingBox.HOLD)
	assert_str((l.hold[0] as Array)[2]).is_equal(WaitingBox.TO_CANCEL)
	assert_float(l.step).is_equal(16.0)
	assert_float(l.hold_h).is_equal(16.0)
	assert_float(l.pic_dy).is_equal(0.0)
	assert_bool(l.fits).is_true()
	assert_float(l.panel.position.y + WaitingBox.TOP_PAD + WaitingBox.BASELINE_IN_ROW) \
		.is_equal(WaitingBox.NAME_BASELINE)
	assert_float(l.panel.position.y + WaitingBox.TOP_PAD + WaitingBox.BASELINE_IN_ROW + WaitingBox.LINE_STEP) \
		.is_equal(WaitingBox.PRESS_BASELINE)
	assert_float(l.panel.position.y + WaitingBox.TOP_PAD + 2.0 * WaitingBox.LINE_STEP + WaitingBox.HOLD_GAP) \
		.is_equal(WaitingBox.HOLD_TOP)
	assert_vector(l.ring).is_equal(Vector2(
		roundi(160 + WaitingBox.hold_width(_key_items(), font) / 2.0 + WaitingBox.RING_GAP),
		roundi(WaitingBox.HOLD_TOP - 0.5)))

func test_normal_layout_is_todays_geometry_on_a_pad() -> void:
	var l := WaitingBox.layout_at(PAD_LINES, WaitingBox.hold_items(D.CONTROLLER, K.XBOX), 1.0, 1.0, font)
	assert_that(l.panel).is_equal(WaitingBox.PANEL)
	assert_int(l.hold.size()).is_equal(1)
	assert_array(Array(l.presses)).is_equal([ControlsMenu.PRESS_BUTTON])
	assert_bool(l.fits).is_true()
