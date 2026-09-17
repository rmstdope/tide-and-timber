extends GdUnitTestSuite
## The colour maths the colour-blind recheck rests on.

const Sight := ColourSight.Sight

func test_a_colour_is_itself_to_normal_sight() -> void:
	for hex: String in ["#e40b29", "#f78b54", "#fff6e4"]:
		var c := Color(hex)
		assert_str(ColourSight.seen(c, Sight.NORMAL).to_html(false)).is_equal(c.to_html(false))
		assert_float(ColourSight.distance(c, c, Sight.NORMAL)).is_equal_approx(0.0, 0.01)

func test_red_and_green_close_up_for_deutan_sight() -> void:
	var red := Color("#e40b29")
	var green := Color("#306b05")
	var normal := ColourSight.distance(red, green, Sight.NORMAL)
	var deutan := ColourSight.distance(red, green, Sight.DEUTAN)
	assert_float(deutan).is_less(normal)
	assert_float(deutan).is_less(40.0)

func test_worst_distance_is_the_smallest_of_the_four() -> void:
	var red := Color("#e40b29")
	var green := Color("#306b05")
	var smallest := INF
	for sight: Sight in [Sight.NORMAL, Sight.PROTAN, Sight.DEUTAN, Sight.TRITAN]:
		smallest = minf(smallest, ColourSight.distance(red, green, sight))
	assert_float(ColourSight.worst_distance(red, green)).is_equal_approx(smallest, 0.001)

func test_contrast_is_the_wcag_ratio() -> void:
	assert_float(ColourSight.contrast(Color.WHITE, Color.BLACK)).is_equal_approx(21.0, 0.01)
	var a := Color("#865932")
	var b := Color("#fff6e4")
	assert_float(ColourSight.contrast(a, b)).is_equal_approx(ColourSight.contrast(b, a), 0.001)

func test_over_lays_one_colour_on_another() -> void:
	var half := ColourSight.over(Color.WHITE, Color.BLACK, 0.5)
	assert_float(half.r).is_equal_approx(0.5, 0.01)
	assert_float(half.g).is_equal_approx(0.5, 0.01)
	assert_float(half.b).is_equal_approx(0.5, 0.01)
	assert_bool(ColourSight.over(Color.WHITE, Color.BLACK, 1.0).is_equal_approx(Color.WHITE)).is_true()
	assert_bool(ColourSight.over(Color.WHITE, Color.BLACK, 0.0).is_equal_approx(Color.BLACK)).is_true()
