extends GdUnitTestSuite
## The foam washing up the wet sand while he wakes.

func test_wash_rises_and_falls_every_four_seconds() -> void:
	assert_int(WaveWash.reach_at(0.0)).is_equal(0)
	assert_int(WaveWash.reach_at(2.0)).is_equal(10)
	assert_int(WaveWash.reach_at(4.0)).is_equal(0)
	for i in 17:
		assert_int(WaveWash.reach_at(i * 0.25)).is_between(0, 10)

func test_wash_runs_up_the_wet_sand_of_the_walkable_beach() -> void:
	assert_int(BeachLayout.kind_at(Vector2i(92, WaveWash.FOAM_ROW))).is_equal(BeachLayout.Kind.FOAM)
	assert_int(BeachLayout.kind_at(Vector2i(92, WaveWash.FOAM_ROW - 1))).is_equal(BeachLayout.Kind.WET_SAND)
	assert_int(BeachLayout.kind_at(Vector2i(WaveWash.FIRST_COLUMN, 12))).is_equal(BeachLayout.Kind.SAND)
	assert_int(BeachLayout.kind_at(Vector2i(WaveWash.LAST_COLUMN, 12))).is_equal(BeachLayout.Kind.SAND)
	assert_int(WaveWash.REACH).is_less(BeachLayout.TILE)
