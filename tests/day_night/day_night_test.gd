extends GdUnitTestSuite

const SCENE := "res://src/day_night/day_night.tscn"
const LINE := "It'll be dark soon. I need shelter."

var runner: GdUnitSceneRunner
var dn: DayNight

func before_test() -> void:
	runner = scene_runner(SCENE)
	dn = runner.scene() as DayNight

func _n(unique: String) -> Node:
	return dn.get_node("%" + unique)

func test_hud_hidden_and_clock_still_before_start() -> void:
	dn.time_scale = 1000.0
	await runner.simulate_frames(5)
	assert_float(dn.clock.total_minutes).is_equal(780.0)
	assert_bool(_n("Hud").visible).is_false()

func test_start_shows_day_1_13_00_in_daylight() -> void:
	dn.start()
	assert_bool(_n("Hud").visible).is_true()
	assert_str(_n("DayLabel").text).is_equal("DAY 1")
	assert_str(_n("TimeLabel").text).is_equal("13:00")
	assert_that(_n("Light").color).is_equal(Color.WHITE)
	assert_bool(_n("Sunset").visible).is_false()

func test_runs_from_process_after_start() -> void:
	dn.start()
	dn.time_scale = 1000.0
	await runner.simulate_frames(5)
	assert_bool(dn.clock.total_minutes > 780.0).is_true()

func test_tick_updates_labels_dial_and_light() -> void:
	dn.start()
	dn.tick(630.0)
	assert_str(_n("TimeLabel").text).is_equal("20:00")
	assert_bool(_n("Dial").is_day).is_false()
	assert_float(_n("Dial").fraction).is_equal(0.0)
	assert_that(_n("Light").color).is_equal(Daylight.color_at(1200.0))

func test_sunset_line_once_at_18_30() -> void:
	dn.start()
	dn.tick(494.0)
	assert_bool(_n("Sunset").visible).is_false()
	dn.tick(2.0)
	assert_bool(_n("Sunset").visible).is_true()
	assert_str(_n("Sunset").get_node("Text").text).is_equal(LINE)
	dn.tick(5.0)
	assert_bool(_n("Sunset").visible).is_false()
	dn.tick(60.0)
	assert_bool(_n("Sunset").visible).is_false()

func test_sunset_line_again_next_evening() -> void:
	dn.start()
	dn.tick(495.0)
	dn.tick(5.0)
	dn.tick(2160.0)
	assert_bool(_n("Sunset").visible).is_true()

func test_root_is_pausable() -> void:
	assert_int(dn.process_mode).is_equal(Node.PROCESS_MODE_PAUSABLE)

func test_hud_is_above_the_light() -> void:
	var hud := _n("Hud")
	var light := _n("Light")
	assert_bool(hud is CanvasLayer).is_true()
	assert_bool((hud as CanvasLayer).layer > 0).is_true()
	assert_bool(light is CanvasModulate).is_true()
	assert_bool(hud.is_ancestor_of(light)).is_false()

func test_hud_ignores_the_mouse() -> void:
	var sunset := _n("Sunset")
	var controls: Array[Node] = [_n("Plank"), _n("DayLabel"), _n("Dial"), _n("TimeLabel"), sunset]
	controls.append_array(sunset.get_children())
	assert_int(sunset.get_child_count()).is_equal(2)
	for c: Node in controls:
		assert_int((c as Control).mouse_filter).override_failure_message(c.name).is_equal(Control.MOUSE_FILTER_IGNORE)
