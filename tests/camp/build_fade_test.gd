extends GdUnitTestSuite
## The build's black: fade out, hold, fade in.

const P := BuildFade.Phase

var fade: BuildFade
var seen: Array[String] = []

func before_test() -> void:
	seen = []
	fade = BuildFade.new()
	fade.went_black.connect(func() -> void: seen.append("went_black"))
	fade.black_ended.connect(func() -> void: seen.append("black_ended"))
	fade.finished.connect(func() -> void: seen.append("finished"))

func test_starts_fading_out_transparent() -> void:
	assert_int(fade.phase).is_equal(P.FADING_OUT)
	assert_float(fade.cover_alpha()).is_equal(0.0)

func test_alpha_through_phases() -> void:
	fade.advance(0.25)
	assert_float(fade.cover_alpha()).is_equal_approx(0.5, 0.001)
	fade.advance(0.25)
	assert_int(fade.phase).is_equal(P.BLACK)
	assert_float(fade.cover_alpha()).is_equal(1.0)
	assert_array(seen).is_equal(["went_black"])
	fade.advance(4.9)
	assert_int(fade.phase).is_equal(P.BLACK)
	fade.advance(0.1)
	assert_int(fade.phase).is_equal(P.FADING_IN)
	assert_float(fade.cover_alpha()).is_equal_approx(1.0, 0.001)
	assert_array(seen).is_equal(["went_black", "black_ended"])
	fade.advance(0.25)
	assert_float(fade.cover_alpha()).is_equal_approx(0.5, 0.001)
	fade.advance(0.25)
	assert_int(fade.phase).is_equal(P.DONE)
	assert_float(fade.cover_alpha()).is_equal(0.0)
	assert_array(seen).is_equal(["went_black", "black_ended", "finished"])

func test_one_huge_step_emits_each_once_in_order() -> void:
	fade.advance(100.0)
	assert_array(seen).is_equal(["went_black", "black_ended", "finished"])
	fade.advance(1.0)
	assert_int(seen.size()).is_equal(3)
