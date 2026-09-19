extends GdUnitTestSuite
## The one plain plate every row is drawn on, and the colour of the words on it.

func test_the_plate_is_wood_with_a_one_pixel_dark_edge() -> void:
	var s := Plate.STYLE
	assert_bool(s.bg_color.is_equal_approx(HudColours.WOOD)).is_true()
	assert_bool(s.border_color.is_equal_approx(HudColours.WOOD_DARK)).is_true()
	for w: int in [s.border_width_left, s.border_width_top, s.border_width_right, s.border_width_bottom]:
		assert_int(w).is_equal(1)
	assert_bool(s.anti_aliasing).is_false()

func test_the_chosen_plate_is_light_wood_with_a_pale_edge() -> void:
	var s := Plate.CHOSEN_STYLE
	assert_bool(s.bg_color.is_equal_approx(HudColours.WOOD_LIGHT)).is_true()
	assert_bool(s.border_color.is_equal_approx(HudColours.PALE)).is_true()
	for w: int in [s.border_width_left, s.border_width_top, s.border_width_right, s.border_width_bottom]:
		assert_int(w).is_equal(1)
	assert_bool(s.anti_aliasing).is_false()

func test_plates_keep_todays_margins() -> void:
	for s: StyleBoxFlat in [Plate.STYLE, Plate.CHOSEN_STYLE]:
		assert_that(s.get_minimum_size()).is_equal(Vector2(4, 4))
		for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			assert_float(s.get_content_margin(side)).is_equal(2.0)

func test_words() -> void:
	assert_that(Plate.words(true)).is_equal(HudColours.INK)
	assert_that(Plate.words(false)).is_equal(HudColours.CREAM)
	assert_that(Plate.words(false, true)).is_equal(HudColours.DIM)
	assert_that(Plate.words(true, true)).is_equal(HudColours.INK)

func test_style() -> void:
	assert_object(Plate.style(true)).is_same(Plate.CHOSEN_STYLE)
	assert_object(Plate.style(false)).is_same(Plate.STYLE)

func test_paint_styles_the_row_and_colours_every_words_label() -> void:
	var p: PanelContainer = auto_free(PanelContainer.new())
	var labels: Array[Label] = []
	for n in 2:
		var holder := Control.new()
		var words := Label.new()
		words.name = "Words"
		holder.add_child(words)
		p.add_child(holder)
		labels.append(words)
	Plate.paint(p, true)
	assert_object(p.get_theme_stylebox("panel")).is_same(Plate.CHOSEN_STYLE)
	for l in labels:
		assert_that(l.get_theme_color("font_color")).is_equal(HudColours.INK)
		assert_that(l.get_theme_color("font_shadow_color")).is_equal(Color(0, 0, 0, 0))
	Plate.paint(p, false, true)
	assert_object(p.get_theme_stylebox("panel")).is_same(Plate.STYLE)
	for l in labels:
		assert_that(l.get_theme_color("font_color")).is_equal(HudColours.DIM)

func test_there_is_no_dimmed_plate() -> void:
	assert_bool(ResourceLoader.exists("res://src/title/plank_dimmed.tres")).is_false()
