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
	assert_vector(bar.position).is_equal(Vector2(roundi((Screen.WIDTH - ItemBar.PLANK_SIZE.x) / 2), ItemBar.TOP))
	assert_vector(bar.slots[0].position).is_equal(Vector2(7, 6))
	assert_vector(bar.slots[7].position).is_equal(Vector2(175, 6))

func test_slots_follow_inventory() -> void:
	inv.add(K.DRIFTWOOD, 3)
	inv.add(K.SHELLFISH)
	assert_int(bar.slots[0].kind).is_equal(K.DRIFTWOOD)
	assert_str(bar.slots[0].count_text()).is_equal("3")
	assert_str(bar.slots[1].count_text()).is_equal("")
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
	root.size = Vector2i(1280, 720)
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
	assert_vector(bar.name_plank.position).is_equal_approx(Vector2(-50, -27), Vector2(0.01, 0.01))
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

# Retired in tr-1o0.1: a name plank wider than the picture, centred on it. At 640x360 no UI size, Text size
# and window grows the longest name that far (it is at most 368 of 640 on screen), so the plank is only
# ever clamped inside the picture. This is what fails if a later change grows it past the picture.
func test_at_the_largest_sizes_every_name_plank_fits_the_picture(
		window: Vector2i, test_parameters := [[Vector2i(1280, 720)], [Vector2i(640, 360)]]) -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = window
	Display.use_prefs(DisplayPrefs.new())
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 2)
	var s := UiScale.current(Display.prefs, get_tree().root)
	for kind: int in K.values():
		inv.clear()
		inv.add(kind)
		bar.slots[0].mouse_entered.emit()
		assert_float(bar.name_plank.size.x * s).override_failure_message(
				"%s's plank, %s wide on screen, does not fit the picture" % [Item.name_of(kind), bar.name_plank.size.x * s]) \
			.is_less_equal(Screen.WIDTH - 4.0)

func test_no_slot_is_selected_after_refresh() -> void:
	inv.add(K.DRIFTWOOD, 3)
	for slot in bar.slots:
		assert_bool(slot.selected).is_false()
