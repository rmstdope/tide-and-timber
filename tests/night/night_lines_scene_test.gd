extends "res://tests/night/night_scene_base.gd"
## His night lines and the frost, on the beach with the clock.

func test_warning_at_2030_away_from_fire() -> void:
	_out_of_light()
	_at(1225.0)
	night.tick(0.1)
	_at(1230.0)
	night.tick(0.1)
	assert_bool(_n("NightLine").visible).is_true()
	assert_str(_line_text()).is_equal("Getting cold. I need that fire.")
	assert_bool(_n("Frost").visible).is_false()

func test_no_warning_in_camp() -> void:
	_fire()
	_in_light()
	_at(1225.0)
	night.tick(0.1)
	_at(1230.0)
	night.tick(0.1)
	assert_bool(_n("NightLine").visible).is_false()

func test_line_fades_out_by_itself() -> void:
	_out_of_light()
	_at(1225.0)
	night.tick(0.1)
	_at(1230.0)
	night.tick(0.1)
	night.tick(5.0)
	assert_bool(_n("NightLine").visible).is_false()

func test_outside_at_2100_frost_and_line() -> void:
	_out_of_light()
	_at(1255.0)
	night.tick(0.1)
	_at(1260.0)
	night.tick(0.0)
	assert_str(_line_text()).is_equal("I can't stay out here.")
	assert_bool(_n("NightLine").visible).is_true()
	night.tick(2.5)
	assert_bool(_n("Frost").visible).is_true()
	assert_float(_n("Frost").modulate.a).is_equal_approx(0.45, 0.01)

func test_no_camp_frost_wherever_he_is() -> void:
	_in_light()
	_at(1260.0)
	night.tick(0.0)
	night.tick(1.0)
	assert_bool(night.watch.outside).is_true()

func test_in_firelight_all_night_nothing() -> void:
	_fire()
	_in_light()
	for m in range(1250, 1741, 10):
		_at(float(m))
		night.tick(1.0)
	assert_bool(_n("NightLine").visible).is_false()
	assert_bool(_n("Frost").visible).is_false()
	assert_object(night.collapse).is_null()

func test_back_inside_melts() -> void:
	_fire()
	_out_of_light()
	_at(1260.0)
	night.tick(0.0)
	night.tick(4.0)
	_in_light()
	night.tick(1.0)
	assert_bool(_n("Frost").visible).is_false()
	assert_object(night.collapse).is_null()
	assert_array(NightLoss.losses(inventory)).is_empty()

func test_stepping_out_again_shows_line_again() -> void:
	_fire()
	_out_of_light()
	_at(1260.0)
	night.tick(0.0)
	night.tick(4.5)
	_in_light()
	night.tick(0.0)
	_out_of_light()
	night.tick(0.0)
	assert_float(night.line.alpha()).is_equal(0.0)
	assert_bool(night.line.is_showing()).is_true()
	assert_float(night.watch.outside_seconds).is_equal(0.0)

func test_list_open_stops_the_seconds() -> void:
	_fire()
	_out_of_light()
	_at(1260.0)
	night.tick(0.0)
	night.tick(2.0)
	builder.open_list()
	night.tick(10.0)
	assert_object(night.collapse).is_null()
	assert_float(night.watch.outside_seconds).is_equal(2.0)
	builder.close_list()
	night.tick(3.0)
	assert_object(night.collapse).is_not_null()

func test_waits_for_the_sunset_line() -> void:
	_out_of_light()
	dn.sunset.start()
	_at(1225.0)
	night.tick(0.0)
	_at(1230.0)
	night.tick(0.0)
	assert_bool(_n("NightLine").visible).is_false()
	dn.sunset.advance(5.0)
	night.tick(0.0)
	assert_bool(_n("NightLine").visible).is_true()
	assert_str(_line_text()).is_equal("Getting cold. I need that fire.")

func test_nothing_before_control() -> void:
	dn.running = false
	_out_of_light()
	_at(1300.0)
	night.tick(10.0)
	night.tick(10.0)
	assert_object(night.collapse).is_null()
	assert_bool(_n("Frost").visible).is_false()
	assert_bool(night.watch.outside).is_false()
