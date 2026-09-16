extends GdUnitTestSuite

const BINDINGS := {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
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
