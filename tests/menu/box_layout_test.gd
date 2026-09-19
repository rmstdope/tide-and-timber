extends GdUnitTestSuite
## BoxLayout: side by side at Normal, stacked and narrowed when the buttons would be wider than the screen.

const B := Vector2(104, 20)
## The scales that stack the Normal box: past Screen.WIDTH / 296 its buttons no longer fit side by side.
## widest() at these is 204 and 152, the stacked widths the layouts below are built on.
const LARGE := 3.0
const LARGEST := 4.0

## A rect of this size centred on the picture, where at() and one_button() put a resized panel.
static func _centred(size: Vector2) -> Rect2:
	return Rect2((Screen.SIZE - size) / 2.0, size)

var fake := func(i: int, w: float) -> float: return [8.0, 19.0][i] if w >= 188.0 else [8.0, 30.0][i]

func _normal() -> BoxLayout:
	var n := BoxLayout.new()
	n.panel = _centred(Vector2(296, 96))
	n.lines = [Rect2(8, 8, 280, 12), Rect2(8, 28, 280, 28)]
	n.left = Rect2(40, 66, 104, 20)
	n.right = Rect2(152, 66, 104, 20)
	return n

func test_side_by_side_at_normal_is_the_normal_layout() -> void:
	var n := _normal()
	var l := n.at(1.0, B, B, fake)
	assert_bool(l.stacked).is_false()
	assert_that(l.panel).is_equal(_centred(Vector2(296, 96)))
	assert_that(l.lines[0]).is_equal(Rect2(8, 8, 280, 12))
	assert_that(l.lines[1]).is_equal(Rect2(8, 28, 280, 28))
	assert_that(l.left).is_equal(Rect2(40, 66, 104, 20))
	assert_that(l.right).is_equal(Rect2(152, 66, 104, 20))
	assert_bool(is_same(l, n)).is_false()
	l.lines[0] = Rect2(0, 0, 1, 1)
	assert_that(n.lines[0]).is_equal(Rect2(8, 8, 280, 12))

func test_stacks_at_is_measured_from_the_buttons() -> void:
	var n := _normal()
	assert_bool(n.stacks_at(1.0, B, B)).is_false()
	assert_bool(n.stacks_at(2.0, B, B)).is_false()
	assert_bool(n.stacks_at(LARGE, B, B)).is_true()
	assert_bool(n.stacks_at(LARGEST, B, B)).is_true()
	# side 40 + 460 + gap 8 + 104 + side 40 = 652, wider than the picture
	assert_bool(n.stacks_at(1.0, Vector2(460, 20), B)).is_true()

func test_stacked_width() -> void:
	assert_float(BoxLayout.stacked_width(296, LARGE)).is_equal(204.0)
	assert_float(BoxLayout.stacked_width(296, LARGEST)).is_equal(152.0)
	assert_float(BoxLayout.stacked_width(296, 1.0)).is_equal(296.0)
	assert_float(BoxLayout.stacked_width(100, LARGE)).is_equal(100.0)

func test_stacked_at_largest() -> void:
	var l := _normal().at(LARGEST, B, B, fake)
	assert_bool(l.stacked).is_true()
	assert_that(l.panel).is_equal(_centred(Vector2(152, 126)))
	assert_that(l.lines[0]).is_equal(Rect2(8, 8, 136, 12))
	assert_that(l.lines[1]).is_equal(Rect2(8, 28, 136, 30))
	assert_that(l.left).is_equal(Rect2(24, 68, 104, 20))
	assert_that(l.right).is_equal(Rect2(24, 96, 104, 20))

func test_stacked_at_large() -> void:
	var l := _normal().at(LARGE, B, B, fake)
	assert_bool(l.stacked).is_true()
	assert_that(l.panel).is_equal(_centred(Vector2(204, 124)))
	assert_that(l.lines[0]).is_equal(Rect2(8, 8, 188, 12))
	assert_that(l.lines[1]).is_equal(Rect2(8, 28, 188, 28))
	assert_that(l.left).is_equal(Rect2(50, 66, 104, 20))
	assert_that(l.right).is_equal(Rect2(50, 94, 104, 20))

func test_stacked_keeps_each_lines_insets() -> void:
	var n := _normal()
	n.lines[0] = Rect2(24, 8, 264, 12)
	var seen: Array = []
	var recording := func(i: int, w: float) -> float:
		seen.append([i, w])
		return fake.call(i, w)
	var l := n.at(LARGEST, B, B, recording)
	assert_float(l.lines[0].position.x).is_equal(24.0)
	assert_float(l.lines[0].size.x).is_equal(120.0)
	assert_bool(seen.has([0, 120.0])).is_true()

func test_stacked_buttons_keep_their_own_widths_centred() -> void:
	var l := _normal().at(LARGEST, Vector2(120, 20), B, fake)
	assert_float(l.left.position.x).is_equal(16.0)
	assert_float(l.right.position.x).is_equal(24.0)

func test_one_button_side_by_side_centres_the_left_button() -> void:
	var l := _normal().at(1.0, B, B, fake).one_button()
	assert_bool(l.stacked).is_false()
	assert_that(l.left).is_equal(Rect2(96, 66, 104, 20))
	assert_that(l.panel).is_equal(_centred(Vector2(296, 96)))
	assert_that(l.lines).is_equal(_normal().lines)

func test_one_button_stacked_drops_the_second_row() -> void:
	var s := _normal().at(LARGEST, B, B, fake)
	var l := s.one_button()
	assert_bool(l.stacked).is_true()
	assert_that(l.panel).is_equal(_centred(Vector2(152, 98)))
	assert_that(l.left).is_equal(Rect2(24, 68, 104, 20))
	assert_that(l.lines).is_equal(s.lines)

func test_one_button_leaves_the_original_unchanged() -> void:
	var s := _normal().at(LARGEST, B, B, fake)
	var line0 := s.lines[0]
	var o := s.one_button()
	assert_that(s.panel).is_equal(_centred(Vector2(152, 126)))
	o.lines[0] = Rect2()
	assert_that(s.lines[0]).is_equal(line0)

# --- framing to the band, and the push rule (tr-eg9.6.4.5.2.1) ---

## The quit box stacked, as measured in the waking scene, and the band it is framed to: the room from
## 44 above the picture's middle to 8 below it.
func _largest() -> BoxLayout:
	var l := BoxLayout.new()
	l.stacked = true
	l.panel = _centred(Vector2(152, 124))
	l.lines = [Rect2(8, 8, 136, 12), Rect2(8, 28, 136, 28)]
	l.left = Rect2(24, 66, 104, 20)
	l.right = Rect2(24, 94, 104, 20)
	return l

const BAND_TOP := Screen.CENTRE.y - 44.0
const BAND_BOTTOM := Screen.CENTRE.y + 8.0

func _at(o: int) -> BoxLayout:
	return _largest().framed(BAND_TOP, BAND_BOTTOM, o)

func test_content_spans_first_line_to_lowest_button() -> void:
	assert_float(_largest().content_top()).is_equal(8.0)
	assert_float(_largest().content_height()).is_equal(106.0)
	assert_float(_largest().one_button().content_height()).is_equal(78.0)
	assert_float(_normal().content_height()).is_equal(78.0)

func test_one_button_hides_the_right() -> void:
	assert_bool(_largest().one_button().right_shown).is_false()
	assert_bool(_largest().right_shown).is_true()

func test_framed_scrolls_when_taller_than_the_band() -> void:
	var f := _at(0)
	assert_bool(f.scrolls).is_true()
	assert_that(f.panel).is_equal(Rect2(_largest().panel.position.x, BAND_TOP, 152, 52))
	assert_that(f.clip).is_equal(Rect2(0, 16, 152, 20))
	assert_that(f.content).is_equal(Rect2(0, -8, 152, 124))
	assert_int(f.offset).is_equal(0)
	assert_that(f.left).is_equal(Rect2(24, 66, 104, 20))
	assert_that(f.right).is_equal(Rect2(24, 94, 104, 20))

func test_framed_clamps_the_offset() -> void:
	assert_int(_at(500).offset).is_equal(86)
	assert_that(_at(500).content).is_equal(Rect2(0, -94, 152, 124))
	assert_int(_at(-3).offset).is_equal(0)

func test_framed_fits_unchanged() -> void:
	var f := _normal().framed(2, Screen.HEIGHT - 18, 20)
	assert_bool(f.scrolls).is_false()
	assert_that(f.panel).is_equal(_centred(Vector2(296, 96)))
	assert_that(f.clip).is_equal(Rect2(0, 0, 296, 96))
	assert_that(f.content).is_equal(Rect2(0, 0, 296, 96))
	assert_int(f.offset).is_equal(0)

func test_a_fitting_panel_moves_inside_the_band() -> void:
	# the panel's top is Screen.CENTRE.y - 62: a band starting below it pulls it down, one ending above its bottom lifts it
	assert_float(_largest().framed(Screen.CENTRE.y - 50, Screen.CENTRE.y + 110, 0).panel.position.y).is_equal(Screen.CENTRE.y - 50)
	assert_float(_largest().framed(Screen.CENTRE.y - 90, Screen.CENTRE.y + 50, 0).panel.position.y).is_equal(Screen.CENTRE.y + 50 - 124)

func test_marks() -> void:
	assert_bool(_at(0).shows_mark_above()).is_false()
	assert_bool(_at(0).shows_mark_below()).is_true()
	assert_bool(_at(30).shows_mark_above()).is_true()
	assert_bool(_at(30).shows_mark_below()).is_true()
	assert_bool(_at(86).shows_mark_above()).is_true()
	assert_bool(_at(86).shows_mark_below()).is_false()
	assert_bool(_normal().framed(2, Screen.HEIGHT - 18, 0).shows_mark_above()).is_false()
	assert_bool(_normal().framed(2, Screen.HEIGHT - 18, 0).shows_mark_below()).is_false()

func test_down_scrolls_a_line_towards_a_hidden_button() -> void:
	assert_that(_at(0).pushed(BoxLayout.Push.DOWN, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 11))
	assert_that(_at(44).pushed(BoxLayout.Push.DOWN, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 55))
	assert_that(_at(50).pushed(BoxLayout.Push.DOWN, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 58))

func test_down_on_a_shown_top_button_moves_to_the_bottom_one() -> void:
	assert_that(_at(58).pushed(BoxLayout.Push.DOWN, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 86))

func test_down_on_the_bottom_button_in_view_does_nothing() -> void:
	assert_that(_at(86).pushed(BoxLayout.Push.DOWN, BoxLayout.Side.RIGHT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 86))

func test_up_on_the_bottom_button_in_view_moves_to_the_top_one() -> void:
	assert_that(_at(86).pushed(BoxLayout.Push.UP, BoxLayout.Side.RIGHT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 58))

func test_up_on_the_top_button_scrolls_back_to_the_words() -> void:
	assert_that(_at(58).pushed(BoxLayout.Push.UP, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 47))
	assert_that(_at(3).pushed(BoxLayout.Push.UP, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 0))

func test_up_on_the_top_button_at_the_top_does_nothing() -> void:
	assert_that(_at(0).pushed(BoxLayout.Push.UP, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 0))

func test_a_hidden_highlight_is_scrolled_towards() -> void:
	assert_that(_at(0).pushed(BoxLayout.Push.UP, BoxLayout.Side.RIGHT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 11))
	assert_that(_at(74).pushed(BoxLayout.Push.DOWN, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 63))

## A button taller than the view is hidden above and below at once: the push goes up, towards its top.
func test_a_button_taller_than_the_view_is_scrolled_up_to() -> void:
	var l := _largest()
	l.right = Rect2(24, 94, 104, 60)
	var f := l.framed(BAND_TOP, BAND_BOTTOM, 100)
	assert_float(f.clip.size.y).is_equal(20.0)
	assert_int(f.offset).is_equal(100)
	assert_that(f.pushed(BoxLayout.Push.UP, BoxLayout.Side.RIGHT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 89))
	# Within one line-step of its top (86): the push stops there rather than scrolling past it.
	assert_that(l.framed(BAND_TOP, BAND_BOTTOM, 92).pushed(BoxLayout.Push.UP, BoxLayout.Side.RIGHT)) \
		.is_equal(Vector2i(BoxLayout.Side.RIGHT, 86))

func test_left_right_move_and_show_just_enough() -> void:
	assert_that(_at(0).pushed(BoxLayout.Push.RIGHT, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 86))
	assert_that(_at(86).pushed(BoxLayout.Push.LEFT, BoxLayout.Side.RIGHT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 58))
	assert_that(_at(60).pushed(BoxLayout.Push.LEFT, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 58))

func test_wheel_scrolls_a_line_and_keeps_the_highlight() -> void:
	assert_that(_at(80).pushed(BoxLayout.Push.WHEEL_DOWN, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 86))
	assert_that(_at(5).pushed(BoxLayout.Push.WHEEL_UP, BoxLayout.Side.RIGHT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 0))
	assert_that(_at(20).pushed(BoxLayout.Push.WHEEL_DOWN, BoxLayout.Side.RIGHT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 31))

func test_fitting_pushes_are_todays() -> void:
	var n := _normal().framed(2, Screen.HEIGHT - 18, 0)
	assert_that(n.pushed(BoxLayout.Push.UP, BoxLayout.Side.RIGHT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 0))
	assert_that(n.pushed(BoxLayout.Push.DOWN, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 0))
	assert_that(n.pushed(BoxLayout.Push.RIGHT, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 0))
	assert_that(n.pushed(BoxLayout.Push.WHEEL_DOWN, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 0))
	var t := _largest().framed(0, Screen.HEIGHT, 0)
	assert_that(t.pushed(BoxLayout.Push.DOWN, BoxLayout.Side.LEFT)).is_equal(Vector2i(BoxLayout.Side.RIGHT, 0))
	assert_that(t.pushed(BoxLayout.Push.UP, BoxLayout.Side.RIGHT)).is_equal(Vector2i(BoxLayout.Side.LEFT, 0))

func test_one_button_right_keeps_the_left() -> void:
	assert_int(_largest().one_button().framed(BAND_TOP, BAND_BOTTOM, 0).pushed(BoxLayout.Push.RIGHT, BoxLayout.Side.LEFT).x).is_equal(BoxLayout.Side.LEFT)

func test_wheel_push_reads_only_a_wheel_press() -> void:
	var wheel := func(index: MouseButton, pressed: bool) -> InputEventMouseButton:
		var e := InputEventMouseButton.new()
		e.button_index = index
		e.pressed = pressed
		return e
	assert_int(BoxLayout.wheel_push(wheel.call(MOUSE_BUTTON_WHEEL_UP, true))).is_equal(BoxLayout.Push.WHEEL_UP)
	assert_int(BoxLayout.wheel_push(wheel.call(MOUSE_BUTTON_WHEEL_DOWN, true))).is_equal(BoxLayout.Push.WHEEL_DOWN)
	assert_int(BoxLayout.wheel_push(wheel.call(MOUSE_BUTTON_WHEEL_UP, false))).is_equal(-1)
	assert_int(BoxLayout.wheel_push(wheel.call(MOUSE_BUTTON_LEFT, true))).is_equal(-1)
	assert_int(BoxLayout.wheel_push(InputEventKey.new())).is_equal(-1)

func test_widest() -> void:
	assert_float(BoxLayout.widest(1.0)).is_equal(Screen.WIDTH - 2.0 * BoxLayout.SCREEN_MARGIN)
	assert_float(BoxLayout.widest(2.0)).is_equal(Screen.WIDTH / 2.0 - 2.0 * BoxLayout.SCREEN_MARGIN)
	assert_float(BoxLayout.widest(LARGE)).is_equal(204.0)     # 2 * floor((640 / 3 - 8) / 2)
	assert_float(BoxLayout.widest(LARGEST)).is_equal(152.0)
	assert_float(BoxLayout.stacked_width(296, LARGE)).is_equal(204.0)

func test_grown_words_widen_the_box_then_wrap() -> void:
	var widths := func(i: int) -> float: return 0.0 if i == 0 else 2.0 * Screen.WIDTH
	var heights := func(i: int, w: float) -> float: return 12.0 if i == 0 else (28.0 if w >= Screen.WIDTH else 56.0)
	var l := _normal().at(1.0, B, B, heights, widths)
	var w := BoxLayout.widest(1.0)
	assert_bool(l.stacked).is_false()
	assert_that(l.lines[1]).is_equal(Rect2(8, 28, w - 16, 56))
	# the pair is centred across the grown box: (w - 216) / 2
	assert_that(l.left).is_equal(Rect2((w - 216) / 2, 94, 104, 20))
	assert_that(l.right).is_equal(Rect2((w - 216) / 2 + 112, 94, 104, 20))
	assert_that(l.panel).is_equal(_centred(Vector2(w, 124)))

func test_grown_words_widen_the_box_without_wrapping() -> void:
	var widths := func(_i: int) -> float: return 200.0
	var l := _normal().at(1.0, B, B, fake, widths)
	assert_that(l.panel).is_equal(_centred(Vector2(296, 96)))

func test_grown_buttons_stay_centred_side_by_side() -> void:
	var l := _normal().at(1.0, Vector2(110, 24), Vector2(110, 24), fake)
	assert_bool(l.stacked).is_false()
	assert_that(l.left).is_equal(Rect2(34, 66, 110, 24))
	assert_that(l.right).is_equal(Rect2(152, 66, 110, 24))
	assert_that(l.panel).is_equal(_centred(Vector2(296, 100)))

func test_button_size_never_shrinks_a_button() -> void:
	var small := PanelContainer.new()
	small.custom_minimum_size = Vector2(40, 12)
	var big := PanelContainer.new()
	big.custom_minimum_size = Vector2(180, 26)
	var normal := Rect2(40, 66, 104, 20)
	assert_that(BoxLayout.button_size(small, normal)).is_equal(Vector2(104, 20))
	assert_that(BoxLayout.button_size(big, normal)).is_equal(Vector2(180, 26))
	small.free()
	big.free()

func _label() -> Label:
	var label := Label.new()
	label.text = "Nothing has been saved yet."
	label.add_theme_font_size_override("font_size", 8)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(120, 12)
	add_child(label)
	return label

func test_label_widths_measures_unwrapped_and_restores_autowrap() -> void:
	var label := _label()
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.update_minimum_size()
	var min_x := label.get_minimum_size().x
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var labels: Array[Label] = [label]
	assert_float(BoxLayout.label_widths(labels, 2.0).call(0)).is_equal(ceilf(min_x * 2.0))
	assert_int(label.autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
	label.free()

func test_label_widths_at_normal_keeps_the_scene_widths() -> void:
	var labels: Array[Label] = []
	assert_bool(BoxLayout.label_widths(labels, 1.0).is_valid()).is_false()

func test_label_heights_scales_by_rel() -> void:
	var label := _label()
	var labels: Array[Label] = [label]
	var one: float = BoxLayout.label_heights(labels, 1.0).call(0, 148.0)
	var two: float = BoxLayout.label_heights(labels, 2.0).call(0, 296.0)
	assert_float(two).is_equal(2.0 * one)
	label.free()

func test_the_frame_edge_is_the_frame_arts_margin() -> void:
	var f := load("res://src/hud/frame.tres") as StyleBoxTexture
	assert_float(f.texture_margin_left).is_equal(BoxLayout.FRAME_EDGE)
	assert_float(f.texture_margin_top).is_equal(BoxLayout.FRAME_EDGE)
	assert_float(f.texture_margin_right).is_equal(BoxLayout.FRAME_EDGE)
	assert_float(f.texture_margin_bottom).is_equal(BoxLayout.FRAME_EDGE)
	assert_float(BoxLayout.BUTTON_INSET).is_equal(BoxLayout.FRAME_EDGE + 2.0)

func test_a_scrolling_box_keeps_its_view_and_marks_inside_the_frame() -> void:
	var f := _at(0)
	assert_that(f.clip).is_equal(Rect2(0, 16, 152, 20))
	var panel := auto_free(Control.new()) as Control
	var clip := auto_free(Control.new()) as Control
	var content := auto_free(Control.new()) as Control
	var marks := auto_free(Control.new()) as Control
	f.place_frame(panel, clip, content, marks)
	assert_that(marks.get_rect()).is_equal(Rect2(0, 6, 152, 40))

func test_side_by_side_buttons_keep_clear_of_the_frame() -> void:
	var l := _normal().at(1.0, Vector2(150, 20), Vector2(150, 20), fake)
	assert_bool(l.stacked).is_false()
	assert_float(l.panel.size.x).is_equal(324.0)
	assert_float(l.left.position.x).is_equal(8.0)
	assert_float(l.right.end.x).is_equal(316.0)
