extends GdUnitTestSuite
## B opens the build list; E, Enter and keypad Enter choose and place. Space does not.

func _bound(action: StringName, key: int) -> bool:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	return InputMap.has_action(action) and InputMap.event_is_action(event, action)

func test_build_actions_bound_by_physical_key() -> void:
	assert_bool(_bound(&"build", KEY_B)).is_true()
	for key in [KEY_E, KEY_ENTER, KEY_KP_ENTER]:
		assert_bool(_bound(&"build_accept", key)).override_failure_message("build_accept not on %d" % key).is_true()
	assert_bool(_bound(&"build_accept", KEY_SPACE)).is_false()
