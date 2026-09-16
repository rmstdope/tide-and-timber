extends GdUnitTestSuite

func test_puff_fades_and_frees() -> void:
	var mark := auto_free(load("res://src/beach/marks/puff.tscn").instantiate()) as TrailMark
	add_child(mark)
	assert_float(mark.modulate.a).is_equal_approx(0.8, 0.01)
	await await_millis(600)
	assert_bool(is_instance_valid(mark)).is_false()

func test_ripple_grows_and_lasts_longer() -> void:
	var mark := auto_free(load("res://src/beach/marks/ripple.tscn").instantiate()) as TrailMark
	add_child(mark)
	assert_float(mark.lifetime).is_equal(0.8)
	assert_float(mark.grow).is_equal(1.5)
	await await_millis(400)
	assert_bool(is_instance_valid(mark)).is_true()
	assert_float(mark.scale.x).is_greater(1.0)
	await await_millis(700)
	assert_bool(is_instance_valid(mark)).is_false()
