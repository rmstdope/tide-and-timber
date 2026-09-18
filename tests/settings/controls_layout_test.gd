extends GdUnitTestSuite
## Where the Controls page draws its words at one UI scale and one Text size.
## Positions are written as the old 320x180 page's plus O: the list and tabs are centred on the picture, and the
## whole block is moved down by ControlsPage.TOP_SHIFT to centre it on the 360-tall page. Where a test is about
## the lines wrapping at the picture's edges it passes twice the old UI scale, the same share of today's
## 640-wide picture; at the UI scales a player reaches on a 1280x720 window (1, 1.5, 2) they no longer wrap.

const D := Controls.Device
const O := Vector2(Screen.CENTRE.x - 160.0, ControlsPage.TOP_SHIFT)

func _at(x: float, y: float) -> Vector2:
	return Vector2(x, y) + O

func _r(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(_at(x, y), Vector2(w, h))

# Each line's String items, pictures dropped.
func _words(lines: Array) -> Array:
	var out := []
	for line: Array in lines:
		var words := []
		for item: Variant in line:
			if item is String:
				words.append(item)
		out.append(words)
	return out

func test_normal_layout_is_todays() -> void:
	var l := ControlsLayout.make(false, 1.0, 1.0)
	assert_that(l.tab_rect(0)).is_equal(ControlsPage.TAB_RECTS[0])
	assert_that(l.tab_rect(1)).is_equal(ControlsPage.TAB_RECTS[1])
	assert_that(l.row_rect(0)).is_equal(_r(16, 28, 288, 11))
	assert_float(l.row_rect(0).position.x).is_equal(ControlsPage.LIST_X)
	assert_that(l.slot_rect(3, 1)).is_equal(_r(212, 62, 60, 9))
	assert_that(l.name_origin(2)).is_equal(_at(20, 59))
	assert_float(l.heading_baseline).is_equal(ControlsPage.HEADING_BASELINE)
	assert_float(l.tab_baseline(0)).is_equal(23.0 + O.y)
	assert_float(l.no_key_baseline()).is_equal(137.0 + O.y)
	assert_float(l.fixed_baseline()).is_equal(147.0 + O.y)
	assert_float(l.content_bottom()).is_equal(ControlsPage.CONTENT_TOP + ControlsPage.CONTENT_H)
	assert_int(l.no_key_lines).is_equal(1)
	assert_int(l.fixed_lines).is_equal(2)

func _xbox(button: JoyButton) -> DeviceHints.Picture:
	return DeviceHints.picture_for(ControlsPage.pad_button(button), DeviceTracker.Kind.XBOX)

func test_normal_lines_under_the_list_are_unbroken() -> void:
	var l := ControlsLayout.make(false, 1.0, 1.0)
	assert_array(_words(l.fit_lines(ControlsLayout.keyboard_lines()))).is_equal(
		[["Menus", "always", "use", "the", "arrow", "keys,"], ["Enter", "and", "Esc"]])
	var lines := l.fit_lines(ControlsLayout.controller_lines(_xbox(JOY_BUTTON_A), _xbox(JOY_BUTTON_B)))
	assert_int(lines.size()).is_equal(1)
	assert_float(ControlsLayout.line_width(lines[0], 1.0)).is_equal(270.0)

func test_stacked_rows_at_text_normal_are_todays() -> void:
	for ui: float in [1.5, 2.0]:
		var l := ControlsLayout.make(true, 1.0, ui)
		assert_that(l.tab_rect(0)).is_equal(_r(82, 14, 68, 11))
		assert_that(l.tab_rect(1)).is_equal(_r(154, 14, 84, 11))
		assert_that(l.row_rect(8)).is_equal(_r(86, 204, 148, 22))
		assert_that(l.slot_rect(3, 0)).is_equal(_r(96, 105, 60, 9))
		assert_that(l.name_origin(0)).is_equal(_at(90, 37))
		assert_array(Array(l.name_lines(8, D.KEYBOARD))).is_equal(["Reset keyboard", "to defaults"])

# UI 3: what UI Large (1.5) was on the 320-wide picture.
func test_lines_under_the_list_at_large_ui() -> void:
	var l := ControlsLayout.make(true, 1.0, 3.0)
	assert_int(l.no_key_lines).is_equal(1)
	assert_int(l.fixed_lines).is_equal(2)
	assert_float(l.no_key_baseline()).is_equal(236.0 + O.y)
	assert_float(l.fixed_baseline()).is_equal(246.0 + O.y)
	assert_float(l.content_bottom()).is_equal(255.0 + O.y)
	assert_array(_words(l.fit_lines(ControlsLayout.keyboard_lines()))).is_equal(
		[["Menus", "always", "use", "the", "arrow"], ["keys,", "Enter", "and", "Esc"]])

# UI 4: what UI Largest (2) was on the 320-wide picture.
func test_lines_under_the_list_wrap_at_largest_ui() -> void:
	var l := ControlsLayout.make(true, 1.0, 4.0)
	assert_int(l.no_key_lines).is_equal(2)
	assert_int(l.fixed_lines).is_equal(3)
	assert_float(l.no_key_baseline()).is_equal(236.0 + O.y)
	assert_float(l.fixed_baseline()).is_equal(255.0 + O.y)
	assert_float(l.content_bottom()).is_equal(273.0 + O.y)
	assert_array(_words(l.fit_lines(ControlsLayout.keyboard_lines()))).is_equal(
		[["Menus", "always", "use"], ["the", "arrow", "keys,"], ["Enter", "and", "Esc"]])
	var controller := l.fit_lines(ControlsLayout.controller_lines(_xbox(JOY_BUTTON_A), _xbox(JOY_BUTTON_B)))
	assert_int(controller.size()).is_equal(2)
	assert_array(_words(controller)[1]).is_equal(["the", "d-pad,", "and"])
	assert_float(ControlsLayout.line_width(controller[1], 1.0)).is_equal(134.0)
	assert_array(_words(l.fit_lines(ControlsLayout.word_lines("Walk right has no key")))).is_equal(
		[["Walk", "right", "has", "no"], ["key"]])
	assert_that(l.row_extent(0)).is_equal(Vector2(0, 47))
	assert_that(l.row_extent(8)).is_equal(Vector2(201, 270))

func test_stacks_measures_grown_names() -> void:
	# The rows and their margins just fit across the picture at this UI scale (2.19...).
	var fit := Screen.WIDTH / (ControlsPage.LIST_W + 2.0 * ControlsPage.SCREEN_MARGIN)
	assert_bool(ControlsLayout.stacks(1.0, 1.0)).is_false()
	assert_bool(ControlsLayout.stacks(2.0, 1.0)).is_false()   # UI Largest alone never stacks
	assert_bool(ControlsLayout.stacks(fit, 1.0)).is_false()
	assert_bool(ControlsLayout.stacks(fit + 0.01, 1.0)).is_true()
	assert_bool(ControlsLayout.stacks(1.0, 1.25)).is_false()
	assert_bool(ControlsLayout.stacks(1.0, 1.5)).is_true()

func test_text_largest_at_ui_normal() -> void:
	var l := ControlsLayout.make(true, 2.0, 1.0)
	assert_float(l.grow).is_equal(8.0)
	assert_float(l.heading_baseline).is_equal(19.0 + O.y)
	assert_that(l.tab_rect(0)).is_equal(_r(10, 22, 132, 19))
	assert_that(l.tab_rect(1)).is_equal(_r(146, 22, 164, 19))
	assert_float(l.tab_baseline(1)).is_equal(39.0 + O.y)
	assert_float(l.list_x).is_equal(24.0 + O.x)
	assert_float(l.list_w).is_equal(272.0)
	assert_float(l.list_top).is_equal(44.0 + O.y)
	assert_float(l.row_h).is_equal(38.0)
	assert_float(l.slot_top).is_equal(27.0)
	assert_that(l.row_rect(8)).is_equal(_r(24, 348, 272, 38))
	assert_that(l.slot_rect(0, 1)).is_equal(_r(164, 71, 60, 9))
	assert_that(l.name_origin(0)).is_equal(_at(28, 61))
	assert_array(Array(l.name_lines(8, D.CONTROLLER))).is_equal(["Reset controller", "to defaults"])
	# The lines under the list no longer reach the picture's edges: one no-key line, two fixed lines,
	# each 17 apart (a grown line), so 2 lines (34) less than on the 320-wide picture.
	assert_int(l.no_key_lines).is_equal(1)
	assert_int(l.fixed_lines).is_equal(2)
	assert_float(l.no_key_baseline()).is_equal(404.0 + O.y)
	assert_float(l.fixed_baseline()).is_equal(404.0 + O.y + 18.0)
	assert_float(l.content_bottom()).is_equal(473.0 + O.y - 34.0)
	assert_that(l.row_extent(0)).is_equal(Vector2(0, 79))
	assert_that(l.row_extent(8)).is_equal(Vector2(345, l.content_bottom() - ControlsPage.CONTENT_TOP))

func test_largest_ui_and_text() -> void:
	# At UI 2 the page shows the middle 320 of the picture's 640 units: room enough that the tabs stay side
	# by side and the list, rows and names are Text Largest at UI Normal's (test_text_largest_at_ui_normal).
	var l := ControlsLayout.make(true, 2.0, 2.0)
	assert_that(l.tab_rect(0)).is_equal(_r(10, 22, 132, 19))
	assert_that(l.tab_rect(1)).is_equal(_r(146, 22, 164, 19))
	assert_float(l.list_top).is_equal(44.0 + O.y)
	assert_float(l.list_w).is_equal(272.0)
	assert_float(l.list_x).is_equal(24.0 + O.x)
	assert_float(l.row_h).is_equal(38.0)
	assert_that(l.slot_rect(0, 0)).is_equal(_r(96, 71, 60, 9))
	assert_array(Array(l.name_lines(0, D.KEYBOARD))).is_equal(["Walk up"])
	assert_array(Array(l.name_lines(3, D.KEYBOARD))).is_equal(["Walk right"])
	assert_array(Array(l.name_lines(8, D.CONTROLLER))).is_equal(["Reset controller", "to defaults"])
	assert_float(l.name_x("controller")).is_equal(28.0 + O.x)
	assert_float(l.name_x("Reset")).is_equal(28.0 + O.x)
	var half := Screen.WIDTH / 2.0 / 2.0   # half the units a 2x page shows across
	for i in 2:
		assert_float(l.tab_rect(i).position.x).is_greater_equal(Screen.CENTRE.x - half)
		assert_float(l.tab_rect(i).end.x).is_less_equal(Screen.CENTRE.x + half)
	for r in ControlsMenu.ROWS:
		assert_float(l.row_rect(r).position.x).is_greater_equal(Screen.CENTRE.x - half)
		assert_float(l.row_rect(r).end.x).is_less_equal(Screen.CENTRE.x + half)

func test_flow() -> void:
	assert_array(ControlsLayout.flow(["Walk", "right", "has", "no", "key"], 156, 2.0)).is_equal(
		[["Walk"], ["right", "has"], ["no", "key"]])
	assert_array(ControlsLayout.flow(["controller"], 100, 2.0)).is_equal([["controller"]])
	var p := _xbox(JOY_BUTTON_A)
	assert_float(ControlsLayout.line_width(["d-pad,", p, "and"], 1.0)).is_equal(89.0)
	assert_float(ControlsLayout.gap("a", "b", 2.0)).is_equal(16.0)

func test_grown_hit_and_tabs() -> void:
	var l := ControlsLayout.make(true, 2.0, 1.0)
	assert_that(l.hit(l.slot_rect(3, 1).get_center(), D.KEYBOARD)).is_equal(Vector2i(3, 1))
	assert_that(l.hit(l.slot_rect(3, 1).get_center(), D.CONTROLLER)).is_equal(Vector2i(-1, -1))
	assert_that(l.hit(l.row_rect(8).get_center(), D.KEYBOARD)).is_equal(Vector2i(8, -1))
	assert_that(l.hit(Vector2(30, l.row_rect(2).get_center().y), D.KEYBOARD)).is_equal(Vector2i(-1, -1))
	assert_int(l.tab_at(l.tab_rect(1).get_center())).is_equal(1)
	assert_int(l.tab_at(Vector2(5, 5))).is_equal(-1)

func test_empty_slot_grows_about_the_dash() -> void:
	assert_that(ControlsPage.empty_slot_at(Rect2(96, 71, 60, 9), "—", 2.0)).is_equal(Vector2(124, 72))
	assert_that(ControlsPage.empty_slot_at(Rect2(96, 71, 60, 9), "! —", 2.0)).is_equal(Vector2(108, 72))
