extends GdUnitTestSuite

func test_width() -> void:
	assert_int(Glyphs.width("")).is_equal(0)
	assert_int(Glyphs.width("7")).is_equal(3)
	assert_int(Glyphs.width("999")).is_equal(11)

func test_three_digits_fit_the_slot_corner() -> void:
	assert_bool(15 - Glyphs.width("999") >= 1).is_true()

func test_order_has_the_hint_letters() -> void:
	assert_str(Glyphs.ORDER).is_equal("0123456789EABDLSWXYsc✕○△")

func test_esc_width() -> void:
	assert_int(Glyphs.width("Esc")).is_equal(11)
