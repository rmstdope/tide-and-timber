extends GdUnitTestSuite
## The Settings board's rules: four value rows and Controls, where it was opened from, Back, Start and the Controls seam.

const P := SettingsMenu.Plank
const O := SettingsMenu.Outcome

var m: SettingsMenu
var prefs: DisplayPrefs

func before_test() -> void:
	m = SettingsMenu.new()
	prefs = DisplayPrefs.new()

func test_opens_on_ui_size_from_either_place() -> void:
	assert_bool(m.open(false)).is_true()
	assert_bool(m.is_open).is_true()
	assert_bool(m.from_pause).is_false()
	assert_int(m.highlighted).is_equal(P.UI_SIZE)
	assert_bool(m.controls_open).is_false()
	var n := SettingsMenu.new()
	n.open(true)
	assert_bool(n.from_pause).is_true()

func test_open_twice_changes_nothing() -> void:
	m.open(true)
	assert_bool(m.open(false)).is_false()
	assert_bool(m.from_pause).is_true()

func test_items_are_five_with_fullscreen_before_controls() -> void:
	assert_array(m.items).is_equal([P.UI_SIZE, P.TEXT_SIZE, P.COLOUR_CUES, P.FULLSCREEN, P.CONTROLS])

func test_opens_on_ui_size() -> void:
	m.open(true)
	assert_int(m.highlighted).is_equal(P.UI_SIZE)

func test_fullscreen_row_stops_at_off_and_on() -> void:
	m.open(false)
	assert_bool(m.change(P.FULLSCREEN, -1, prefs)).is_false()
	assert_int(m.highlighted).is_equal(P.FULLSCREEN)
	assert_bool(m.change(P.FULLSCREEN, 1, prefs)).is_true()
	assert_bool(prefs.fullscreen).is_true()
	assert_bool(m.change(P.FULLSCREEN, 1, prefs)).is_false()
	assert_bool(m.change(P.FULLSCREEN, -1, prefs)).is_true()
	assert_bool(prefs.fullscreen).is_false()

func test_select_on_fullscreen_does_nothing() -> void:
	m.open(false)
	assert_int(m.pick(P.FULLSCREEN)).is_equal(O.NONE)
	assert_int(m.highlighted).is_equal(P.FULLSCREEN)
	assert_bool(m.is_open).is_true()

func test_move_goes_down_the_five_rows_and_wraps() -> void:
	m.open(false)
	m.move(1)
	assert_int(m.highlighted).is_equal(P.TEXT_SIZE)
	m.move(1)
	assert_int(m.highlighted).is_equal(P.COLOUR_CUES)
	m.move(1)
	assert_int(m.highlighted).is_equal(P.FULLSCREEN)
	m.move(1)
	assert_int(m.highlighted).is_equal(P.CONTROLS)
	m.move(1)
	assert_int(m.highlighted).is_equal(P.UI_SIZE)
	m.move(-1)
	assert_int(m.highlighted).is_equal(P.CONTROLS)

func test_pick_controls_asks_for_the_page_and_stays_open() -> void:
	m.open(false)
	assert_int(m.pick(P.CONTROLS)).is_equal(O.OPEN_CONTROLS)
	assert_bool(m.is_open).is_true()
	assert_bool(m.controls_open).is_false()

func test_back_closes() -> void:
	m.open(false)
	assert_int(m.back()).is_equal(O.CLOSED)
	assert_bool(m.is_open).is_false()

func test_start_from_pause_resumes() -> void:
	m.open(true)
	assert_int(m.start()).is_equal(O.RESUME_PLAY)
	assert_bool(m.is_open).is_false()

func test_start_from_title_does_nothing() -> void:
	m.open(false)
	assert_int(m.start()).is_equal(O.NONE)
	assert_bool(m.is_open).is_true()

func test_closed_board_ignores_everything() -> void:
	assert_int(m.pick(P.CONTROLS)).is_equal(O.NONE)
	assert_int(m.back()).is_equal(O.NONE)
	assert_int(m.start()).is_equal(O.NONE)

func test_controls_page_blocks_the_board() -> void:
	m.open(true)
	m.show_controls()
	assert_int(m.back()).is_equal(O.NONE)
	assert_int(m.start()).is_equal(O.NONE)
	assert_int(m.pick(P.CONTROLS)).is_equal(O.NONE)
	assert_bool(m.is_open).is_true()

func test_close_controls_highlights_controls() -> void:
	m.open(false)
	m.show_controls()
	m.close_controls()
	assert_bool(m.controls_open).is_false()
	assert_int(m.highlighted).is_equal(P.CONTROLS)
	assert_int(m.back()).is_equal(O.CLOSED)

func test_resume_from_controls() -> void:
	m.open(true)
	m.show_controls()
	assert_int(m.resume_from_controls()).is_equal(O.RESUME_PLAY)
	assert_bool(m.is_open).is_false()
	var t := SettingsMenu.new()
	t.open(false)
	t.show_controls()
	assert_int(t.resume_from_controls()).is_equal(O.NONE)
	assert_bool(t.is_open).is_true()

func test_show_controls_on_a_closed_board_does_nothing() -> void:
	m.show_controls()
	assert_bool(m.controls_open).is_false()

func _assert_prefs_untouched() -> void:
	assert_dict(prefs.to_dict()).is_equal(DisplayPrefs.new().to_dict())

func test_pick_on_a_value_row_does_nothing() -> void:
	m.open(false)
	assert_int(m.pick(P.COLOUR_CUES)).is_equal(O.NONE)
	assert_int(m.highlighted).is_equal(P.COLOUR_CUES)
	assert_bool(m.is_open).is_true()
	_assert_prefs_untouched()

func test_change_steps_the_rows_setting() -> void:
	m.open(false)
	assert_bool(m.change(P.TEXT_SIZE, 1, prefs)).is_true()
	assert_int(prefs.text_size).is_equal(DisplayPrefs.Size.LARGE)
	assert_int(m.highlighted).is_equal(P.TEXT_SIZE)
	assert_bool(m.change(P.COLOUR_CUES, -1, prefs)).is_false()
	assert_int(m.highlighted).is_equal(P.COLOUR_CUES)

func test_change_on_controls_does_nothing() -> void:
	m.open(false)
	assert_bool(m.change(P.CONTROLS, 1, prefs)).is_false()
	assert_int(m.highlighted).is_equal(P.UI_SIZE)
	_assert_prefs_untouched()

func test_change_ignored_unless_the_board_takes_input() -> void:
	assert_bool(m.change(P.UI_SIZE, 1, prefs)).is_false()
	_assert_prefs_untouched()
	m.open(true)
	m.show_controls()
	assert_bool(m.change(P.UI_SIZE, 1, prefs)).is_false()
	_assert_prefs_untouched()
