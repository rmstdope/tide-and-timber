extends GdUnitTestSuite

const Preview := preload("res://src/day_night/day_night_preview.gd")

func test_parse_args_defaults() -> void:
	var opts := Preview.parse_args(PackedStringArray())
	assert_float(opts.speed).is_equal(1.0)
	assert_int(opts.start).is_equal(780)

func test_parse_args_reads_speed_and_start() -> void:
	var opts := Preview.parse_args(PackedStringArray(["--clock-speed=60", "--clock-start=18:20"]))
	assert_float(opts.speed).is_equal(60.0)
	assert_int(opts.start).is_equal(1100)

func test_parse_args_ignores_bad_values() -> void:
	var opts := Preview.parse_args(PackedStringArray(["--clock-speed=0", "--clock-start=25:00"]))
	assert_float(opts.speed).is_equal(1.0)
	assert_int(opts.start).is_equal(780)
