extends GdUnitTestSuite

func _fire() -> CampFire:
	var f := CampFire.new()
	add_child(auto_free(f))
	return f

func test_new_fire_is_lit_with_glow() -> void:
	var f := _fire()
	assert_bool(f.lit).is_true()
	assert_float(f.out_at).is_equal(INF)
	assert_object(f.glow).is_not_null()
	assert_bool(f.glow.visible).is_true()
	assert_object(f.glow.color).is_equal(Color("#ffc060"))
	assert_bool(is_equal_approx(f.glow.energy, 0.7)).is_true()
	assert_vector(f.glow.position).is_equal(Vector2(0, -8))

func test_glow_texture_spans_the_radius() -> void:
	var f := _fire()
	assert_bool(f.glow.texture is GradientTexture2D).is_true()
	var tex := f.glow.texture as GradientTexture2D
	assert_int(tex.width).is_equal(96)
	assert_int(tex.height).is_equal(96)
	assert_int(tex.fill).is_equal(GradientTexture2D.FILL_RADIAL)
	assert_vector(tex.fill_to).is_equal(Vector2(1.0, 0.5))
	assert_float(tex.gradient.get_color(1).a).is_equal(0.0)

func test_put_out_leaves_ash_without_glow() -> void:
	var f := _fire()
	f.put_out()
	assert_bool(f.lit).is_false()
	assert_bool(f.glow.visible).is_false()

func test_light_centre() -> void:
	var f := _fire()
	f.global_position = Vector2(1480, 240)
	assert_vector(f.light_centre()).is_equal(Vector2(1480, 232))

func test_constants() -> void:
	assert_float(CampFire.LIGHT_RADIUS).is_equal(48.0)
	assert_object(CampArt.ASH_DARK).is_equal(Color("#6a625c"))
	assert_object(CampArt.ASH).is_equal(Color("#8a827a"))
