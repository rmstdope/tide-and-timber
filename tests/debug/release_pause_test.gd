extends GdUnitTestSuite
## A release build's pause board: no Debug plank, no DEV tag, no Debug panel.

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause

func before_test() -> void:
	Pause.debug_tools = false
	InputDevice.reset()
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	get_tree().paused = false
	Pause.debug_tools = OS.is_debug_build()
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func test_release_build_has_no_debug() -> void:
	await runner.simulate_frames(1)
	assert_array(pause.rules.items).is_equal([PauseMenu.Plank.RESUME, PauseMenu.Plank.SETTINGS, PauseMenu.Plank.QUIT_TO_TITLE])
	assert_object(pause.get_node_or_null("%Debug")).is_null()
	assert_object(pause.get_node_or_null("%DevTag")).is_null()
	assert_object(pause.get_node_or_null("%DebugPanel")).is_null()
	assert_object(pause.debug_menu()).is_null()
	waking.tick(5.0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	assert_int(pause.rules.highlighted).is_equal(PauseMenu.Plank.RESUME)
