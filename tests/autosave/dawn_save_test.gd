extends GdUnitTestSuite
## The dawn rules: save, then the line or the box.

const B := DawnSave.Choice

var calls: Array = []

func before_test() -> void:
	calls = []

func _rules(results: Array) -> DawnSave:
	return DawnSave.new(func() -> Error:
		calls.append(1)
		return results.pop_front())

func test_dawn_saved_starts_the_line() -> void:
	var r := _rules([OK])
	r.dawn()
	assert_bool(r.line.is_showing()).is_true()
	assert_bool(r.box_open).is_false()
	assert_int(calls.size()).is_equal(1)

func test_line_lasts_four_seconds_in_all() -> void:
	var r := _rules([OK])
	r.dawn()
	r.advance(3.9)
	assert_bool(r.line.is_showing()).is_true()
	r.advance(0.2)
	assert_bool(r.line.is_showing()).is_false()

func test_dawn_failed_opens_box_with_try_again() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE])
	r.dawn()
	assert_bool(r.box_open).is_true()
	assert_int(r.selected).is_equal(B.TRY_AGAIN)
	assert_bool(r.line.is_showing()).is_false()

func test_try_again_works() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE, OK])
	r.dawn()
	r.press(B.TRY_AGAIN)
	assert_bool(r.box_open).is_false()
	assert_bool(r.line.is_showing()).is_true()
	assert_int(calls.size()).is_equal(2)
	assert_int(r.failed_retries).is_equal(0)

func test_try_again_fails_again() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE, ERR_FILE_CANT_WRITE])
	r.dawn()
	r.press(B.TRY_AGAIN)
	assert_bool(r.box_open).is_true()
	assert_int(r.failed_retries).is_equal(1)
	assert_int(r.selected).is_equal(B.TRY_AGAIN)
	assert_bool(r.line.is_showing()).is_false()

func test_try_again_selects_try_again() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE, ERR_FILE_CANT_WRITE])
	r.dawn()
	r.select(B.KEEP_PLAYING)
	r.press(B.TRY_AGAIN)
	assert_int(r.selected).is_equal(B.TRY_AGAIN)

func test_keep_playing_closes_with_no_line_and_no_save() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE])
	r.dawn()
	r.press(B.KEEP_PLAYING)
	assert_bool(r.box_open).is_false()
	assert_bool(r.line.is_showing()).is_false()
	assert_int(calls.size()).is_equal(1)

func test_cancel_is_keep_playing() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE])
	r.dawn()
	r.cancel()
	assert_bool(r.box_open).is_false()
	assert_bool(r.line.is_showing()).is_false()
	assert_int(calls.size()).is_equal(1)

func test_next_dawn_tries_again() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE, ERR_FILE_CANT_WRITE])
	r.dawn()
	r.cancel()
	r.dawn()
	assert_bool(r.box_open).is_true()
	assert_int(calls.size()).is_equal(2)

func test_select_and_press_ignored_while_closed() -> void:
	var r := _rules([OK])
	r.dawn()
	r.select(B.KEEP_PLAYING)
	assert_int(r.selected).is_equal(B.TRY_AGAIN)
	r.press(B.TRY_AGAIN)
	assert_int(calls.size()).is_equal(1)

func test_dawn_while_box_open_does_nothing() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE])
	r.dawn()
	r.dawn()
	assert_int(calls.size()).is_equal(1)

func test_held_line_waits_for_release() -> void:
	var r := _rules([OK])
	r.hold_line()
	r.dawn()
	assert_int(calls.size()).is_equal(1)
	assert_bool(r.line.is_showing()).is_false()
	r.release_line()
	assert_bool(r.line.is_showing()).is_true()

func test_release_without_a_save_shows_nothing() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE])
	r.hold_line()
	r.dawn()
	r.cancel()
	r.release_line()
	assert_bool(r.line.is_showing()).is_false()

func test_try_again_while_held_waits_for_release() -> void:
	var r := _rules([ERR_FILE_CANT_WRITE, OK])
	r.hold_line()
	r.dawn()
	r.press(B.TRY_AGAIN)
	assert_bool(r.line.is_showing()).is_false()
	r.release_line()
	assert_bool(r.line.is_showing()).is_true()
