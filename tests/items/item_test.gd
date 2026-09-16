extends GdUnitTestSuite

func test_names_exact() -> void:
	assert_array(Item.NAMES).is_equal(["Driftwood", "Shellfish", "Coconut", "Empty shell", "Fresh water"])

func test_gain_line() -> void:
	assert_str(Item.gain_line(Item.Kind.DRIFTWOOD, 1)).is_equal("+1 Driftwood")
	assert_str(Item.gain_line(Item.Kind.FRESH_WATER, 1)).is_equal("+1 Fresh water")

func test_every_kind_has_a_10px_icon() -> void:
	for kind: int in Item.Kind.values():
		var icon := Item.icon_of(kind)
		assert_object(icon).is_not_null()
		assert_vector(Vector2(icon.get_size())).is_equal(Vector2(10, 10))
