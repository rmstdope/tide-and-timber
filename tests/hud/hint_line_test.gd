extends GdUnitTestSuite
## Measuring a hint line: picture sizes, gaps and words.

const K := DeviceTracker.Kind
const H := DeviceHints.Hint
const S := DeviceHints.Shape

var font: Font = load("res://assets/fonts/PressStart2P-Regular.ttf")

func _picture(shape: DeviceHints.Shape, label: String) -> DeviceHints.Picture:
	return DeviceHints.Picture.new(shape, label, Color.WHITE, Color.BLACK)

func test_key_cap_widths() -> void:
	assert_int(HintLine.picture_width(_picture(S.KEY, "E"))).is_equal(9)
	assert_int(HintLine.picture_width(_picture(S.KEY, "Esc"))).is_equal(17)
	assert_int(HintLine.picture_width(_picture(S.KEY, "Enter"))).is_equal(25)
	assert_int(HintLine.picture_width(_picture(S.ROUND, "A"))).is_equal(9)
	assert_int(HintLine.picture_width(_picture(S.STICK, "L"))).is_equal(9)

func test_line_widths() -> void:
	assert_int(HintLine.width(DeviceHints.line(H.BUILD_LIST, K.KEYBOARD), font)).is_equal(124)
	assert_int(HintLine.width(DeviceHints.line(H.BUILD_LIST, K.XBOX), font)).is_equal(116)
	assert_int(HintLine.width(DeviceHints.line(H.MOVE, K.KEYBOARD), font)).is_equal(74)

func test_longest_hint_fits_the_picture() -> void:
	for kind: DeviceTracker.Kind in K.values():
		assert_int(HintLine.width(DeviceHints.line(H.PLACING, kind), font) + 8).is_less_equal(320)
		assert_int(HintLine.width(DeviceHints.line(H.BUILD_LIST, kind), font) + 8).is_less_equal(320)

func test_shoulder_width_is_label_plus_six() -> void:
	assert_int(HintLine.picture_width(_picture(S.SHOULDER, "LB"))).is_equal(Glyphs.width("LB") + 6)
	assert_int(HintLine.picture_width(_picture(S.SHOULDER, "Start"))).is_equal(Glyphs.width("Start") + 6)

func test_menu_line_widths() -> void:
	assert_int(HintLine.width(DeviceHints.line(H.SELECT, K.KEYBOARD), font)).is_equal(76)
	assert_int(HintLine.width(DeviceHints.line(H.SELECT_BACK, K.KEYBOARD), font)).is_equal(140)
	assert_int(HintLine.width(DeviceHints.line(H.SELECT_BACK, K.XBOX), font)).is_equal(116)
