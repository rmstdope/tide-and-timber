extends GdUnitTestSuite
## The shipwreck story's rules: panels, taps, hold to skip and the pause box.

var s: IntroStory
var ends: Array[String] = []

func before_test() -> void:
	s = IntroStory.new()
	ends = []
	var recorded := ends
	s.finished.connect(func() -> void: recorded.append("end"))

func _approx(value: float, expected: float) -> void:
	assert_float(value).is_equal_approx(expected, 0.001)

func _hold_to_skip() -> void:
	s.press()
	s.advance(1.0)

func _tap() -> void:
	s.press()
	s.advance(0.1)
	s.release()

func _to_black_beat() -> void:
	for i in 3:
		s.advance(6.0)

func test_starts_black_on_the_first_picture() -> void:
	assert_int(s.phase).is_equal(IntroStory.Phase.PLAYING)
	assert_int(s.panel).is_equal(0)
	assert_bool(s.skip_hint_shown).is_false()
	_approx(s.hold_progress, 0.0)
	_approx(s.panel_cover_alpha(), 1.0)
	_approx(s.skip_cover_alpha(), 0.0)

func test_picture_fades_in_over_half_a_second() -> void:
	s.advance(0.25)
	_approx(s.panel_cover_alpha(), 0.5)
	s.advance(0.25)
	_approx(s.panel_cover_alpha(), 0.0)

func test_picture_moves_on_after_six_seconds() -> void:
	s.advance(5.9)
	assert_int(s.panel).is_equal(0)
	s.advance(0.2)
	assert_int(s.panel).is_equal(1)
	_approx(s.panel_elapsed, 0.0)
	_approx(s.panel_cover_alpha(), 1.0)

func test_first_press_shows_the_skip_hint_without_moving_on() -> void:
	s.press()
	assert_bool(s.skip_hint_shown).is_true()
	assert_int(s.panel).is_equal(0)

func test_short_press_is_a_tap() -> void:
	_tap()
	assert_int(s.panel).is_equal(1)

func test_hold_fills_the_ring_in_one_second_then_skips() -> void:
	s.press()
	s.advance(0.5)
	_approx(s.hold_progress, 0.5)
	assert_int(s.phase).is_equal(IntroStory.Phase.PLAYING)
	s.advance(0.5)
	assert_int(s.phase).is_equal(IntroStory.Phase.SKIPPING)
	_approx(s.hold_progress, 1.0)
	s.release()
	assert_int(s.panel).is_equal(0)

func test_early_release_drains_and_does_not_move_on() -> void:
	s.press()
	s.advance(0.6)
	s.release()
	assert_int(s.panel).is_equal(0)
	_approx(s.hold_progress, 0.6)
	s.advance(0.3)
	_approx(s.hold_progress, 0.3)
	s.advance(1.0)
	_approx(s.hold_progress, 0.0)
	assert_int(s.phase).is_equal(IntroStory.Phase.PLAYING)

func test_two_held_inputs_skip_only_after_both_release_or_full() -> void:
	s.press()
	s.press()
	s.advance(0.1)
	s.release()
	assert_int(s.panel).is_equal(0)
	s.advance(1.0)
	assert_int(s.phase).is_equal(IntroStory.Phase.SKIPPING)

func test_skip_fades_for_half_a_second_then_finishes_once() -> void:
	_hold_to_skip()
	s.advance(0.25)
	_approx(s.skip_cover_alpha(), 0.5)
	assert_array(ends).is_empty()
	s.advance(0.25)
	assert_int(s.phase).is_equal(IntroStory.Phase.FINISHED)
	assert_array(ends).is_equal(["end"])
	_approx(s.skip_cover_alpha(), 1.0)
	s.advance(5.0)
	assert_array(ends).is_equal(["end"])

func test_watched_through_finishes_after_the_black_beat() -> void:
	_to_black_beat()
	assert_int(s.panel).is_equal(3)
	assert_array(ends).is_empty()
	s.advance(6.0)
	assert_array(ends).is_equal(["end"])
	assert_int(s.panel).is_equal(3)
	_approx(s.skip_cover_alpha(), 1.0)

func test_tap_on_the_black_beat_finishes() -> void:
	_to_black_beat()
	_tap()
	assert_array(ends).is_equal(["end"])

func test_presses_after_finish_do_nothing() -> void:
	_to_black_beat()
	s.advance(6.0)
	s.press()
	s.advance(1.0)
	s.release()
	s.toggle_pause()
	assert_int(s.phase).is_equal(IntroStory.Phase.FINISHED)
	assert_array(ends).has_size(1)

func test_pause_freezes_the_story_and_clears_the_ring() -> void:
	s.press()
	s.advance(0.5)
	s.toggle_pause()
	assert_int(s.phase).is_equal(IntroStory.Phase.PAUSED)
	_approx(s.hold_progress, 0.0)
	assert_int(s.held_count).is_equal(0)
	s.advance(10.0)
	assert_int(s.panel).is_equal(0)
	_approx(s.panel_elapsed, 0.5)
	s.release()
	s.press()
	assert_int(s.held_count).is_equal(0)
	assert_int(s.panel).is_equal(0)
	assert_bool(s.skip_hint_shown).is_true()

func test_pause_again_resumes_where_it_stopped() -> void:
	s.advance(2.0)
	s.toggle_pause()
	s.toggle_pause()
	assert_int(s.phase).is_equal(IntroStory.Phase.PLAYING)
	_approx(s.panel_elapsed, 2.0)
	s.advance(4.0)
	assert_int(s.panel).is_equal(1)

func test_skip_from_pause_does_what_a_full_ring_does() -> void:
	s.toggle_pause()
	s.skip()
	assert_int(s.phase).is_equal(IntroStory.Phase.SKIPPING)
	_approx(s.skip_cover_alpha(), 0.0)
	s.advance(0.5)
	assert_array(ends).is_equal(["end"])

func test_skip_does_nothing_unless_paused() -> void:
	s.skip()
	assert_int(s.phase).is_equal(IntroStory.Phase.PLAYING)

func test_pause_does_nothing_while_skipping() -> void:
	_hold_to_skip()
	s.toggle_pause()
	assert_int(s.phase).is_equal(IntroStory.Phase.SKIPPING)

func test_tap_marker_blinks_on_pictures_only() -> void:
	s.advance(0.2)
	assert_bool(s.tap_marker_visible()).is_true()
	s.advance(0.5)
	assert_bool(s.tap_marker_visible()).is_false()
	s.advance(0.5)
	assert_bool(s.tap_marker_visible()).is_true()
	s.advance(6.0)
	s.advance(6.0)
	s.advance(6.0)
	assert_int(s.panel).is_equal(3)
	s.advance(0.1)
	assert_bool(s.tap_marker_visible()).is_false()

func test_surf_is_audible_on_the_black_beat_only() -> void:
	for i in 3:
		assert_bool(s.surf_audible()).is_false()
		s.advance(6.0)
	assert_int(s.panel).is_equal(3)
	assert_bool(s.surf_audible()).is_true()
	s.toggle_pause()
	assert_bool(s.surf_audible()).is_false()
	s.toggle_pause()
	_hold_to_skip()
	assert_int(s.phase).is_equal(IntroStory.Phase.SKIPPING)
	assert_bool(s.surf_audible()).is_true()
	s.advance(0.5)
	assert_bool(s.surf_audible()).is_false()
