extends GdUnitTestSuite

const K := Item.Kind

var inv: Inventory
var bar: ItemBar

func before_test() -> void:
	inv = Inventory.new()
	bar = auto_free(ItemBar.new())
	add_child(bar)
	bar.bind(inv)

func test_eight_slots_centred_at_bottom() -> void:
	assert_int(bar.slots.size()).is_equal(8)
	assert_vector(bar.position).is_equal(Vector2(90, 157))
	assert_vector(bar.slots[7].position).is_equal(Vector2(122, 3))

func test_slots_follow_inventory() -> void:
	inv.add(K.DRIFTWOOD, 3)
	inv.add(K.SHELLFISH)
	assert_int(bar.slots[0].kind).is_equal(K.DRIFTWOOD)
	assert_str(bar.slots[0].count_text()).is_equal("3")
	assert_str(bar.slots[1].count_text()).is_equal("1")
	assert_str(bar.slots[2].count_text()).is_equal("")
	inv.remove(K.DRIFTWOOD, 3)
	assert_str(bar.slots[0].count_text()).is_equal("")
	assert_int(bar.slots[1].kind).is_equal(K.SHELLFISH)

func test_count_past_99() -> void:
	inv.add(K.DRIFTWOOD, 120)
	assert_str(bar.slots[0].count_text()).is_equal("120")

func test_name_on_filled_slot_only() -> void:
	inv.add(K.SHELLFISH)
	bar.slots[0].mouse_entered.emit()
	assert_bool(bar.name_plank.visible).is_true()
	assert_str(bar.name_label.text).is_equal("Shellfish")
	bar.slots[0].mouse_exited.emit()
	assert_bool(bar.name_plank.visible).is_false()
	bar.slots[3].mouse_entered.emit()
	assert_bool(bar.name_plank.visible).is_false()

func test_name_hides_when_hovered_slot_empties() -> void:
	inv.add(K.SHELLFISH)
	bar.slots[0].mouse_entered.emit()
	inv.remove(K.SHELLFISH)
	assert_bool(bar.name_plank.visible).is_false()

func test_slots_stop_the_mouse() -> void:
	for slot in bar.slots:
		assert_int(slot.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)

func test_name_plank_stays_on_screen_at_largest() -> void:
	var root := get_tree().root
	var saved_size := root.size
	var saved_mode := root.content_scale_mode
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.size = Vector2i(640, 360)
	Display.use_prefs(DisplayPrefs.new())
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	inv.add(K.SHELLFISH)
	bar.slots[0].mouse_entered.emit()
	var x := bar.position.x + bar.name_plank.position.x
	root.size = saved_size
	root.content_scale_mode = saved_mode
	Display.use_prefs(DisplayPrefs.new())
	assert_float(x).is_greater_equal(82.0)
