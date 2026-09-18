extends GdUnitTestSuite
## The live display settings: one DisplayPrefs every view reads, and a changed signal they redraw on.

const S := DisplayPrefs.Setting

func after_test() -> void:
	Display.use_prefs(DisplayPrefs.new())

func test_the_gate_run_never_touches_the_real_file() -> void:
	assert_object(Display.prefs).is_not_null()
	assert_str(Display.prefs.path).is_equal("")
	assert_str(Display.startup_path(get_tree())).is_equal("")

func test_use_prefs_tells_every_view() -> void:
	var fired := [0]
	var count := func() -> void: fired[0] += 1
	Display.changed.connect(count)
	Display.use_prefs(DisplayPrefs.new())
	Display.changed.disconnect(count)
	assert_int(fired[0]).is_equal(1)

func test_changes_are_relayed() -> void:
	var p := DisplayPrefs.new()
	Display.use_prefs(p)
	var fired := [0]
	var count := func() -> void: fired[0] += 1
	Display.changed.connect(count)
	p.step(S.UI_SIZE, 1)
	assert_int(fired[0]).is_equal(1)
	p.step(S.UI_SIZE, 5)
	assert_int(fired[0]).is_equal(2)
	p.step(S.UI_SIZE, 1)
	Display.changed.disconnect(count)
	assert_int(fired[0]).is_equal(2)

func test_old_prefs_are_let_go() -> void:
	var old := DisplayPrefs.new()
	Display.use_prefs(old)
	Display.use_prefs(DisplayPrefs.new())
	var fired := [0]
	var count := func() -> void: fired[0] += 1
	Display.changed.connect(count)
	old.step(S.CUES, 1)
	Display.changed.disconnect(count)
	assert_int(fired[0]).is_equal(0)

func test_registered_after_input_device() -> void:
	assert_str(ProjectSettings.get_setting("autoload/Display")).is_equal("*res://src/settings/display.gd")
	var root := get_tree().root
	assert_int(root.get_node("Display").get_index()).is_greater(root.get_node("InputDevice").get_index())

func test_toggle_fullscreen_flips_and_announces() -> void:
	Display.use_prefs(DisplayPrefs.new())
	var fired := [0]
	var count := func() -> void: fired[0] += 1
	Display.changed.connect(count)
	Display.toggle_fullscreen()
	assert_bool(Display.prefs.fullscreen).is_true()
	assert_int(fired[0]).is_equal(1)
	Display.toggle_fullscreen()
	Display.changed.disconnect(count)
	assert_bool(Display.prefs.fullscreen).is_false()
	assert_int(fired[0]).is_equal(2)

func test_sync_from_window_follows_the_os() -> void:
	Display.use_prefs(DisplayPrefs.new())
	Display.sync_from_window(Window.MODE_FULLSCREEN)
	assert_bool(Display.prefs.fullscreen).is_true()
	Display.sync_from_window(Window.MODE_WINDOWED)
	assert_bool(Display.prefs.fullscreen).is_false()

func test_minimised_is_ignored() -> void:
	Display.use_prefs(DisplayPrefs.new())
	Display.prefs.set_fullscreen(true)
	Display.sync_from_window(Window.MODE_MINIMIZED)
	assert_bool(Display.prefs.fullscreen).is_true()

func test_is_fullscreen_and_mode_for() -> void:
	assert_bool(Display.is_fullscreen(Window.MODE_WINDOWED)).is_false()
	assert_bool(Display.is_fullscreen(Window.MODE_MINIMIZED)).is_false()
	assert_bool(Display.is_fullscreen(Window.MODE_MAXIMIZED)).is_false()
	assert_bool(Display.is_fullscreen(Window.MODE_FULLSCREEN)).is_true()
	assert_bool(Display.is_fullscreen(Window.MODE_EXCLUSIVE_FULLSCREEN)).is_true()
	assert_int(Display.mode_for(true)).is_equal(Window.MODE_FULLSCREEN)
	assert_int(Display.mode_for(false)).is_equal(Window.MODE_WINDOWED)
