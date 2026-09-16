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

func _node(unique: String) -> Node:
	return intro.get_node("%" + unique)

func _tap(key: Key = KEY_SPACE) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_opens_black_on_the_first_caption() -> void:
	assert_str(_node("Caption").text).is_equal("Three weeks out of port.")
	assert_float(_node("PanelCover").modulate.a).is_greater(0.8)
	assert_bool(_node("SkipHint").visible).is_false()
	assert_bool(_node("PauseBox").visible).is_false()
	assert_bool(_node("PauseDim").visible).is_false()
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
