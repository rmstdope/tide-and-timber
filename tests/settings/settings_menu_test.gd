extends GdUnitTestSuite
## The Settings board's rules: one plank, where it was opened from, Back, Start and the Controls seam.

const P := SettingsMenu.Plank
const O := SettingsMenu.Outcome

var m: SettingsMenu

func before_test() -> void:
	m = SettingsMenu.new()

func test_opens_on_controls_from_either_place() -> void:
	assert_bool(m.open(false)).is_true()
	assert_bool(m.is_open).is_true()
	assert_bool(m.from_pause).is_false()
	assert_int(m.highlighted).is_equal(P.CONTROLS)
	assert_bool(m.controls_open).is_false()
	var n := SettingsMenu.new()
	n.open(true)
	assert_bool(n.from_pause).is_true()

func test_open_twice_changes_nothing() -> void:
	m.open(true)
	assert_bool(m.open(false)).is_false()
	assert_bool(m.from_pause).is_true()

func test_move_with_one_plank_stays() -> void:
	m.open(false)
	m.move(1)
	assert_int(m.highlighted).is_equal(P.CONTROLS)
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
