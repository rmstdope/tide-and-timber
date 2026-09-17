extends GdUnitTestSuite
## The Debug panel's Story page in the shipwreck story: it works there, starred on Shipwreck story.

const P := StoryPoints.Point

var runner: GdUnitSceneRunner
var intro: Intro
var pause: Pause
var jumps: Array = []

func before_test() -> void:
	Pause.debug_tools = true
	jumps = []
	runner = scene_runner("res://src/intro/intro.tscn")
	intro = runner.scene() as Intro
	intro.end_story = func() -> void: pass
	intro.enter_story = func(p: StoryPoints.Point) -> void: jumps.append(p)
	pause = intro.get_node("%Pause")

func after_test() -> void:
	get_tree().paused = false
	Pause.debug_tools = OS.is_debug_build()
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func test_story_page_in_the_story_stars_shipwreck_and_jumps() -> void:
	await _tap(KEY_ESCAPE)
	for i in 3:
		await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	for i in 3:
		await _tap(KEY_E)
	var panel := pause.get_node("%DebugPanel") as DebugPanel
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.STORY)
	assert_bool(panel.rules.in_story).is_true()
	assert_array(panel.rules.rows_of(DebugMenu.Page.STORY).map(func(r: DebugRow) -> String: return r.value_text())) \
		.is_equal(["★", "", "", "", ""])
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	assert_bool(get_tree().paused).is_true()
	assert_bool(panel.visible).is_false()
	assert_bool((pause.get_node("%Board") as CanvasItem).visible).is_false()
	await _real_seconds(1.2)
	assert_array(jumps).is_equal([P.WAKING])
