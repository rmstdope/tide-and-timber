extends GdUnitTestSuite

const K := Item.Kind

var inv: Inventory
var bar: ItemBar
var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	inv = Inventory.new()
	bar = auto_free(ItemBar.new())
	add_child(bar)
	bar.bind(inv)

func after_test() -> void:
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	Display.use_prefs(DisplayPrefs.new())

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
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.size = Vector2i(2560, 1440)
	Display.use_prefs(DisplayPrefs.new())
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	inv.add(K.SHELLFISH)
	bar.slots[0].mouse_entered.emit()
	assert_float(bar.position.x + bar.name_plank.position.x).is_greater_equal(82.0)

func _big_root() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Display.use_prefs(DisplayPrefs.new())

func test_name_plank_grows_with_text_size() -> void:
	_big_root()
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	inv.add(K.SHELLFISH)
	bar.slots[0].mouse_entered.emit()
	assert_vector(bar.name_plank.size).is_equal_approx(Vector2(136, 21), Vector2(0.01, 0.01))
	assert_vector(bar.name_plank.position).is_equal_approx(Vector2(-57, -27), Vector2(0.01, 0.01))
	assert_vector(bar.name_label.scale).is_equal_approx(Vector2(2, 2), Vector2(0.01, 0.01))
	assert_vector(bar.name_label.position).is_equal_approx(Vector2(4, 3), Vector2(0.01, 0.01))

func test_name_plank_refits_when_text_size_changes() -> void:
	_big_root()
	inv.add(K.SHELLFISH)
	bar.slots[0].mouse_entered.emit()
	assert_vector(bar.name_plank.size).is_equal_approx(Vector2(72, 13), Vector2(0.01, 0.01))
	assert_float(bar.name_plank.position.y).is_equal_approx(-19.0, 0.01)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	assert_vector(bar.name_plank.size).is_equal_approx(Vector2(136, 21), Vector2(0.01, 0.01))
	Display.use_prefs(DisplayPrefs.new())
	assert_vector(bar.name_plank.size).is_equal_approx(Vector2(72, 13), Vector2(0.01, 0.01))
	assert_vector(bar.name_label.scale).is_equal_approx(Vector2.ONE, Vector2(0.01, 0.01))

func test_too_wide_name_plank_is_centred_on_the_screen() -> void:
	_big_root()
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	inv.add(K.FRESH_WATER)
	bar.slots[0].mouse_entered.emit()
	assert_float(bar.name_plank.size.x).is_equal_approx(184.0, 0.01)
	assert_float(bar.position.x + bar.name_plank.position.x + bar.name_plank.size.x / 2.0) \
		.is_equal_approx(160.0, 0.01)
	assert_float(bar.name_plank.position.x).is_equal_approx(-22.0, 0.01)
