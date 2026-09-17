extends GdUnitTestSuite
## The display settings model: three values, steps that stop at the ends, and a file read all or nothing.

const DIR := "user://test_display"
const FILE := "user://test_display/display.json"
const S := DisplayPrefs.Setting

func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)

func after_test() -> void:
	if FileAccess.file_exists(FILE):
		DirAccess.remove_absolute(FILE)
	DirAccess.remove_absolute(DIR)

func _write(text: String) -> void:
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _read() -> String:
	return FileAccess.get_file_as_string(FILE)

func _assert_defaults(p: DisplayPrefs, why: String = "") -> void:
	assert_int(p.ui_size).override_failure_message("ui_size %s" % why).is_equal(DisplayPrefs.Size.NORMAL)
	assert_int(p.text_size).override_failure_message("text_size %s" % why).is_equal(DisplayPrefs.Size.NORMAL)
	assert_int(p.cues).override_failure_message("cues %s" % why).is_equal(DisplayPrefs.Cues.STANDARD)

func test_starts_at_normal_normal_standard() -> void:
	var p := DisplayPrefs.new()
	_assert_defaults(p)
	assert_str(p.path).is_equal("")

func test_counts() -> void:
	assert_int(DisplayPrefs.count(S.UI_SIZE)).is_equal(3)
	assert_int(DisplayPrefs.count(S.TEXT_SIZE)).is_equal(3)
	assert_int(DisplayPrefs.count(S.CUES)).is_equal(2)

func test_step_moves_one_and_stops_at_the_ends() -> void:
	var p := DisplayPrefs.new()
	assert_bool(p.step(S.UI_SIZE, 1)).is_true()
	assert_int(p.ui_size).is_equal(DisplayPrefs.Size.LARGE)
	assert_bool(p.step(S.UI_SIZE, 1)).is_true()
	assert_int(p.ui_size).is_equal(DisplayPrefs.Size.LARGEST)
	assert_bool(p.step(S.UI_SIZE, 1)).is_false()
	assert_int(p.ui_size).is_equal(DisplayPrefs.Size.LARGEST)
	assert_bool(p.step(S.UI_SIZE, -1)).is_true()
	assert_bool(p.step(S.UI_SIZE, -1)).is_true()
	assert_bool(p.step(S.UI_SIZE, -1)).is_false()
	assert_int(p.ui_size).is_equal(DisplayPrefs.Size.NORMAL)
	assert_bool(p.step(S.CUES, -1)).is_false()
	assert_bool(p.step(S.CUES, 1)).is_true()
	assert_int(p.cues).is_equal(DisplayPrefs.Cues.SHAPES)
	assert_bool(p.step(S.CUES, 1)).is_false()

func test_step_touches_only_its_setting() -> void:
	var p := DisplayPrefs.new()
	p.step(S.TEXT_SIZE, 1)
	assert_int(p.text_size).is_equal(DisplayPrefs.Size.LARGE)
	assert_int(p.ui_size).is_equal(DisplayPrefs.Size.NORMAL)
	assert_int(p.cues).is_equal(DisplayPrefs.Cues.STANDARD)

func test_changed_fires_once_per_real_change() -> void:
	var p := DisplayPrefs.new()
	var fired := [0]
	p.changed.connect(func() -> void: fired[0] += 1)
	p.step(S.UI_SIZE, 1)
	p.step(S.UI_SIZE, 1)
	p.step(S.UI_SIZE, 1)
	assert_int(fired[0]).is_equal(2)

func test_to_dict_shape() -> void:
	var p := DisplayPrefs.new()
	p.step(S.TEXT_SIZE, 2)
	p.step(S.CUES, 1)
	assert_dict(p.to_dict()).is_equal({"version": 1, "ui_size": "normal", "text_size": "largest", "cues": "shapes"})

func test_a_change_is_written_at_once() -> void:
	var p := DisplayPrefs.new(FILE)
	p.step(S.UI_SIZE, 1)
	assert_bool(FileAccess.file_exists(FILE)).is_true()
	assert_dict(JSON.parse_string(_read())).is_equal(
		{"version": 1.0, "ui_size": "large", "text_size": "normal", "cues": "standard"})

func test_no_path_writes_nothing() -> void:
	var p := DisplayPrefs.new()
	p.step(S.UI_SIZE, 1)
	assert_int(p.save()).is_equal(OK)
	assert_bool(FileAccess.file_exists(FILE)).is_false()

func test_round_trip() -> void:
	var p := DisplayPrefs.new(FILE)
	p.step(S.UI_SIZE, 2)
	p.step(S.TEXT_SIZE, 1)
	p.step(S.CUES, 1)
	var q := DisplayPrefs.load_from(FILE)
	assert_int(q.ui_size).is_equal(DisplayPrefs.Size.LARGEST)
	assert_int(q.text_size).is_equal(DisplayPrefs.Size.LARGE)
	assert_int(q.cues).is_equal(DisplayPrefs.Cues.SHAPES)
	assert_str(q.path).is_equal(FILE)

func test_missing_file_gives_defaults_and_writes_nothing() -> void:
	var p := DisplayPrefs.load_from(FILE)
	_assert_defaults(p)
	assert_str(p.path).is_equal(FILE)
	assert_bool(FileAccess.file_exists(FILE)).is_false()

func test_unreadable_files_give_defaults() -> void:
	var texts: Array[String] = [
		"",
		"not json",
		"[1, 2]",
		'{"ui_size": "large", "text_size": "large", "cues": "shapes"}',
		'{"version": 2, "ui_size": "large", "text_size": "large", "cues": "shapes"}',
		'{"version": "1", "ui_size": "large", "text_size": "large", "cues": "shapes"}',
		'{"version": 1, "text_size": "large", "cues": "shapes"}',
		'{"version": 1, "ui_size": "huge", "text_size": "large", "cues": "shapes"}',
		'{"version": 1, "ui_size": 1, "text_size": "large", "cues": "shapes"}',
		'{"version": 1, "ui_size": "large", "text_size": "large", "cues": "large"}',
	]
	for text in texts:
		_write(text)
		var p := DisplayPrefs.load_from(FILE)
		_assert_defaults(p, text)
		assert_str(p.path).is_equal(FILE)
		assert_str(_read()).override_failure_message("rewrote %s" % text).is_equal(text)

func test_all_or_nothing() -> void:
	_write('{"version": 1, "ui_size": "large", "text_size": "large", "cues": "large"}')
	var p := DisplayPrefs.load_from(FILE)
	assert_int(p.ui_size).is_equal(DisplayPrefs.Size.NORMAL)
	assert_int(p.text_size).is_equal(DisplayPrefs.Size.NORMAL)

func test_extra_keys_are_ignored() -> void:
	_write('{"version": 1, "ui_size": "large", "text_size": "normal", "cues": "shapes", "later": true}')
	var p := DisplayPrefs.load_from(FILE)
	assert_int(p.ui_size).is_equal(DisplayPrefs.Size.LARGE)
	assert_int(p.text_size).is_equal(DisplayPrefs.Size.NORMAL)
	assert_int(p.cues).is_equal(DisplayPrefs.Cues.SHAPES)

func test_next_change_saves_over_a_bad_file() -> void:
	_write("not json")
	DisplayPrefs.load_from(FILE).step(S.CUES, 1)
	var d: Variant = JSON.parse_string(_read())
	assert_dict(d).is_equal({"version": 1.0, "ui_size": "normal", "text_size": "normal", "cues": "shapes"})
