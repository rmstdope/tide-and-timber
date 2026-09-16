extends GdUnitTestSuite

const SCENE := "res://src/beach/beach.tscn"
const T := BuildMenu.Thing
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

func _n(unique: String) -> Node:
	return beach.get_node("%" + unique)

func _list() -> BuildList:
	return _n("BuildList") as BuildList

func _stand(cell: Vector2i, facing: F) -> void:
	player.global_position = BeachLayout.cell_centre(cell)
	player.facing = facing
	(beach.get_node("%Camera") as LooseCamera).snap_to_target()
	await await_millis(50)

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()
	await await_millis(50)

func _clock() -> DayNight:
	var dn := load("res://src/day_night/day_night.tscn").instantiate() as DayNight
	beach.add_child(dn)
	beach.set_day_night(dn)
	dn.start()
	return dn

func _driftwood(n: int) -> void:
	inventory.add(Item.Kind.DRIFTWOOD, n)

func _left_press() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event

## B opens the Build list on the beach; it stops the world; Esc or B closes it.

func test_b_opens_list_enough_driftwood() -> void:
	_driftwood(9)
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(M.LIST)
	assert_bool(_list().visible).is_true()
	assert_bool(_n("BuildBlocker").visible).is_true()
	assert_bool(_n("KeyHint").visible).is_true()
	assert_str((_n("KeyHint") as KeyHint).text()).is_equal("[E] Build   [Esc] Close")
	assert_str(_list().title_label.text).is_equal("Build")
	assert_str(_list().name_labels[0].text).is_equal("Lean-to")
	assert_str(_list().cost_labels[0].text).is_equal("9/8 driftwood")
	assert_str(_list().cost_labels[1].text).is_equal("Needs a lean-to")
	assert_int(builder.menu.highlighted).is_equal(0)
	assert_that(_list().cost_labels[1].get_theme_color(&"font_color")).is_equal(BuildList.GREYED)
	assert_that(_list().cost_labels[0].get_theme_color(&"font_color")).is_equal(BuildList.TEXT)

func test_list_opens_empty_inventory_nothing_highlighted() -> void:
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(M.LIST)
	assert_str(_list().cost_labels[0].text).is_equal("0/8 driftwood")
	assert_int(builder.menu.highlighted).is_equal(-1)

func test_up_down_and_ws_move_one_highlight() -> void:
	_driftwood(9)
	await _press(KEY_B)
	await _press(KEY_DOWN)
	assert_int(builder.menu.highlighted).is_equal(1)
	await _press(KEY_S)
	assert_int(builder.menu.highlighted).is_equal(0)
	await _press(KEY_UP)
	assert_int(builder.menu.highlighted).is_equal(1)
	await _press(KEY_W)
	assert_int(builder.menu.highlighted).is_equal(0)

func test_mouse_over_row_moves_highlight() -> void:
	_driftwood(9)
	await _press(KEY_B)
	_list().rows[1].mouse_entered.emit()
	assert_int(builder.menu.highlighted).is_equal(1)

func test_esc_and_b_close_spending_nothing() -> void:
	_driftwood(9)
	await _press(KEY_B)
	await _press(KEY_ESCAPE)
	assert_int(builder.mode).is_equal(M.CLOSED)
	assert_bool(_list().visible).is_false()
	assert_bool(_n("BuildBlocker").visible).is_false()
	assert_bool(_n("KeyHint").visible).is_false()
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(9)
	await _press(KEY_B)
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(M.CLOSED)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(9)

func test_e_on_greyed_line_does_nothing() -> void:
	_driftwood(3)
	await _press(KEY_B)
	await _press(KEY_DOWN)
	assert_int(builder.menu.highlighted).is_equal(0)
	await _press(KEY_E)
	assert_int(builder.mode).is_equal(M.LIST)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(3)
	await _press(KEY_ENTER)
	assert_int(builder.mode).is_equal(M.LIST)

func test_click_on_greyed_row_does_nothing() -> void:
	_driftwood(3)
	await _press(KEY_B)
	_list().rows[0].gui_input.emit(_left_press())
	assert_int(builder.mode).is_equal(M.LIST)

func test_list_stops_world_and_clock() -> void:
	var dn := _clock()
	_driftwood(9)
	await _press(KEY_B)
	for node: Node in [_n("World"), _n("Decor"), _n("Interactor"), dn]:
		assert_int(node.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	var m := dn.clock.total_minutes
	var p := player.global_position
	runner.simulate_action_press("move_right")
	await await_millis(300)
	assert_float(dn.clock.total_minutes).is_equal(m)
	assert_vector(player.global_position).is_equal(p)
	runner.simulate_action_release("move_right")
	await _press(KEY_ESCAPE)
	assert_int(_n("World").process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_int(dn.process_mode).is_equal(Node.PROCESS_MODE_PAUSABLE)

func test_prompt_hidden_while_list_open() -> void:
	player.global_position = BeachLayout.cell_base(BeachLayout.DRIFTWOOD[2]) + Vector2(-16, -2)
	player.facing = F.RIGHT
	await await_millis(50)
	assert_bool(_n("Prompt").visible).is_true()
	await _press(KEY_B)
	assert_bool(_n("Prompt").visible).is_false()
	await _press(KEY_E)
	assert_int(inventory.count(Item.Kind.DRIFTWOOD)).is_equal(0)
	await _press(KEY_ESCAPE)
	await await_millis(50)
	assert_bool(_n("Prompt").visible).is_true()

func test_b_does_nothing_without_control() -> void:
	player.control_enabled = false
	await _press(KEY_B)
	assert_int(builder.mode).is_equal(M.CLOSED)
	assert_bool(_list().visible).is_false()
