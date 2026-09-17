extends GdUnitTestSuite
## The Debug panel's Items page on the beach, in a debug build.

const K := Item.Kind

var runner: GdUnitSceneRunner
var waking: Waking
var pause: Pause
var panel: DebugPanel
var beach: Beach
var inv: Inventory

func before_test() -> void:
	Pause.debug_tools = true
	InputDevice.reset()
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	pause = waking.get_node("%Pause")
	panel = pause.get_node("%DebugPanel") as DebugPanel
	beach = waking.get_node("%Beach") as Beach
	inv = beach.inventory
	(waking.get_node("%Autosave") as Autosave).save_game = func() -> Error: return OK

func after_test() -> void:
	get_tree().paused = false
	Pause.debug_tools = OS.is_debug_build()
	InputDevice.reset()
	InputDevice.use_controls(Controls.new())

func _control() -> void:
	waking.tick(5.0)

func _tap(key: Key) -> void:
	await runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _pad(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = button
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await runner.await_input_processed()

func _open_items() -> void:
	_control()
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	await _tap(KEY_E)

func _bar() -> ItemBar:
	return beach.get_node("%ItemBar") as ItemBar

func test_items_page_lists_every_item_at_its_count() -> void:
	inv.add(K.COCONUT, 2)
	await _open_items()
	assert_int(panel.rules.page).is_equal(DebugMenu.Page.ITEMS)
	var rows := panel.rules.rows_of(DebugMenu.Page.ITEMS)
	assert_array(rows.map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Driftwood", "Shellfish", "Coconut", "Empty shell", "Fresh water", "Empty his bag"])
	assert_str(rows[2].value_text()).is_equal("2")
	assert_int(panel.rules.highlighted).is_equal(0)

func test_right_adds_driftwood_and_the_bar_shows_it_while_paused() -> void:
	await _open_items()
	for i in 3:
		await _tap(KEY_RIGHT)
	assert_int(inv.count(K.DRIFTWOOD)).is_equal(3)
	assert_int(_bar().slots[0].kind).is_equal(K.DRIFTWOOD)
	assert_int(_bar().slots[0].count).is_equal(3)
	assert_bool(get_tree().paused).is_true()
	assert_bool(panel.visible).is_true()
	assert_object(waking.player.get_node_or_null("RisingLine")).is_null()

func test_left_takes_away_and_stops_at_zero() -> void:
	inv.add(K.DRIFTWOOD, 1)
	await _open_items()
	await _tap(KEY_LEFT)
	await _tap(KEY_LEFT)
	assert_int(inv.count(K.DRIFTWOOD)).is_equal(0)
	assert_int(_bar().slots[0].kind).is_equal(Inventory.EMPTY)

func test_empty_his_bag_clears_the_bar_and_stays_open() -> void:
	inv.add(K.DRIFTWOOD, 4)
	inv.add(K.SHELLFISH, 2)
	await _open_items()
	for i in 5:
		await _tap(KEY_DOWN)
	assert_int(panel.rules.highlighted).is_equal(5)
	await _tap(KEY_ENTER)
	for kind: K in K.values():
		assert_int(inv.count(kind)).is_equal(0)
	for slot in _bar().slots:
		assert_int(slot.kind).is_equal(Inventory.EMPTY)
	assert_bool(panel.visible).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_int(panel.shaking_row).is_equal(-1)

func test_pad_dpad_changes_the_count() -> void:
	await _open_items()
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	assert_int(inv.count(K.DRIFTWOOD)).is_equal(1)

func test_bag_set_from_debug_is_what_the_save_writes() -> void:
	await _open_items()
	await _tap(KEY_RIGHT)
	await _tap(KEY_RIGHT)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ESCAPE)
	assert_dict(inv.to_slots()[0]).is_equal({"kind": K.DRIFTWOOD, "count": 2})
