extends GdUnitTestSuite
## The Debug panel's Items page rows over one inventory.

const K := Item.Kind

var menu: DebugMenu
var inv: Inventory
var rows: Array[DebugRow]

func before_test() -> void:
	menu = DebugMenu.new()
	inv = Inventory.new()
	DebugItems.add_rows(menu, inv)
	rows = menu.rows_of(DebugMenu.Page.ITEMS)

func test_one_row_per_item_then_empty_his_bag() -> void:
	assert_array(rows.map(func(r: DebugRow) -> String: return r.label)) \
		.is_equal(["Driftwood", "Shellfish", "Coconut", "Empty shell", "Fresh water", "Empty his bag"])
	assert_int(rows.size()).is_equal(Item.Kind.size() + 1)
	for p: DebugMenu.Page in DebugMenu.Page.values():
		if p != DebugMenu.Page.ITEMS:
			assert_array(menu.rows_of(p)).is_empty()

func test_item_value_is_the_count_carried() -> void:
	assert_str(rows[2].value_text()).is_equal("0")
	inv.add(K.COCONUT, 7)
	assert_str(rows[2].value_text()).is_equal("7")

func test_right_and_left_step_the_count() -> void:
	rows[0].step.call(1)
	rows[0].step.call(1)
	assert_int(inv.count(K.DRIFTWOOD)).is_equal(2)
	rows[0].step.call(-1)
	assert_int(inv.count(K.DRIFTWOOD)).is_equal(1)

func test_count_stops_at_zero() -> void:
	rows[1].step.call(-1)
	assert_int(inv.count(K.SHELLFISH)).is_equal(0)
	assert_int(inv.slot_kind(0)).is_equal(Inventory.EMPTY)

func test_count_stops_at_ninety_nine() -> void:
	inv.set_count(K.FRESH_WATER, 99)
	rows[4].step.call(1)
	assert_int(inv.count(K.FRESH_WATER)).is_equal(99)
	inv.add(K.SHELLFISH, 120)
	rows[1].step.call(-1)
	assert_int(inv.count(K.SHELLFISH)).is_equal(99)

func test_item_rows_have_no_select() -> void:
	for i in 5:
		assert_bool(rows[i].select.is_valid()).is_false()

func test_empty_his_bag_clears_everything() -> void:
	inv.add(K.DRIFTWOOD, 5)
	inv.add(K.COCONUT, 2)
	assert_int(rows[5].select.call()).is_equal(DebugRow.Result.DONE)
	for kind: K in K.values():
		assert_int(inv.count(kind)).is_equal(0)
	assert_str(rows[5].value_text()).is_equal("")
	assert_bool(rows[5].step.is_valid()).is_false()

func test_empty_his_bag_on_an_empty_bag_does_nothing() -> void:
	assert_int(rows[5].select.call()).is_equal(DebugRow.Result.DONE)
	for kind: K in K.values():
		assert_int(inv.count(kind)).is_equal(0)
