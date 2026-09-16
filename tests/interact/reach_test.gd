extends GdUnitTestSuite

const RIGHT := Vector2(1, 0)
const UP := Vector2(0, -1)

func _spots(points: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	out.assign(points)
	return out

func test_nothing_in_range() -> void:
	assert_int(Reach.pick(Vector2.ZERO, RIGHT, _spots([Vector2(21, 0)]))).is_equal(-1)
	assert_int(Reach.pick(Vector2.ZERO, RIGHT, _spots([]))).is_equal(-1)

func test_faced_beats_closer_unfaced() -> void:
	assert_int(Reach.pick(Vector2.ZERO, RIGHT, _spots([Vector2(-5, 0), Vector2(15, 0)]))).is_equal(1)

func test_closest_when_none_faced() -> void:
	assert_int(Reach.pick(Vector2.ZERO, UP, _spots([Vector2(-15, 0), Vector2(10, 0)]))).is_equal(1)

func test_closest_faced_among_faced() -> void:
	assert_int(Reach.pick(Vector2.ZERO, RIGHT, _spots([Vector2(18, 0), Vector2(12, 3)]))).is_equal(1)

func test_on_spot_counts_as_faced() -> void:
	assert_int(Reach.pick(Vector2.ZERO, UP, _spots([Vector2(0, 1), Vector2(0, -15)]))).is_equal(0)

func test_tie_goes_to_lower_index() -> void:
	assert_int(Reach.pick(Vector2.ZERO, UP, _spots([Vector2(10, 0), Vector2(-10, 0)]))).is_equal(0)

func test_edge_of_range_included() -> void:
	assert_int(Reach.pick(Vector2.ZERO, RIGHT, _spots([Vector2(20, 0)]))).is_equal(0)
