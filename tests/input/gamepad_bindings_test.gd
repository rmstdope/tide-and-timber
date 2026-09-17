extends GdUnitTestSuite
## Every gameplay verb has its pad binding by button position; unused pad inputs bind nothing.
## Keys are named in code only under src/input (Controls and KeyLabels); nowhere else in src reads a key code.

const BUTTONS := {
	&"run": JOY_BUTTON_LEFT_SHOULDER,
	&"use": JOY_BUTTON_A,
	&"build": JOY_BUTTON_Y,
	&"build_accept": JOY_BUTTON_A,
	&"build_back": JOY_BUTTON_B,
	&"pause": JOY_BUTTON_START,
	&"menu_accept": JOY_BUTTON_A,
}

const AXES := {
	&"move_left": [JOY_AXIS_LEFT_X, -1.0],
	&"move_right": [JOY_AXIS_LEFT_X, 1.0],
	&"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	&"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}

func _button(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = b
	e.pressed = true
	return e

func _motion(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	return e

func _key(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.pressed = true
	return e

func _game_actions_matching(event: InputEvent) -> Array[StringName]:
	var hits: Array[StringName] = []
	for action in InputMap.get_actions():
		if not String(action).begins_with("ui_") and InputMap.event_is_action(event, action):
			hits.append(action)
	return hits

func test_each_action_has_its_pad_binding() -> void:
	for action: StringName in BUTTONS:
		assert_bool(InputMap.has_action(action)).override_failure_message("missing %s" % action).is_true()
		assert_bool(InputMap.event_is_action(_button(BUTTONS[action]), action)) \
			.override_failure_message("%s lacks pad button %d" % [action, BUTTONS[action]]).is_true()
	for action: StringName in AXES:
		assert_bool(InputMap.event_is_action(_motion(AXES[action][0], AXES[action][1]), action)) \
			.override_failure_message("%s lacks its stick axis" % action).is_true()

func test_build_back_is_escape_and_pad_b() -> void:
	assert_bool(InputMap.has_action(&"build_back")).is_true()
	assert_bool(InputMap.event_is_action(_key(KEY_ESCAPE), &"build_back")).is_true()
	assert_bool(InputMap.event_is_action(_button(JOY_BUTTON_B), &"build_back")).is_true()
	assert_bool(InputMap.event_is_action(_key(KEY_B), &"build_back")).is_false()

func test_by_position_a_is_bottom() -> void:
	assert_array(_game_actions_matching(_button(JOY_BUTTON_A))) \
		.contains_exactly_in_any_order([&"use", &"build_accept", &"menu_accept"])
	assert_array(_game_actions_matching(_button(JOY_BUTTON_B))).contains_exactly_in_any_order([&"build_back", &"menu_cancel"])

func test_unused_pad_inputs_bind_nothing() -> void:
	for b: JoyButton in [JOY_BUTTON_X, JOY_BUTTON_BACK, JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK, JOY_BUTTON_RIGHT_SHOULDER]:
		assert_array(_game_actions_matching(_button(b))).override_failure_message("button %d is bound" % b).is_empty()
	assert_array(_game_actions_matching(_button(JOY_BUTTON_DPAD_LEFT))).contains_exactly([&"menu_left"])   # menus (tr-eg9.2)
	assert_array(_game_actions_matching(_button(JOY_BUTTON_DPAD_RIGHT))).contains_exactly([&"menu_right"])
	assert_array(_game_actions_matching(_button(JOY_BUTTON_DPAD_UP))).contains_exactly([&"menu_up"])
	assert_array(_game_actions_matching(_button(JOY_BUTTON_DPAD_DOWN))).contains_exactly([&"menu_down"])
	for axis: JoyAxis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		assert_array(_game_actions_matching(_motion(axis, 1.0))).override_failure_message("axis %d is bound" % axis).is_empty()

func _has_motion(action: StringName, axis: JoyAxis, value: float) -> bool:
	for e: InputEvent in InputMap.action_get_events(action):
		var m := e as InputEventJoypadMotion
		if m and m.axis == axis and m.axis_value == value:
			return true
	return false

func test_left_stick_moves_menus() -> void:
	assert_bool(_has_motion(&"menu_up", JOY_AXIS_LEFT_Y, -1.0)).is_true()
	assert_bool(_has_motion(&"menu_down", JOY_AXIS_LEFT_Y, 1.0)).is_true()

func test_keyboard_bindings_unchanged() -> void:
	assert_bool(InputMap.event_is_action(_key(KEY_ESCAPE), &"pause")).is_true()
	assert_bool(InputMap.event_is_action(_key(KEY_SHIFT), &"run")).is_true()
	assert_bool(InputMap.event_is_action(_key(KEY_B), &"build")).is_true()
	assert_bool(InputMap.event_is_action(_key(KEY_E), &"use")).is_true()

func test_no_raw_key_reads_in_src() -> void:
	var offenders: Array[String] = []
	_scan("res://src", offenders)
	assert_array(offenders).is_empty()

func _scan(dir: String, offenders: Array[String]) -> void:
	if dir == "res://src/input":
		return
	for sub in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(sub), offenders)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			var text := FileAccess.get_file_as_string(dir.path_join(f))
			if text.contains("KEY_") or text.contains("physical_keycode"):
				offenders.append(dir.path_join(f))
