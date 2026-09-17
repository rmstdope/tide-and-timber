extends GdUnitTestSuite
## B opens the build list; Enter and keypad Enter choose and place, and so does the Use key (E). Space does not.

func _bound(action: StringName, key: int) -> bool:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	return InputMap.has_action(action) and InputMap.event_is_action(event, action)

func test_build_actions_bound_by_physical_key() -> void:
	assert_bool(_bound(&"build", KEY_B)).is_true()
	for key in [KEY_ENTER, KEY_KP_ENTER]:
		assert_bool(_bound(&"build_accept", key)).override_failure_message("build_accept not on %d" % key).is_true()
	assert_bool(_bound(&"build_accept", KEY_E)).is_false()
	assert_bool(_bound(&"use", KEY_E)).is_true()
	var keys := InputMap.action_get_events(&"build_accept").filter(func(e: InputEvent) -> bool: return e is InputEventKey)
	assert_int(keys.size()).is_equal(2)
	assert_bool(_bound(&"build_accept", KEY_SPACE)).is_false()
