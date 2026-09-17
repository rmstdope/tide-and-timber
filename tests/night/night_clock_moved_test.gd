extends "res://tests/night/night_scene_base.gd"
## A clock set by hand from the Debug panel starts the night's watch afresh.

func test_hand_set_clock_does_not_warn_at_noon() -> void:
	night.tick(0.1)
	dn.set_minutes(1440 + 780)
	night.tick(0.1)
	assert_str(night._pending).is_equal("")
	assert_bool(night.watch.outside).is_false()

func test_hand_set_clock_into_the_night_steps_him_out() -> void:
	night.tick(0.1)
	dn.set_minutes(1440 + 1290)
	night.tick(0.1)
	assert_bool(night.watch.outside).is_true()
