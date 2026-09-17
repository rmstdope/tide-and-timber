extends GdUnitTestSuite
## Where the Controls page's rows, slots and tabs sit, and that its words fit the 320x180 base.

const D := Controls.Device

var font: Font = load("res://assets/fonts/PressStart2P-Regular.ttf")

func _w(text: String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x

func test_hit_finds_rows_and_slots() -> void:
	assert_that(ControlsPage.hit(ControlsPage.slot_rect(3, 1).get_center(), D.KEYBOARD)).is_equal(Vector2i(3, 1))
	assert_that(ControlsPage.hit(ControlsPage.slot_rect(3, 1).get_center(), D.CONTROLLER)).is_equal(Vector2i(-1, -1))
	assert_that(ControlsPage.hit(ControlsPage.slot_rect(3, 0).get_center(), D.CONTROLLER)).is_equal(Vector2i(3, 0))
	assert_that(ControlsPage.hit(ControlsPage.row_rect(8).get_center(), D.KEYBOARD)).is_equal(Vector2i(8, -1))
	assert_that(ControlsPage.hit(Vector2(ControlsPage.NAME_X + 4, ControlsPage.row_rect(2).get_center().y), D.KEYBOARD)) \
		.is_equal(Vector2i(-1, -1))
	assert_that(ControlsPage.hit(Vector2(160, 5), D.KEYBOARD)).is_equal(Vector2i(-1, -1))

func test_tab_at() -> void:
	assert_int(ControlsPage.tab_at(ControlsPage.TAB_RECTS[0].get_center())).is_equal(0)
	assert_int(ControlsPage.tab_at(ControlsPage.TAB_RECTS[1].get_center())).is_equal(1)
	assert_int(ControlsPage.tab_at(Vector2(10, 10))).is_equal(-1)

func test_page_fits_the_base() -> void:
	assert_float(ControlsPage.row_rect(8).end.y).is_less_equal(ControlsPage.LINE_BASELINE - 8)
	assert_float(ControlsPage.FIXED_BASELINES[1]).is_less_equal(MenuStrip.BOTTOM - KeyHint.HEIGHT)
	for r in ControlsMenu.ROWS:
		for s in 2:
			assert_bool(ControlsPage.row_rect(r).encloses(ControlsPage.slot_rect(r, s))).is_true()
	assert_float(ControlsPage.SLOT_XS[1] + ControlsPage.SLOT_W).is_less_equal(ControlsPage.LIST_X + ControlsPage.LIST_W)

func test_words_fit_320() -> void:
	for line: String in ControlsPage.KEYBOARD_FIXED:
		assert_float(_w(line)).override_failure_message(line).is_less_equal(312.0)
	assert_float(ControlsPage.NAME_X + _w("Reset controller to defaults")).is_less_equal(ControlsPage.LIST_X + ControlsPage.LIST_W)
	for a: Controls.Action in Controls.Action.values():
		assert_float(ControlsPage.NAME_X + _w(Controls.NAMES[a])).override_failure_message(Controls.NAMES[a]) \
			.is_less_equal(ControlsPage.SLOT_XS[0])
	for kind: DeviceTracker.Kind in [DeviceTracker.Kind.XBOX, DeviceTracker.Kind.PLAYSTATION, DeviceTracker.Kind.NINTENDO]:
		var pictures := 0
		for b in [JOY_BUTTON_A, JOY_BUTTON_B]:
			var e := InputEventJoypadButton.new()
			e.button_index = b
			pictures += HintLine.picture_width(DeviceHints.picture_for(e, kind))
		var words := _w(ControlsPage.CONTROLLER_FIXED_WORDS[0]) + _w(ControlsPage.CONTROLLER_FIXED_WORDS[1])
		assert_float(words + pictures + 12).is_less_equal(312.0)
