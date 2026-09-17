extends GdUnitTestSuite
## The migration runner, with injected steps. No disk.

var calls: Array = []

func before_test() -> void:
	calls.clear()

func _files(version: Variant) -> Dictionary:
	return {"meta": {"version": version}, "player": {"x": 1.0}}

func _rename_x_to_left(files: Dictionary) -> Variant:
	files.player["left"] = files.player["x"]
	files.player.erase("x")
	return files

func _recording() -> Callable:
	var recorded := calls
	return func(f: Dictionary) -> Variant:
		recorded.append(1)
		return f

func _trail(mark: String) -> Callable:
	return func(f: Dictionary) -> Variant:
		if not f.meta.has("trail"):
			f.meta["trail"] = []
		f.meta.trail.append(mark)
		return f

func _abc() -> Dictionary[int, Callable]:
	var steps: Dictionary[int, Callable] = {1: _trail("a"), 2: _trail("b"), 3: _trail("c")}
	return steps

func test_real_chain_is_empty_at_version_1() -> void:
	assert_int(SaveData.VERSION).is_equal(1)
	assert_bool(SaveMigrations.chain().is_empty()).is_true()

func test_current_version_unchanged_no_step_runs() -> void:
	var steps: Dictionary[int, Callable] = {1: _recording()}
	assert_dict(SaveMigrations.migrate(_files(1.0), steps, 1)).is_equal(_files(1.0))
	assert_array(calls).is_empty()

func test_one_step() -> void:
	var steps: Dictionary[int, Callable] = {1: _rename_x_to_left}
	var out: Dictionary = SaveMigrations.migrate(_files(1.0), steps, 2)
	assert_dict(out.player).is_equal({"left": 1.0})
	assert_int(out.meta.version).is_equal(2)

func test_several_versions_in_order() -> void:
	var out: Dictionary = SaveMigrations.migrate(_files(1), _abc(), 4)
	assert_array(out.meta.trail).is_equal(["a", "b", "c"])
	assert_int(out.meta.version).is_equal(4)

func test_starts_at_the_saves_version() -> void:
	var out: Dictionary = SaveMigrations.migrate(_files(3.0), _abc(), 4)
	assert_array(out.meta.trail).is_equal(["c"])

func test_json_float_version() -> void:
	var steps: Dictionary[int, Callable] = {1: _rename_x_to_left}
	var a: Dictionary = SaveMigrations.migrate(_files(1.0), steps, 2)
	var b: Dictionary = SaveMigrations.migrate(_files(1), steps, 2)
	assert_dict(a).is_equal(b)

func test_input_never_changed() -> void:
	var original := _files(1.0)
	var before := original.duplicate(true)
	var steps: Dictionary[int, Callable] = {1: _rename_x_to_left}
	SaveMigrations.migrate(original, steps, 2)
	assert_dict(original).is_equal(before)

func test_missing_step_is_null() -> void:
	var steps: Dictionary[int, Callable] = {1: _recording()}
	assert_that(SaveMigrations.migrate(_files(1), steps, 3)).is_null()

func test_version_0_is_null() -> void:
	assert_that(SaveMigrations.migrate(_files(0), SaveMigrations.chain(), 1)).is_null()

func test_refusing_step_is_null() -> void:
	var steps: Dictionary[int, Callable] = {1: func(_f: Dictionary) -> Variant: return null}
	assert_that(SaveMigrations.migrate(_files(1), steps, 2)).is_null()

func test_step_losing_meta_is_null() -> void:
	var steps: Dictionary[int, Callable] = {1: func(_f: Dictionary) -> Variant: return {"player": {}}}
	assert_that(SaveMigrations.migrate(_files(1), steps, 2)).is_null()

func test_newer_untouched() -> void:
	var steps: Dictionary[int, Callable] = {5: _recording()}
	assert_dict(SaveMigrations.migrate(_files(5.0), steps, 1)).is_equal(_files(5.0))
	assert_array(calls).is_empty()

func test_no_meta_or_bad_version_untouched() -> void:
	var steps: Dictionary[int, Callable] = {1: _recording()}
	for files: Dictionary in [{"player": {}}, _files("1"), _files(1.5)]:
		assert_dict(SaveMigrations.migrate(files, steps, 2)).is_equal(files)
	assert_array(calls).is_empty()
