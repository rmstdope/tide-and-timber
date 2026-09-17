extends GdUnitTestSuite
## On the beach, hints follow the device pressed last, in place, without disturbing anything else.

const SCENE := "res://src/beach/beach.tscn"
const F := Walk.Facing
const M := Builder.Mode

var runner: GdUnitSceneRunner
var beach: Beach
var player: Player
var builder: Builder
var inventory: Inventory

func before_test() -> void:
	InputDevice.reset()
	runner = scene_runner(SCENE)
	beach = runner.scene() as Beach
	player = beach.get_node("%Player") as Player
	builder = beach.get_node("%Builder") as Builder
	inventory = beach.inventory

func after_test() -> void:
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _n(unique: String) -> Node:
	return beach.get_node("%" + unique)

func _hint() -> KeyHint:
	return _n("KeyHint") as KeyHint

func _stand(cell: Vector2i, facing: F) -> void:
	player.global_position = BeachLayout.cell_centre(cell)
	player.facing = facing
	(beach.get_node("%Camera") as LooseCamera).snap_to_target()
	await await_millis(50)

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()
	await await_millis(50)

func _pad(button: JoyButton, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 7
	e.button_index = button
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await runner.await_input_processed()

func _driftwood(n: int) -> void:
	inventory.add(Item.Kind.DRIFTWOOD, n)

func test_build_list_hint_follows_the_pad_in_place() -> void:
	_driftwood(9)
	await _press(KEY_B)
	assert_str(_hint().text()).is_equal("[E] Build   [Esc] Close")
	assert_float(_hint().position.x).is_equal(float(roundi((320 - 132) / 2.0)))
	await _pad(JOY_BUTTON_X, true)
	await _pad(JOY_BUTTON_X, false)
	assert_str(_hint().text()).is_equal("(A) Build   (B) Close")
	assert_float(_hint().position.x).is_equal(float(roundi((320 - 124) / 2.0)))
	assert_int(builder.mode).is_equal(M.LIST)
	assert_int(builder.menu.highlighted).is_equal(0)
	assert_bool(_n("BuildList").visible).is_true()

func test_placing_hint_switches_back_to_keys_on_a_click() -> void:
	_driftwood(9)
	await _stand(Vector2i(92, 11), F.DOWN)
	await _press(KEY_B)
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.PLACING)
	InputDevice.reset(PackedStringArray(["Xbox Series Controller"]))
	assert_str(_hint().text()).is_equal("(A) Place   (B) Back")
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	await runner.await_input_processed()
	assert_str(_hint().text()).is_equal("[E] Place   [Esc] Back")
	assert_int(builder.mode).is_equal(M.PLACING)

func test_hidden_hint_stays_hidden_on_a_switch() -> void:
	assert_bool(_hint().visible).is_false()
	await _pad(JOY_BUTTON_X, true)
	await _pad(JOY_BUTTON_X, false)
	assert_bool(_hint().visible).is_false()

func _stand_by_driftwood() -> void:
	player.global_position = BeachLayout.cell_base(BeachLayout.DRIFTWOOD[2]) + Vector2(-16, -2)
	player.facing = F.RIGHT
	(beach.get_node("%Camera") as LooseCamera).snap_to_target()
	await await_millis(50)

func test_verb_prompt_shows_the_pad_bottom_button() -> void:
	var prompt := _n("Prompt") as UsePrompt
	await _stand_by_driftwood()
	assert_bool(prompt.visible).is_true()
	assert_str(prompt.text()).is_equal("[E] Take")
	var at := prompt.global_position
	InputDevice.reset(PackedStringArray(["PS5 Controller"]))
	assert_str(prompt.text()).is_equal("(✕) Take")
	assert_vector(prompt.global_position).is_equal(at)
	assert_float(prompt.verb_label.position.x).is_equal(float(-prompt.width() / 2 + 3 + 9 + 2))

func test_verb_prompt_key_cap_matches_the_old_layout() -> void:
	var prompt := _n("Prompt") as UsePrompt
	await _stand_by_driftwood()
	assert_int(prompt.width()).is_equal(3 + 9 + 2 + ceili(prompt.verb_label.get_minimum_size().x) + 3)

func test_prompt_shows_the_players_key() -> void:
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	InputDevice.controls.set_slot(Controls.Action.USE, Controls.Device.KEYBOARD, 0, f)
	var prompt := _n("Prompt") as UsePrompt
	await _stand_by_driftwood()
	assert_bool(prompt.visible).is_true()
	assert_str(prompt.text()).is_equal("[F] Take")

func test_prompt_without_a_use_key_shows_just_the_verb() -> void:
	InputDevice.controls.clear_slot(Controls.Action.USE, Controls.Device.KEYBOARD, 0)
	var prompt := _n("Prompt") as UsePrompt
	await _stand_by_driftwood()
	assert_object(prompt.picture()).is_null()
	assert_str(prompt.text()).is_equal("Take")
	assert_int(prompt.width()).is_equal(3 + ceili(prompt.verb_label.get_minimum_size().x) + 3)

