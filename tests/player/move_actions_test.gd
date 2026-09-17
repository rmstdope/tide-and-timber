extends GdUnitTestSuite

const BINDINGS := {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"use": [KEY_E],
}

func test_move_actions_are_bound_by_physical_key() -> void:
	for action: StringName in BINDINGS:
		assert_bool(InputMap.has_action(action)).override_failure_message("missing %s" % action).is_true()
		for key: int in BINDINGS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			event.pressed = true
			assert_bool(InputMap.event_is_action(event, action)) \
				.override_failure_message("%s not bound to %s" % [action, OS.get_keycode_string(key)]) \
				.is_true()

func test_run_is_bound_to_shift() -> void:
	assert_bool(InputMap.has_action(&"run")).is_true()
	for location: int in [KEY_LOCATION_LEFT, KEY_LOCATION_RIGHT]:
		var shift := InputEventKey.new()
		shift.physical_keycode = KEY_SHIFT
		shift.location = location
		shift.pressed = true
		assert_bool(InputMap.event_is_action(shift, &"run")).override_failure_message("location %d" % location).is_true()
	var a := InputEventKey.new()
	a.physical_keycode = KEY_A
	a.shift_pressed = true
	a.pressed = true
	assert_bool(InputMap.event_is_action(a, &"move_left")).is_true()

func after_test() -> void:
	InputDevice.use_controls(Controls.new())

func test_walk_follows_rebound_keys() -> void:
	var i := InputEventKey.new()
	i.physical_keycode = KEY_I
	InputDevice.controls.set_slot(Controls.Action.WALK_UP, Controls.Device.KEYBOARD, 0, i)
	var held := InputEventKey.new()
	held.physical_keycode = KEY_I
	held.pressed = true
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	assert_float(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down").y).is_less(0.0)
	var up := held.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	var w := InputEventKey.new()
	w.physical_keycode = KEY_W
	w.pressed = true
	assert_bool(InputMap.event_is_action(w, &"move_up")).is_false()
