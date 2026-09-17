extends GdUnitTestSuite
## The player's controls: the eight play actions, their slots, the clash rule, the file and the InputMap.

const A := Controls.Action
const D := Controls.Device
const ROOT := "user://test_controls"
const PATH := "user://test_controls/controls.json"

func _key(code: Key, location: KeyLocation = KEY_LOCATION_UNSPECIFIED) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.location = location
	return e

func _button(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	return e

func _motion(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e

func _rm(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)

func _write(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func after_test() -> void:
	_rm(ROOT)
	InputDevice.use_controls(Controls.new())

func _key_code(c: Controls, a: Controls.Action, index: int) -> int:
	var e := c.slot(a, D.KEYBOARD, index) as InputEventKey
	return -1 if e == null else e.physical_keycode

func _is_default(c: Controls) -> bool:
	return JSON.stringify(c.to_dict()) == JSON.stringify(Controls.new().to_dict())

# --- the model

func test_defaults_match_the_agreed_table() -> void:
	var c := Controls.new()
	var keys := {A.WALK_UP: [KEY_W, KEY_UP], A.WALK_DOWN: [KEY_S, KEY_DOWN], A.WALK_LEFT: [KEY_A, KEY_LEFT],
		A.WALK_RIGHT: [KEY_D, KEY_RIGHT], A.RUN: [KEY_SHIFT, -1], A.USE: [KEY_E, -1], A.BUILD_LIST: [KEY_B, -1],
		A.PAUSE: [KEY_ESCAPE, -1]}
	for a: Controls.Action in keys:
		assert_int(_key_code(c, a, 0)).override_failure_message("%s key 0" % a).is_equal(keys[a][0])
		assert_int(_key_code(c, a, 1)).override_failure_message("%s key 1" % a).is_equal(keys[a][1])
	assert_int((c.slot(A.RUN, D.KEYBOARD, 0) as InputEventKey).location).is_equal(KEY_LOCATION_UNSPECIFIED)
	var axes := {A.WALK_UP: [JOY_AXIS_LEFT_Y, -1.0], A.WALK_DOWN: [JOY_AXIS_LEFT_Y, 1.0],
		A.WALK_LEFT: [JOY_AXIS_LEFT_X, -1.0], A.WALK_RIGHT: [JOY_AXIS_LEFT_X, 1.0]}
	for a: Controls.Action in axes:
		var m := c.slot(a, D.CONTROLLER, 0) as InputEventJoypadMotion
		assert_int(m.axis).is_equal(axes[a][0])
		assert_float(m.axis_value).is_equal(axes[a][1])
	var buttons := {A.RUN: JOY_BUTTON_LEFT_SHOULDER, A.USE: JOY_BUTTON_A, A.BUILD_LIST: JOY_BUTTON_Y,
		A.PAUSE: JOY_BUTTON_START}
	for a: Controls.Action in buttons:
		assert_int((c.slot(a, D.CONTROLLER, 0) as InputEventJoypadButton).button_index).is_equal(buttons[a])

func test_slot_counts() -> void:
	assert_int(Controls.slot_count(D.KEYBOARD)).is_equal(2)
	assert_int(Controls.slot_count(D.CONTROLLER)).is_equal(1)

func test_names_are_the_agreed_words() -> void:
	assert_array(Controls.NAMES.values()).is_equal(["Walk up", "Walk down", "Walk left", "Walk right",
		"Run (hold)", "Use / take", "Build list", "Pause"])

func test_set_empty_input_takes_the_slot() -> void:
	var c := Controls.new()
	assert_int(c.set_slot(A.USE, D.KEYBOARD, 1, _key(KEY_F))).is_equal(Controls.NO_ACTION)
	assert_int(_key_code(c, A.USE, 1)).is_equal(KEY_F)
	assert_int(_key_code(c, A.USE, 0)).is_equal(KEY_E)

func test_set_stores_a_normalised_copy() -> void:
	var c := Controls.new()
	var e := _key(KEY_F)
	e.pressed = true
	c.set_slot(A.USE, D.KEYBOARD, 0, e)
	assert_bool(c.slot(A.USE, D.KEYBOARD, 0) == e).is_false()
	assert_bool((c.slot(A.USE, D.KEYBOARD, 0) as InputEventKey).pressed).is_false()
	c.set_slot(A.WALK_UP, D.CONTROLLER, 0, _motion(JOY_AXIS_RIGHT_Y, -0.6))
	assert_float((c.slot(A.WALK_UP, D.CONTROLLER, 0) as InputEventJoypadMotion).axis_value).is_equal(-1.0)

func test_clash_empties_the_other_action() -> void:
	var c := Controls.new()
	assert_int(c.set_slot(A.BUILD_LIST, D.KEYBOARD, 0, _key(KEY_E))).is_equal(A.USE)
	assert_bool(c.has_no_key(A.USE, D.KEYBOARD)).is_true()
	assert_int(_key_code(c, A.BUILD_LIST, 0)).is_equal(KEY_E)

func test_clash_on_the_same_action_moves_across() -> void:
	var c := Controls.new()
	assert_int(c.set_slot(A.WALK_UP, D.KEYBOARD, 0, _key(KEY_UP))).is_equal(Controls.NO_ACTION)
	assert_int(_key_code(c, A.WALK_UP, 0)).is_equal(KEY_UP)
	assert_int(_key_code(c, A.WALK_UP, 1)).is_equal(-1)

func test_same_key_again_changes_nothing() -> void:
	var c := Controls.new()
	monitor_signals(c, false)
	assert_int(c.set_slot(A.WALK_UP, D.KEYBOARD, 0, _key(KEY_W))).is_equal(Controls.NO_ACTION)
	await assert_signal(c).wait_until(50).is_not_emitted("changed")

func test_clash_is_per_device() -> void:
	var c := Controls.new()
	assert_int(c.set_slot(A.BUILD_LIST, D.CONTROLLER, 0, _button(JOY_BUTTON_A))).is_equal(A.USE)
	assert_object(c.slot(A.USE, D.CONTROLLER, 0)).is_null()
	assert_int(_key_code(c, A.USE, 0)).is_equal(KEY_E)
	assert_int(_key_code(c, A.BUILD_LIST, 0)).is_equal(KEY_B)

func test_same_input_rules() -> void:
	assert_bool(Controls.same_input(_key(KEY_SHIFT), _key(KEY_SHIFT, KEY_LOCATION_RIGHT))).is_true()
	assert_bool(Controls.same_input(_key(KEY_SHIFT, KEY_LOCATION_LEFT), _key(KEY_SHIFT, KEY_LOCATION_RIGHT))).is_false()
	assert_bool(Controls.same_input(_motion(JOY_AXIS_LEFT_Y, -1.0), _motion(JOY_AXIS_LEFT_Y, 1.0))).is_false()
	assert_bool(Controls.same_input(_motion(JOY_AXIS_LEFT_Y, -0.5), _motion(JOY_AXIS_LEFT_Y, -1.0))).is_true()
	assert_bool(Controls.same_input(_button(JOY_BUTTON_A), _button(JOY_BUTTON_A))).is_true()
	assert_bool(Controls.same_input(_button(JOY_BUTTON_A), _motion(JOY_AXIS_LEFT_X, 1.0))).is_false()
	assert_bool(Controls.same_input(null, _button(JOY_BUTTON_A))).is_false()

func test_clear_empties_and_clear_again_is_silent() -> void:
	var c := Controls.new()
	monitor_signals(c, false)
	c.clear_slot(A.USE, D.KEYBOARD, 0)
	assert_object(c.slot(A.USE, D.KEYBOARD, 0)).is_null()
	await assert_signal(c).is_emitted("changed")
	var c2 := Controls.new()
	monitor_signals(c2, false)
	c2.clear_slot(A.USE, D.KEYBOARD, 1)
	await assert_signal(c2).wait_until(50).is_not_emitted("changed")

func test_actions_without_key_in_order() -> void:
	var c := Controls.new()
	c.clear_slot(A.PAUSE, D.KEYBOARD, 0)
	c.clear_slot(A.WALK_UP, D.KEYBOARD, 0)
	c.clear_slot(A.WALK_UP, D.KEYBOARD, 1)
	assert_array(c.actions_without_key(D.KEYBOARD)).is_equal([A.WALK_UP, A.PAUSE])
	assert_array(c.actions_without_key(D.CONTROLLER)).is_empty()

func test_first_input_falls_back_to_the_other_slot() -> void:
	var c := Controls.new()
	c.clear_slot(A.WALK_LEFT, D.KEYBOARD, 0)
	assert_int((c.first_input(A.WALK_LEFT, D.KEYBOARD) as InputEventKey).physical_keycode).is_equal(KEY_LEFT)
	assert_object(Controls.new().first_input(A.USE, D.KEYBOARD)).is_not_null()

func test_reset_restores_only_that_device() -> void:
	var c := Controls.new()
	c.set_slot(A.USE, D.KEYBOARD, 0, _key(KEY_F))
	c.set_slot(A.USE, D.CONTROLLER, 0, _button(JOY_BUTTON_X))
	monitor_signals(c, false)
	c.reset(D.KEYBOARD)
	await assert_signal(c).is_emitted("changed")
	assert_int(_key_code(c, A.USE, 0)).is_equal(KEY_E)
	assert_int((c.slot(A.USE, D.CONTROLLER, 0) as InputEventJoypadButton).button_index).is_equal(JOY_BUTTON_X)

# --- the file

func test_new_writes_nothing() -> void:
	Controls.new(PATH)
	assert_bool(FileAccess.file_exists(PATH)).is_false()

func test_round_trip_through_the_file() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var c := Controls.new(PATH)
	c.set_slot(A.USE, D.KEYBOARD, 0, _key(KEY_F))
	c.clear_slot(A.WALK_UP, D.KEYBOARD, 1)
	c.set_slot(A.RUN, D.KEYBOARD, 1, _key(KEY_SHIFT, KEY_LOCATION_RIGHT))
	c.set_slot(A.WALK_UP, D.CONTROLLER, 0, _motion(JOY_AXIS_RIGHT_Y, -1.0))
	c.set_slot(A.PAUSE, D.CONTROLLER, 0, _button(JOY_BUTTON_BACK))
	var back := Controls.load_from(PATH)
	assert_str(back.path).is_equal(PATH)
	assert_str(JSON.stringify(back.to_dict())).is_equal(JSON.stringify(c.to_dict()))
	assert_int(_key_code(back, A.USE, 0)).is_equal(KEY_F)

func test_each_mutation_saves() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var c := Controls.new(PATH)
	c.set_slot(A.USE, D.KEYBOARD, 0, _key(KEY_F))
	assert_int(_key_code(Controls.load_from(PATH), A.USE, 0)).is_equal(KEY_F)
	c.clear_slot(A.USE, D.KEYBOARD, 0)
	assert_int(_key_code(Controls.load_from(PATH), A.USE, 0)).is_equal(-1)
	c.reset(D.KEYBOARD)
	assert_int(_key_code(Controls.load_from(PATH), A.USE, 0)).is_equal(KEY_E)

func test_to_dict_shape() -> void:
	var d := Controls.new().to_dict()
	assert_int(d["version"]).is_equal(1)
	assert_array(d["keyboard"]["move_up"]).is_equal([{"key": KEY_W, "location": 0}, {"key": KEY_UP, "location": 0}])
	assert_that(d["keyboard"]["run"][1]).is_null()
	assert_dict(d["controller"]["move_up"]).is_equal({"axis": 1, "sign": -1})
	assert_dict(d["controller"]["run"]).is_equal({"button": 9})

@warning_ignore("unused_parameter")
func test_unreadable_files_give_defaults(case: String, text: String, test_parameters := [
	["missing", ""],
	["not json", "not json"],
	["array", "[]"],
	["version 2", "V2"],
	["missing action", "NO_USE"],
	["keyboard array of 1", "KB1"],
	["key 0", "KEY0"],
	["key too large", "KEYBIG"],
	["location 3", "LOC3"],
	["button 200", "BTN200"],
	["sign 0", "SIGN0"],
	["not whole", "FRACTION"],
	["duplicate", "DUP"],
]) -> void:
	var good := JSON.stringify(Controls.new().to_dict())
	var content := text
	match text:
		"V2": content = good.replace("\"version\":1", "\"version\":2")
		"NO_USE": content = good.replace("\"use\":", "\"usex\":")
		"KB1": content = good.replace("[{\"key\":69,\"location\":0},null]", "[{\"key\":69,\"location\":0}]")
		"KEY0": content = good.replace("{\"key\":69,", "{\"key\":0,")
		"KEYBIG": content = good.replace("{\"key\":69,", "{\"key\":1e30,")
		"LOC3": content = good.replace("{\"key\":69,\"location\":0}", "{\"key\":69,\"location\":3}")
		"BTN200": content = good.replace("{\"button\":0}", "{\"button\":200}")
		"SIGN0": content = good.replace("{\"axis\":1,\"sign\":-1}", "{\"axis\":1,\"sign\":0}")
		"FRACTION": content = good.replace("{\"key\":69,", "{\"key\":69.5,")
		"DUP": content = good.replace("{\"key\":66,", "{\"key\":69,")
	assert_str(content).override_failure_message("case %s did not change the file" % case).is_not_equal(good)
	if case != "missing":
		_write(content)
	var c := Controls.load_from(PATH)
	assert_bool(_is_default(c)).override_failure_message(case).is_true()
	assert_str(c.path).is_equal(PATH)
	if case != "missing":
		assert_str(FileAccess.get_file_as_string(PATH)).is_equal(content)
	else:
		assert_bool(FileAccess.file_exists(PATH)).is_false()

func test_a_good_file_loads_changes() -> void:
	var good := JSON.stringify(Controls.new().to_dict(), "\t")
	_write(good.replace("\"key\": 69", "\"key\": 70"))
	assert_int(_key_code(Controls.load_from(PATH), A.USE, 0)).is_equal(KEY_F)

func test_empty_path_loads_defaults() -> void:
	var c := Controls.load_from("")
	assert_bool(_is_default(c)).is_true()
	assert_str(c.path).is_equal("")

# --- the InputMap

func _pressed_key(code: Key) -> InputEventKey:
	var e := _key(code)
	e.pressed = true
	return e

func test_apply_rebinds_the_input_map() -> void:
	var c := Controls.new()
	c.set_slot(A.USE, D.KEYBOARD, 0, _key(KEY_F))
	assert_bool(InputMap.event_is_action(_pressed_key(KEY_F), &"use")).is_true()
	assert_bool(InputMap.event_is_action(_pressed_key(KEY_E), &"use")).is_false()
	assert_float(InputMap.action_get_deadzone(&"use")).is_equal_approx(0.2, 0.0001)

func test_apply_uses_the_motion_sign() -> void:
	var c := Controls.new()
	c.set_slot(A.WALK_UP, D.CONTROLLER, 0, _motion(JOY_AXIS_RIGHT_Y, -1.0))
	var m := _motion(JOY_AXIS_RIGHT_Y, -1.0)
	m.device = 0
	Input.parse_input_event(m)
	Input.flush_buffered_events()
	assert_bool(Input.is_action_pressed(&"move_up")).is_true()
	Input.parse_input_event(_motion_at(JOY_AXIS_RIGHT_Y, 0.0))
	Input.flush_buffered_events()
	assert_bool(Input.is_action_pressed(&"move_up")).is_false()

func _motion_at(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var m := _motion(axis, value)
	m.device = 0
	return m

func test_apply_leaves_menus_alone() -> void:
	var menus := [&"menu_accept", &"menu_cancel", &"build_accept", &"build_back", &"menu_up"]
	var counts := {}
	for m: StringName in menus:
		counts[m] = InputMap.action_get_events(m).size()
	var c := Controls.new()
	c.reset(D.KEYBOARD)
	for a: Controls.Action in A.values():
		for i in 2:
			c.clear_slot(a, D.KEYBOARD, i)
	for m: StringName in menus:
		assert_int(InputMap.action_get_events(m).size()).is_equal(counts[m])
