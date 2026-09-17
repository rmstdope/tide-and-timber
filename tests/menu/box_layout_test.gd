extends GdUnitTestSuite
## BoxLayout: side by side at Normal, stacked and narrowed when the buttons would be wider than the screen.

const B := Vector2(104, 20)

var fake := func(i: int, w: float) -> float: return [8.0, 19.0][i] if w >= 188.0 else [8.0, 30.0][i]

func _normal() -> BoxLayout:
	var n := BoxLayout.new()
	n.panel = Rect2(12, 42, 296, 96)
	n.lines = [Rect2(8, 8, 280, 12), Rect2(8, 28, 280, 28)]
	n.left = Rect2(40, 66, 104, 20)
	n.right = Rect2(152, 66, 104, 20)
	return n

func test_side_by_side_at_normal_is_the_normal_layout() -> void:
	var n := _normal()
	var l := n.at(1.0, B, B, fake)
	assert_bool(l.stacked).is_false()
	assert_that(l.panel).is_equal(Rect2(12, 42, 296, 96))
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
	assert_bool(n.stacks_at(1.5, B, B)).is_true()
	assert_bool(n.stacks_at(2.0, B, B)).is_true()
	assert_bool(n.stacks_at(1.0, Vector2(130, 20), B)).is_true()

func test_stacked_width() -> void:
	assert_float(BoxLayout.stacked_width(296, 1.5)).is_equal(204.0)
	assert_float(BoxLayout.stacked_width(296, 2.0)).is_equal(152.0)
	assert_float(BoxLayout.stacked_width(296, 1.0)).is_equal(296.0)
	assert_float(BoxLayout.stacked_width(100, 1.5)).is_equal(100.0)

func test_stacked_at_largest() -> void:
	var l := _normal().at(2.0, B, B, fake)
	assert_bool(l.stacked).is_true()
	assert_that(l.panel).is_equal(Rect2(84, 27, 152, 126))
	assert_that(l.lines[0]).is_equal(Rect2(8, 8, 136, 12))
	assert_that(l.lines[1]).is_equal(Rect2(8, 28, 136, 30))
	assert_that(l.left).is_equal(Rect2(24, 68, 104, 20))
	assert_that(l.right).is_equal(Rect2(24, 96, 104, 20))

func test_stacked_at_large() -> void:
	var l := _normal().at(1.5, B, B, fake)
	assert_bool(l.stacked).is_true()
	assert_that(l.panel).is_equal(Rect2(58, 28, 204, 124))
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
	var l := n.at(2.0, B, B, recording)
	assert_float(l.lines[0].position.x).is_equal(24.0)
	assert_float(l.lines[0].size.x).is_equal(120.0)
	assert_bool(seen.has([0, 120.0])).is_true()

func test_stacked_buttons_keep_their_own_widths_centred() -> void:
	var l := _normal().at(2.0, Vector2(120, 20), B, fake)
	assert_float(l.left.position.x).is_equal(16.0)
	assert_float(l.right.position.x).is_equal(24.0)

func test_one_button_side_by_side_centres_the_left_button() -> void:
	var l := _normal().at(1.0, B, B, fake).one_button()
	assert_bool(l.stacked).is_false()
	assert_that(l.left).is_equal(Rect2(96, 66, 104, 20))
	assert_that(l.panel).is_equal(Rect2(12, 42, 296, 96))
	assert_that(l.lines).is_equal(_normal().lines)

func test_one_button_stacked_drops_the_second_row() -> void:
	var s := _normal().at(2.0, B, B, fake)
	var l := s.one_button()
	assert_bool(l.stacked).is_true()
	assert_that(l.panel).is_equal(Rect2(84, 41, 152, 98))
	assert_that(l.left).is_equal(Rect2(24, 68, 104, 20))
	assert_that(l.lines).is_equal(s.lines)

func test_one_button_leaves_the_original_unchanged() -> void:
	var s := _normal().at(2.0, B, B, fake)
	var line0 := s.lines[0]
	var o := s.one_button()
	assert_that(s.panel).is_equal(Rect2(84, 27, 152, 126))
	o.lines[0] = Rect2()
	assert_that(s.lines[0]).is_equal(line0)
