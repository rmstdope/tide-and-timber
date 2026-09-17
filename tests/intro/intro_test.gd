extends GdUnitTestSuite
## The intro scene: the story's panels, taps, hold to skip and the pause box, driven by input.

const SCENE := "res://src/intro/intro.tscn"

var runner: GdUnitSceneRunner
var intro: Intro
var calls: Array[String] = []

func before_test() -> void:
	calls = []
	runner = scene_runner(SCENE)
	intro = runner.scene() as Intro
	var recorded := calls
	intro.end_story = func() -> void: recorded.append("end")

func after_test() -> void:
	get_tree().paused = false

func _node(unique: String) -> Node:
	return intro.get_node("%" + unique)

func _pause_node(unique: String) -> Node:
	return _node("Pause").get_node("%" + unique)

func _board() -> Control:
	return _pause_node("Board") as Control

func _highlighted(unique: String) -> void:
	assert_bool(is_same((_pause_node(unique) as Control).get_theme_stylebox("panel"), Pause.PLANK_HIGHLIGHT_STYLE)) \
		.override_failure_message(unique + " is not highlighted").is_true()

# gdUnit4's await_millis stops with the paused tree; this timer runs through a pause.
func _real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _tap(key: Key = KEY_SPACE) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_opens_black_on_the_first_caption() -> void:
	assert_str(_node("Caption").text).is_equal("Three weeks out of port.")
	assert_float(_node("PanelCover").modulate.a).is_greater(0.8)
	assert_bool(_node("SkipHint").visible).is_false()
	assert_bool(_board().visible).is_false()
	assert_float(_node("SkipCover").modulate.a).is_equal(0.0)
	assert_int(_node("Picture").picture).is_equal(0)

func test_taps_walk_the_captions_in_order() -> void:
	var captions := ["Then the storm found us.", "The mast gave way.", "..."]
	var bar_y := [138.0, 138.0, 79.0]
	for i in 3:
		await _tap()
		assert_str(_node("Caption").text).is_equal(captions[i])
		assert_int(_node("Picture").picture).is_equal(i + 1)
		assert_float(_node("CaptionBar").position.y).is_equal(bar_y[i])
	assert_bool(_node("TapMarker").visible).is_false()
	assert_array(calls).is_empty()
	await _tap()
	assert_array(calls).is_equal(["end"])

func test_enter_and_left_click_also_tap() -> void:
	await _tap(KEY_ENTER)
	assert_int(_node("Picture").picture).is_equal(1)
	await runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()
	assert_int(_node("Picture").picture).is_equal(2)

func test_first_press_shows_hold_to_skip() -> void:
	assert_bool(_node("SkipHint").visible).is_false()
	await _tap()
	assert_bool(_node("SkipHint").visible).is_true()
	assert_str((intro.get_node("SkipHint/Label") as Label).text).is_equal("Hold to skip")

func test_release_carried_over_from_the_title_is_ignored() -> void:
	runner.simulate_key_release(KEY_ENTER)
	await runner.await_input_processed()
	assert_int(_node("Picture").picture).is_equal(0)
	assert_bool(_node("SkipHint").visible).is_false()

func test_holding_space_fills_the_ring_and_skips() -> void:
	runner.simulate_key_press(KEY_SPACE)
	await runner.await_input_processed()
	intro.tick(0.5)
	assert_float(_node("SkipRing").progress).is_between(0.5, 0.7)
	assert_array(calls).is_empty()
	intro.tick(0.6)
	assert_int(intro.story.phase).is_equal(IntroStory.Phase.SKIPPING)
	intro.tick(0.6)
	assert_array(calls).is_equal(["end"])
	assert_float(_node("SkipCover").modulate.a).is_equal(1.0)
	runner.simulate_key_release(KEY_SPACE)
	await runner.await_input_processed()
	assert_int(_node("Picture").picture).is_equal(0)

func test_holding_the_mouse_button_skips() -> void:
	runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()
	intro.tick(0.5)
	assert_float(_node("SkipRing").progress).is_between(0.5, 0.7)
	intro.tick(0.6)
	intro.tick(0.6)
	assert_array(calls).is_equal(["end"])
	runner.simulate_mouse_button_release(MOUSE_BUTTON_LEFT)
	await runner.await_input_processed()
	assert_int(_node("Picture").picture).is_equal(0)

func _click_item(unique: String, button: MouseButton) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = true
	(_pause_node(unique) as Control).gui_input.emit(click)

func test_escape_pauses_on_the_four_plank_board() -> void:
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_true()
	assert_int(intro.story.phase).is_equal(IntroStory.Phase.PAUSED)
	assert_bool(_board().visible).is_true()
	assert_str((_pause_node("Panel").get_node("Heading") as Label).text).is_equal("Paused")
	var words := {"Resume": "Resume", "SkipStory": "Skip story", "Settings": "Settings", "QuitToTitle": "Quit to title"}
	for unique: String in words:
		assert_str((_pause_node(unique).get_node("Label") as Label).text).is_equal(words[unique])
		assert_bool((_pause_node(unique) as Control).visible).is_true()
	_highlighted("Resume")
	assert_that((_pause_node("Panel") as Control).get_rect()).is_equal(Rect2(88, 32, 144, 116))
	intro.tick(10.0)
	assert_int(_node("Picture").picture).is_equal(0)
	assert_array(calls).is_empty()

func test_pausing_mid_hold_clears_the_ring() -> void:
	runner.simulate_key_press(KEY_SPACE)
	await runner.await_input_processed()
	intro.tick(0.5)
	await _tap(KEY_ESCAPE)
	assert_float(_node("SkipRing").progress).is_equal(0.0)

func test_escape_again_resumes() -> void:
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ESCAPE)
	assert_bool(_board().visible).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_int(intro.story.phase).is_equal(IntroStory.Phase.PLAYING)

func test_down_and_enter_choose_skip_story() -> void:
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	_highlighted("SkipStory")
	await _tap(KEY_ENTER)
	assert_int(intro.story.phase).is_equal(IntroStory.Phase.SKIPPING)
	assert_bool(get_tree().paused).is_false()
	assert_bool(_board().visible).is_false()
	intro.tick(0.6)
	assert_array(calls).is_equal(["end"])

func test_up_wraps_in_the_pause_box() -> void:
	await _tap(KEY_ESCAPE)
	await _tap(KEY_UP)
	_highlighted("QuitToTitle")

func test_hover_and_click_in_the_pause_box() -> void:
	await _tap(KEY_ESCAPE)
	(_pause_node("SkipStory") as Control).mouse_entered.emit()
	_highlighted("SkipStory")
	_click_item("Resume", MOUSE_BUTTON_LEFT)
	assert_int(intro.story.phase).is_equal(IntroStory.Phase.PLAYING)
	assert_bool(get_tree().paused).is_false()

func test_clicking_skip_story_skips() -> void:
	await _tap(KEY_ESCAPE)
	_click_item("SkipStory", MOUSE_BUTTON_LEFT)
	intro.tick(0.6)
	assert_array(calls).is_equal(["end"])

func test_right_click_on_a_pause_item_does_nothing() -> void:
	await _tap(KEY_ESCAPE)
	_click_item("SkipStory", MOUSE_BUTTON_RIGHT)
	assert_int(intro.story.phase).is_equal(IntroStory.Phase.PAUSED)

func test_quit_box_in_the_story_says_nothing_saved() -> void:
	await _tap(KEY_ESCAPE)
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)
	assert_bool((_pause_node("QuitBox") as Control).visible).is_true()
	assert_str((_pause_node("SecondLine") as Label).text).is_equal("Nothing has been saved yet.")
	_highlighted("Stay")

func test_quit_from_the_story_opens_the_title() -> void:
	var recorded := calls
	(_node("Pause") as Pause).quit_to_title = func() -> void: recorded.append("title")
	await _tap(KEY_ESCAPE)
	await _tap(KEY_UP)
	await _tap(KEY_ENTER)
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	await _real_seconds(1.2)
	assert_array(calls).is_equal(["title"])

func test_no_pause_while_skipping() -> void:
	runner.simulate_key_press(KEY_SPACE)
	await runner.await_input_processed()
	intro.tick(1.1)
	assert_int(intro.story.phase).is_equal(IntroStory.Phase.SKIPPING)
	await _tap(KEY_ESCAPE)
	assert_bool(get_tree().paused).is_false()
	runner.simulate_key_release(KEY_SPACE)
	await runner.await_input_processed()

func test_losing_focus_pauses_the_story() -> void:
	_node("Pause").notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_int(intro.story.phase).is_equal(IntroStory.Phase.PAUSED)
	assert_bool(get_tree().paused).is_true()

func test_surf_follows_the_black_beat() -> void:
	var surf := _node("Surf") as SurfSound
	assert_bool(surf.audible).is_false()
	for i in 3:
		await _tap()
	assert_bool(surf.audible).is_true()
	assert_bool(surf.stream_paused).is_false()
	await _tap(KEY_ESCAPE)
	assert_bool(surf.audible).is_false()
	assert_bool(surf.stream_paused).is_true()

func test_story_ends_on_the_beach_waking() -> void:
	assert_str(Intro.WAKING_SCENE).is_equal("res://src/waking/waking.tscn")
	assert_bool(ResourceLoader.exists(Intro.WAKING_SCENE)).is_true()
	if ResourceLoader.exists(Intro.WAKING_SCENE):
		assert_bool((load(Intro.WAKING_SCENE) as PackedScene).can_instantiate()).is_true()
