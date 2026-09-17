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
